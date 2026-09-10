/// Wiring. Providers are hand-written (no codegen) — the graph is small and
/// entirely async-read.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/api/ra_api.dart';
import '../core/api/ra_client.dart';
import '../core/auth/auth_repository.dart';
import '../core/db/database.dart';
import '../core/prefs/prefs_repository.dart';
import '../core/result.dart';
import '../data/cache.dart';
import '../data/insights_repository.dart';
import '../domain/insights/activity.dart';
import '../domain/insights/almost_there.dart';
import '../domain/insights/challenge_match.dart';
import '../domain/insights/challenge_plan.dart';
import '../domain/insights/challenges.dart';
import '../domain/insights/heatmap.dart';
import '../domain/insights/progression.dart';
import '../domain/insights/rarity.dart';
import '../domain/insights/recommendation.dart';
import '../domain/insights/search.dart';
import '../domain/insights/streaks.dart';
import '../domain/models/models.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final cacheStoreProvider =
    Provider<CacheStore>((ref) => CacheStore(ref.watch(databaseProvider)));

final raClientProvider = Provider<RaClient>((ref) => RaClient());

final raApiProvider = Provider<RaApi>((ref) => RaApi(ref.watch(raClientProvider)));

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(
      storage: ref.watch(secureStorageProvider),
      api: ref.watch(raApiProvider),
    ));

final insightsRepositoryProvider = Provider<InsightsRepository>(
  (ref) => InsightsRepository(
    api: ref.watch(raApiProvider),
    cache: ref.watch(cacheStoreProvider),
  ),
);

final prefsRepositoryProvider = Provider<PrefsRepository>(
    (ref) => PrefsRepository(ref.watch(secureStorageProvider)));

/// `null` = follow the device language. Adding a language means adding its
/// `.arb` and its [Locale] to `AppLocalizations.supportedLocales`; nothing
/// here changes.
class LocaleNotifier extends AsyncNotifier<Locale?> {
  @override
  Future<Locale?> build() => ref.read(prefsRepositoryProvider).loadLocale();

  Future<void> set(Locale? locale) async {
    await ref.read(prefsRepositoryProvider).saveLocale(locale);
    state = AsyncData(locale);
  }
}

final localeProvider =
    AsyncNotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

/// `null` = signed out. The router keys off this.
class SessionNotifier extends AsyncNotifier<RaCredentials?> {
  @override
  Future<RaCredentials?> build() => ref.read(authRepositoryProvider).load();

  Future<void> signIn(RaCredentials creds) async {
    ref.read(raClientProvider).credentials = creds;
    // Remembered for the next sign-in, so only the key ever has to be retyped.
    await ref.read(prefsRepositoryProvider).saveLastUsername(creds.username);
    state = AsyncData(creds);
    ref.invalidate(dashboardProvider);
    ref.invalidate(heatmapProvider);
    ref.invalidate(progressionProvider);
  }

  /// Replaces the stored key while staying signed in. The cache is dropped so
  /// nothing fetched with the old key survives.
  Future<Result<void>> replaceApiKey(String apiKey) async {
    final user = state.valueOrNull?.username;
    if (user == null) {
      return const Err(AppError(AppErrorKind.unauthorized, 'not signed in'));
    }
    final res = await ref.read(authRepositoryProvider).signIn(user, apiKey);
    switch (res) {
      case Err(:final error):
        return Err(error);
      case Ok():
        await ref.read(databaseProvider).clearCache();
        state = AsyncData(RaCredentials(username: user, apiKey: apiKey.trim()));
        return const Ok(null);
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    await ref.read(databaseProvider).clearCache();
    state = const AsyncData(null);
  }
}

final sessionProvider =
    AsyncNotifierProvider<SessionNotifier, RaCredentials?>(SessionNotifier.new);

/// Everything the dashboard shows, computed from cached payloads.
class DashboardData {
  const DashboardData({
    required this.summary,
    required this.streaks,
    required this.almostThere,
    required this.progression,
    required this.pick,
    required this.fetchedAt,
    required this.stale,
  });

  final UserSummary? summary;
  final StreakStats streaks;
  final List<AlmostThereGame> almostThere;
  final ProgressionBreakdown progression;
  final PlayNowPick? pick;
  final DateTime? fetchedAt;
  final bool stale;
}

final refreshCounterProvider = StateProvider<int>((ref) => 0);

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  ref.watch(refreshCounterProvider);
  // Refreshing is driven by [refreshAll], which re-fetches then invalidates;
  // this provider always reads through the cache.
  final repo = ref.watch(insightsRepositoryProvider);

  final summary = (await repo.summary()).valueOrNull;
  final games = await repo.recentGames();
  final yearly = await repo.yearlyAchievements();
  final completion = await repo.completionProgress();

  // All four failed with nothing cached: that is a real error, not an empty
  // state. The rarest list loads on its own and is not part of this check.
  if (summary == null && !games.isOk && !yearly.isOk && !completion.isOk) {
    throw games.errorOrNull ?? yearly.errorOrNull ?? completion.errorOrNull!;
  }

  final almost = computeAlmostThere(games.valueOrNull?.value ?? const []);
  final fetchedAt = summary != null ? DateTime.now() : null;

  return DashboardData(
    summary: summary?.value,
    streaks: computeStreaks(yearly.valueOrNull?.value ?? const []),
    almostThere: almost,
    progression: computeProgression(completion.valueOrNull?.value ?? const []),
    pick: pickWhatToPlay(almost),
    fetchedAt: summary?.fetchedAt ?? fetchedAt,
    stale: summary?.stale ?? true,
  );
});

/// Every event plus how far the user is into each. Loads on its own so the
/// catalogue fetch never holds back the dashboard.
final challengeCatalogProvider = FutureProvider<List<Challenge>>((ref) async {
  ref.watch(refreshCounterProvider);
  final repo = ref.watch(insightsRepositoryProvider);

  final catalog = (await repo.eventCatalog()).unwrap().value;
  // Progress is derived from data the app already holds: no request per event.
  final allTime = (await repo.allTimeAchievements()).valueOrNull?.value ??
      const <EarnedAchievement>[];
  final completion = (await repo.completionProgress()).valueOrNull?.value ??
      const <CompletionEntry>[];

  return buildChallenges(catalog, allTime, completion: completion);
});

final challengeFilterProvider =
    StateProvider<ChallengeFilter>((ref) => ChallengeFilter.all);

final challengeSortProvider =
    StateProvider<ChallengeSort>((ref) => ChallengeSort.closest);

final challengeQueryProvider = StateProvider<String>((ref) => '');

/// The list the screen renders: searched, sorted, then filtered.
///
/// Synchronous on purpose. As a FutureProvider every keystroke would flip it to
/// loading, and the screen would rebuild its search field out of existence
/// mid-word.
final challengeListProvider = Provider<List<Challenge>>((ref) {
  final all = ref.watch(challengeCatalogProvider).valueOrNull;
  if (all == null) return const [];
  return filterChallenges(
    sortChallenges(
      searchChallenges(all, ref.watch(challengeQueryProvider)),
      ref.watch(challengeSortProvider),
    ),
    ref.watch(challengeFilterProvider),
  );
});

/// The ordered next moves for one event.
final challengePlanProviderFamily =
    FutureProvider.family<ChallengePlan, int>((ref, eventId) async {
  final game = await ref.watch(gameProgressProvider(eventId).future);
  return buildChallengePlan(game);
});

/// The handful the dashboard card shows: closest to done first.
final challengePlanProvider = FutureProvider<List<Challenge>>((ref) async {
  final all = await ref.watch(challengeCatalogProvider.future);
  return rankChallenges(all.where((c) => !c.completed).toList(), limit: 3);
});

/// One event's achievements paired with the library game each seems to point
/// at. Reuses [gameProgressProvider] — an event is a game to the API.
final challengeTargetsProvider =
    FutureProvider.family<List<ChallengeTarget>, int>((ref, eventId) async {
  final game = await ref.watch(gameProgressProvider(eventId).future);
  final library = (await ref.watch(insightsRepositoryProvider)
              .completionProgress())
          .valueOrNull
          ?.value ??
      const <CompletionEntry>[];
  return matchTargets(game.achievements, library);
});

/// Window the rarest list is computed over. Defaults to the whole history.
final rarestWindowProvider =
    StateProvider<RarestWindow>((ref) => RarestWindow.all);

/// Loads separately from [dashboardProvider] so the all-time walk never holds
/// back the rest of the screen. Switching windows filters in memory — one
/// fetch serves all three.
final rarestProvider = FutureProvider<List<EarnedAchievement>>((ref) async {
  ref.watch(refreshCounterProvider);
  final window = ref.watch(rarestWindowProvider);
  final repo = ref.watch(insightsRepositoryProvider);
  final all = (await repo.allTimeAchievements()).unwrap().value;
  return computeRarest(withinDays(all, window.days), limit: 10);
});

final heatmapProvider = FutureProvider<HeatmapData>((ref) async {
  final events = await ref.watch(activityProvider.future);
  return heatmapDataFrom(events);
});

/// The grid for the modes currently toggled on. Shared by the Activity page
/// and the Profile tab's preview so both draw the same picture from one
/// computation instead of two copies of the same four lines.
final heatmapGridProvider = Provider<AsyncValue<HeatmapGrid>>((ref) {
  final modes = ref.watch(heatmapModesProvider);
  final events = ref.watch(activityProvider);
  return events.whenData((list) => buildHeatmap(
        heatmapDataFrom(filterActivity(list, modes: modes)),
        modes: modes,
      ));
});

/// One flat index of the year: unlocks and awards, tagged with mode and day.
/// The grid, the game list and the achievement list are all filters over it.
final activityProvider = FutureProvider<List<ActivityEvent>>((ref) async {
  ref.watch(refreshCounterProvider);
  final repo = ref.watch(insightsRepositoryProvider);
  final yearly = await repo.yearlyAchievements();
  final awards = await repo.awards();
  final completion = await repo.completionProgress();

  if (!yearly.isOk && !awards.isOk) throw yearly.errorOrNull!;

  final icons = <int, String>{
    for (final e in completion.valueOrNull?.value ?? const <CompletionEntry>[])
      e.gameId: e.iconUrl,
  };
  return buildActivityEvents(
    yearly.valueOrNull?.value ?? const [],
    awards.valueOrNull?.value ?? const [],
    icons: icons,
  );
});

/// Paging state of the "Jogos" tab — mirrors the site's `Show: N` selector
/// plus its page arrows.
class RecentGamesQuery {
  const RecentGamesQuery({this.pageSize = 5, this.page = 0});

  final int pageSize;
  final int page;

  int get offset => pageSize * page;

  RecentGamesQuery copyWith({int? pageSize, int? page}) => RecentGamesQuery(
        pageSize: pageSize ?? this.pageSize,
        page: page ?? this.page,
      );

  @override
  bool operator ==(Object other) =>
      other is RecentGamesQuery &&
      other.pageSize == pageSize &&
      other.page == page;

  @override
  int get hashCode => Object.hash(pageSize, page);
}

final recentGamesQueryProvider =
    StateProvider<RecentGamesQuery>((ref) => const RecentGamesQuery());

/// One page of `API_GetUserRecentlyPlayedGames`. The API reports no total, so
/// "there is a next page" is inferred from a full page coming back.
final recentGamesPageProvider = FutureProvider<Cached<List<RecentGame>>>((ref) async {
  ref.watch(refreshCounterProvider);
  final query = ref.watch(recentGamesQueryProvider);
  final repo = ref.watch(insightsRepositoryProvider);
  final res =
      await repo.recentGames(count: query.pageSize, offset: query.offset);
  return res.unwrap();
});

/// The grid cell currently selected, or null when no day is pinned.
final selectedDayProvider = StateProvider<String?>((ref) => null);

/// Full achievement list of one game. Cached so a game opened once still opens
/// offline; the TTL is short because unlock state is what the user came to see.
final gameProgressProvider =
    FutureProvider.family<GameProgress, int>((ref, gameId) async {
  final repo = ref.watch(insightsRepositoryProvider);
  return (await repo.gameProgress(gameId)).unwrap().value;
});

/// Gates the splash: resolves once the first screen has something to draw.
///
/// Waits a minimum beat so the logo never flashes, warms the dashboard when
/// signed in, and gives up after [_splashMaxWait] — every screen renders from
/// cache, so a dead connection must not trap anyone here.
const _splashMinimum = Duration(milliseconds: 1600);
const _splashMaxWait = Duration(seconds: 6);

final bootProvider = FutureProvider<void>((ref) async {
  final signedIn = ref.watch(sessionProvider).valueOrNull != null;
  final minimum = Future<void>.delayed(_splashMinimum);

  if (!signedIn) {
    await minimum;
    return;
  }

  // The warm-up can fail or hang; neither is a reason to hold the splash, since
  // the dashboard renders from cache and surfaces its own errors.
  final warmup = ref
      .watch(dashboardProvider.future)
      .then<void>((_) {}, onError: (_, __) {})
      .timeout(_splashMaxWait, onTimeout: () {});

  await Future.wait([minimum, warmup]);
});

/// The username to prefill on the sign-in screen, and whether to keep it.
final lastUsernameProvider = FutureProvider<String?>(
    (ref) => ref.watch(prefsRepositoryProvider).loadLastUsername());

final rememberMeProvider =
    FutureProvider<bool>((ref) => ref.watch(prefsRepositoryProvider).rememberMe());

final gameSearchQueryProvider = StateProvider<String>((ref) => '');

/// Searches the games the user has already played — the API has no
/// search-by-title endpoint, so the local library is the index.
final gameSearchProvider = FutureProvider<List<CompletionEntry>>((ref) async {
  final query = ref.watch(gameSearchQueryProvider);
  if (query.trim().isEmpty) return const [];
  final repo = ref.watch(insightsRepositoryProvider);
  final completion = await repo.completionProgress();
  return searchGames(completion.valueOrNull?.value ?? const [], query);
});

/// Another player's profile, summary and wall.
class PlayerView {
  const PlayerView({
    required this.profile,
    required this.summary,
    required this.comments,
  });

  final UserProfile profile;
  final UserSummary? summary;
  final List<UserComment> comments;
}

final playerProvider =
    FutureProvider.family<PlayerView, String>((ref, username) async {
  final api = ref.watch(raApiProvider);
  final profile = (await api.getProfileOf(username)).unwrap();
  if (profile.user.trim().isEmpty) {
    throw const AppError(AppErrorKind.notFound, 'usuário inexistente');
  }
  final summary = (await api.getSummaryOf(username)).valueOrNull;
  final comments = (await api.getUserComments(username)).valueOrNull ?? const [];
  return PlayerView(profile: profile, summary: summary, comments: comments);
});

final heatmapModesProvider = StateProvider<Set<HeatmapMode>>(
  (ref) => {HeatmapMode.achievements, HeatmapMode.mastered, HeatmapMode.beaten},
);

/// Profile of the signed-in user, for the profile screen.
final myProfileProvider = FutureProvider<UserProfile>((ref) async {
  ref.watch(refreshCounterProvider);
  final repo = ref.watch(insightsRepositoryProvider);
  return (await repo.profile()).unwrap().value;
});

/// Trophies and masteries, for the profile screen's Prêmios section. Already
/// cached and fetched by [activityProvider] to build the heatmap; this just
/// reuses the same call instead of asking the API twice.
enum AwardFilter { all, mastered, beaten }

final awardFilterProvider = StateProvider<AwardFilter>((ref) => AwardFilter.all);

final myAwardsProvider = FutureProvider<List<UserAward>>((ref) async {
  ref.watch(refreshCounterProvider);
  final repo = ref.watch(insightsRepositoryProvider);
  return (await repo.awards()).unwrap().value;
});

/// The signed-in user's own wall — same endpoint [playerProvider] uses for
/// other players, just pointed at the current session's username. Not
/// cached: the wall is the one thing on this screen that is not core to
/// working offline, and matches how another player's wall is fetched too.
final myWallProvider = FutureProvider<List<UserComment>>((ref) async {
  final username = ref.watch(sessionProvider).valueOrNull?.username;
  if (username == null) return const [];
  final api = ref.watch(raApiProvider);
  return (await api.getUserComments(username)).valueOrNull ?? const [];
});

final progressionFilterProvider =
    StateProvider<ProgressionFilter>((ref) => ProgressionFilter.all);

final progressionProvider = FutureProvider<List<CompletionEntry>>((ref) async {
  ref.watch(refreshCounterProvider);
  final repo = ref.watch(insightsRepositoryProvider);
  final res = await repo.completionProgress();
  return res.unwrap().value;
});

/// Pull-to-refresh: bump the counter, every screen re-reads with `refresh: true`.
Future<void> refreshAll(WidgetRef ref) async {
  final repo = ref.read(insightsRepositoryProvider);
  await Future.wait([
    repo.summary(refresh: true),
    repo.recentGames(refresh: true),
    repo.allTimeAchievements(refresh: true),
    repo.yearlyAchievements(refresh: true),
    repo.awards(refresh: true),
    repo.completionProgress(refresh: true),
  ]);
  ref.read(refreshCounterProvider.notifier).state++;
  ref.invalidate(dashboardProvider);
  ref.invalidate(heatmapProvider);
  ref.invalidate(progressionProvider);
  ref.invalidate(activityProvider);
  ref.invalidate(recentGamesPageProvider);
  ref.invalidate(rarestProvider);
  // The catalogue keeps its 30-day cache; only the user's side is re-derived.
  ref.invalidate(challengeCatalogProvider);
  // Not covered by refreshCounterProvider: it depends only on the session.
  ref.invalidate(myWallProvider);
}

/// Refresh scoped to the visible page of the "Jogos" tab — [refreshAll] only
/// refetches the dashboard's own 50-game page.
Future<void> refreshRecentGames(WidgetRef ref) async {
  final query = ref.read(recentGamesQueryProvider);
  await ref.read(insightsRepositoryProvider).recentGames(
        count: query.pageSize,
        offset: query.offset,
        refresh: true,
      );
  ref.invalidate(recentGamesPageProvider);
}
