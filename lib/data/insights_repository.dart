/// Repositories: cache-then-network, DTO → domain.
library;

import '../core/api/ra_api.dart';
import '../core/result.dart';
import '../domain/models/models.dart';
import 'cache.dart';

class InsightsRepository {
  InsightsRepository({required this.api, required this.cache});

  final RaApi api;
  final CacheStore cache;

  String _key(String suffix) => '${api.client.credentials?.username ?? '?'}:$suffix';

  Future<Result<Cached<UserProfile>>> profile({bool refresh = false}) =>
      cacheThenNetwork<UserProfile>(
        store: cache,
        key: _key('profile'),
        ttl: CacheTtl.profile,
        decode: (j) => UserProfile.fromJson(Map<String, dynamic>.from(j as Map)),
        encode: (v) => v.toJson(),
        fetch: () => api.getUserProfile(),
        forceRefresh: refresh,
      );

  Future<Result<Cached<UserSummary>>> summary({bool refresh = false}) =>
      cacheThenNetwork<UserSummary>(
        store: cache,
        key: _key('summary'),
        ttl: CacheTtl.profile,
        decode: (j) => UserSummary.fromJson(Map<String, dynamic>.from(j as Map)),
        encode: (v) => v.toJson(),
        fetch: api.getUserSummary,
        forceRefresh: refresh,
      );

  /// Each page is cached under its own key, so paging back and forth is free.
  Future<Result<Cached<List<RecentGame>>>> recentGames({
    bool refresh = false,
    int count = 50,
    int offset = 0,
  }) =>
      cacheThenNetwork<List<RecentGame>>(
        store: cache,
        key: _key('recent_games:$count:$offset'),
        ttl: CacheTtl.recent,
        decode: (j) => (j as List)
            .map((e) => RecentGame.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        encode: (v) => v.map((e) => e.toJson()).toList(),
        fetch: () => api.getRecentlyPlayedGames(count: count, offset: offset),
        forceRefresh: refresh,
      );

  Future<Result<Cached<List<EarnedAchievement>>>> recentAchievements(
          {bool refresh = false}) =>
      cacheThenNetwork<List<EarnedAchievement>>(
        store: cache,
        key: _key('recent_achievements'),
        ttl: CacheTtl.recent,
        decode: _decodeAchievements,
        encode: (v) => v.map((e) => e.toJson()).toList(),
        fetch: () => api.getRecentAchievements(),
        forceRefresh: refresh,
      );

  /// A year of unlocks in 4 quarterly chunks, deduped across the overlapping
  /// boundaries. Cached for 6h — it is the most expensive call in the app.
  Future<Result<Cached<List<EarnedAchievement>>>> yearlyAchievements(
          {bool refresh = false}) =>
      cacheThenNetwork<List<EarnedAchievement>>(
        store: cache,
        key: _key('yearly'),
        ttl: CacheTtl.yearly,
        decode: _decodeAchievements,
        encode: (v) => v.map((e) => e.toJson()).toList(),
        fetch: _fetchYearly,
        forceRefresh: refresh,
      );

  /// Every unlock since the account was created, walked in one-year chunks.
  /// Five requests for a five-year-old account, against the twenty a quarterly
  /// walk would cost — the rarest list does not need day-level chunking.
  Future<Result<Cached<List<EarnedAchievement>>>> allTimeAchievements(
          {bool refresh = false}) =>
      cacheThenNetwork<List<EarnedAchievement>>(
        store: cache,
        key: _key('alltime'),
        ttl: CacheTtl.yearly,
        decode: _decodeAchievements,
        encode: (v) => v.map((e) => e.toJson()).toList(),
        fetch: _fetchAllTime,
        forceRefresh: refresh,
      );

  /// One game's achievements and the user's progress in it. Cached so an
  /// already-opened game still works with no connection.
  Future<Result<Cached<GameProgress>>> gameProgress(int gameId,
          {bool refresh = false}) =>
      cacheThenNetwork<GameProgress>(
        store: cache,
        key: _key('game:$gameId'),
        ttl: CacheTtl.recent,
        decode: (j) => GameProgress.fromJson(Map<String, dynamic>.from(j as Map)),
        encode: (v) => v.toJson(),
        fetch: () => api.getGameInfoAndUserProgress(gameId),
        forceRefresh: refresh,
      );

  /// The site's systems. Barely ever changes, hence the 30-day TTL.
  Future<Result<Cached<List<ConsoleInfo>>>> consoles({bool refresh = false}) =>
      cacheThenNetwork<List<ConsoleInfo>>(
        store: cache,
        key: 'consoles',
        ttl: CacheTtl.consoles,
        decode: (j) => (j as List)
            .map((e) => ConsoleInfo.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        encode: (v) => v.map((e) => e.toJson()).toList(),
        fetch: () => api.getConsoleIds(),
        forceRefresh: refresh,
      );

  /// Every event, as listed under the Events system. Two requests on a cold
  /// cache, then nothing for a month — the catalogue is not per-user.
  Future<Result<Cached<List<GameListEntry>>>> eventCatalog(
          {bool refresh = false}) =>
      cacheThenNetwork<List<GameListEntry>>(
        store: cache,
        key: 'event_catalog',
        ttl: CacheTtl.consoles,
        decode: (j) => (j as List)
            .map((e) =>
                GameListEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        encode: (v) => v.map((e) => e.toJson()).toList(),
        fetch: _fetchEventCatalog,
        forceRefresh: refresh,
      );

  Future<Result<List<GameListEntry>>> _fetchEventCatalog() async {
    final systems = await consoles();
    final list = systems.valueOrNull?.value;
    if (list == null) {
      return Err(systems.errorOrNull ??
          const AppError(AppErrorKind.unknown, 'consoles unavailable'));
    }

    // Matched by name, not by a hardcoded id: the id is not documented and
    // guessing it would fail silently against the wrong system.
    for (final system in list) {
      if (system.name.trim().toLowerCase() == 'events') {
        return api.getGameList(system.id);
      }
    }
    return const Err(
        AppError(AppErrorKind.notFound, 'no Events system on this site'));
  }

  Future<Result<Cached<List<UserAward>>>> awards({bool refresh = false}) =>
      cacheThenNetwork<List<UserAward>>(
        store: cache,
        key: _key('awards'),
        ttl: CacheTtl.yearly,
        decode: (j) => (j as List)
            .map((e) => UserAward.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        encode: (v) => v.map((e) => e.toJson()).toList(),
        fetch: api.getUserAwards,
        forceRefresh: refresh,
      );

  Future<Result<Cached<List<CompletionEntry>>>> completionProgress(
          {bool refresh = false}) =>
      cacheThenNetwork<List<CompletionEntry>>(
        store: cache,
        key: _key('completion'),
        ttl: CacheTtl.yearly,
        decode: (j) => (j as List)
            .map((e) => CompletionEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        encode: (v) => v.map((e) => e.toJson()).toList(),
        fetch: _fetchCompletion,
        forceRefresh: refresh,
      );

  Future<Result<List<EarnedAchievement>>> _fetchYearly() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 365));
    final quarter =
        Duration(microseconds: (now.difference(start).inMicroseconds / 4).ceil());

    final all = <EarnedAchievement>[];
    AppError? lastError;
    for (var q = 0; q < 4; q++) {
      final from = start.add(quarter * q);
      final to = q < 3 ? start.add(quarter * (q + 1)) : now;
      final res = await api.getAchievementsEarnedBetween(from, to);
      switch (res) {
        case Ok(:final value):
          all.addAll(value);
        case Err(:final error):
          lastError = error;
      }
    }
    // Every chunk failed: surface the error instead of an empty year.
    if (all.isEmpty && lastError != null) return Err(lastError);
    return Ok(dedupeAchievements(all));
  }

  Future<Result<List<EarnedAchievement>>> _fetchAllTime() async {
    final now = DateTime.now();
    final profile = (await api.getUserProfile()).valueOrNull;

    // Without a usable join date, a year back is the most we can honestly
    // claim. The floor also stops a bogus date from fanning out to hundreds
    // of requests.
    final floor = now.subtract(const Duration(days: 365 * 20));
    var from = profile?.memberSince ?? now.subtract(const Duration(days: 365));
    if (from.isAfter(now) || from.isBefore(floor)) {
      from = now.subtract(const Duration(days: 365));
    }

    final all = <EarnedAchievement>[];
    AppError? lastError;
    while (from.isBefore(now)) {
      final next = from.add(const Duration(days: 365));
      final to = next.isAfter(now) ? now : next;
      final res = await api.getAchievementsEarnedBetween(from, to);
      switch (res) {
        case Ok(:final value):
          all.addAll(value);
        case Err(:final error):
          lastError = error;
      }
      from = next;
    }
    // Every chunk failed: surface the error instead of an empty history.
    if (all.isEmpty && lastError != null) return Err(lastError);
    return Ok(dedupeAchievements(all));
  }

  Future<Result<List<CompletionEntry>>> _fetchCompletion() async {
    const pageSize = 500;
    final all = <CompletionEntry>[];
    var offset = 0;
    while (true) {
      final res =
          await api.getUserCompletionProgress(count: pageSize, offset: offset);
      switch (res) {
        case Err(:final error):
          if (all.isEmpty) return Err(error);
          return Ok(all);
        case Ok(:final value):
          all.addAll(value.results);
          offset += value.results.length;
          if (value.results.length < pageSize || offset >= value.total) {
            return Ok(all);
          }
      }
    }
  }

  List<EarnedAchievement> _decodeAchievements(dynamic j) => (j as List)
      .map((e) => EarnedAchievement.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

/// Quarterly chunks overlap at the boundaries; the key is
/// `AchievementID|Date|HardcoreMode`.
List<EarnedAchievement> dedupeAchievements(List<EarnedAchievement> items) {
  final seen = <String>{};
  final out = <EarnedAchievement>[];
  for (final a in items) {
    if (seen.add(a.chunkKey)) out.add(a);
  }
  return out;
}
