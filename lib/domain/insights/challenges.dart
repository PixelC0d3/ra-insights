/// Challenges — the RetroAchievements events, seen as things to finish.
///
/// An event is a game on the Events system, so the catalogue comes from
/// `API_GetGameList` and the user's progress is derived from unlocks we already
/// fetch. Nothing here costs a request per event.
library;

import '../models/models.dart';
import 'rarity.dart';
import 'search.dart';

class Challenge {
  const Challenge({
    required this.gameId,
    required this.title,
    required this.iconUrl,
    required this.totalAchievements,
    required this.totalPoints,
    required this.earned,
    required this.updatedAt,
    required this.earnedRarity,
  });

  final int gameId;
  final String title;
  final String iconUrl;
  final int totalAchievements;
  final int totalPoints;
  final int earned;

  /// When the event set last changed — drives the "recent" ordering.
  final DateTime? updatedAt;

  /// Average TrueRatio multiplier of what the user unlocked here. Null until
  /// they earn something: the catalogue carries no per-achievement rarity, so
  /// this is the only rarity available without a request per event.
  final double? earnedRarity;

  RarityTier? get rarityTier =>
      earnedRarity == null ? null : rarityFromMultiplier(earnedRarity!);

  bool get started => earned > 0;
  bool get completed => totalAchievements > 0 && earned >= totalAchievements;
  int get remaining =>
      totalAchievements > earned ? totalAchievements - earned : 0;

  double get progress =>
      totalAchievements > 0 ? earned / totalAchievements : 0;
  int get percent => (progress * 100).round();
}

enum ChallengeFilter { all, inProgress, notStarted, completed }

enum ChallengeSort { closest, recent, biggest }

/// Merges the catalogue with what the user has actually unlocked.
///
/// [allTime] is the full unlock history, which carries event achievements like
/// any other. [completion] is preferred where it covers an event, since it is
/// the API's own tally rather than a count of rows.
List<Challenge> buildChallenges(
  List<GameListEntry> catalog,
  List<EarnedAchievement> allTime, {
  List<CompletionEntry> completion = const [],
}) {
  // Distinct ids: the same achievement appears twice when it was unlocked in
  // both softcore and hardcore.
  final unlocked = <int, Set<int>>{};
  final byGame = <int, List<EarnedAchievement>>{};
  for (final a in allTime) {
    if (unlocked.putIfAbsent(a.gameId, () => <int>{}).add(a.achievementId)) {
      byGame.putIfAbsent(a.gameId, () => <EarnedAchievement>[]).add(a);
    }
  }

  final tallied = <int, CompletionEntry>{
    for (final e in completion) e.gameId: e,
  };

  final out = <Challenge>[];
  for (final game in catalog) {
    final entry = tallied[game.gameId];
    final mine = byGame[game.gameId] ?? const <EarnedAchievement>[];
    out.add(Challenge(
      gameId: game.gameId,
      title: game.title,
      iconUrl: game.iconUrl,
      totalAchievements: entry != null && entry.maxPossible > 0
          ? entry.maxPossible
          : game.numAchievements,
      totalPoints: game.points,
      earned: entry?.earned ?? unlocked[game.gameId]?.length ?? 0,
      updatedAt: game.dateModified,
      earnedRarity: _averageRarity(mine),
    ));
  }
  return out;
}

/// Mean of the usable TrueRatio multipliers; null when none can be computed.
double? _averageRarity(List<EarnedAchievement> items) {
  var sum = 0.0;
  var count = 0;
  for (final a in items) {
    final multiplier = a.rarityMultiplier;
    if (multiplier != null) {
      sum += multiplier;
      count++;
    }
  }
  return count == 0 ? null : sum / count;
}

List<Challenge> filterChallenges(
  List<Challenge> challenges,
  ChallengeFilter filter,
) =>
    switch (filter) {
      ChallengeFilter.all => challenges,
      ChallengeFilter.inProgress =>
        challenges.where((c) => c.started && !c.completed).toList(),
      ChallengeFilter.notStarted =>
        challenges.where((c) => !c.started).toList(),
      ChallengeFilter.completed =>
        challenges.where((c) => c.completed).toList(),
    };

/// Closest to done first.
///
/// Buckets before scores, deliberately: a single arithmetic score that mixes
/// progress with the remaining count buries a barely-started event (1 of 42)
/// below untouched ones, which is the opposite of useful. Something begun
/// always outranks something untouched; finished sinks to the bottom.
List<Challenge> rankChallenges(List<Challenge> challenges, {int? limit}) {
  final out = challenges.toList()
    ..sort((a, b) {
      final byBucket = _bucket(a).compareTo(_bucket(b));
      if (byBucket != 0) return byBucket;
      final byProgress = b.progress.compareTo(a.progress);
      if (byProgress != 0) return byProgress;
      // Same proportion: the shorter tail is the one to finish first.
      final byRemaining = a.remaining.compareTo(b.remaining);
      if (byRemaining != 0) return byRemaining;
      return a.title.compareTo(b.title);
    });
  if (limit == null || out.length <= limit) return out;
  return out.sublist(0, limit);
}

int _bucket(Challenge c) {
  if (c.completed) return 2;
  return c.started ? 0 : 1;
}

/// Title search over the catalogue, accent- and case-insensitive. Reuses the
/// same normalizer the game search uses, so "roleta" behaves like "Roleta".
List<Challenge> searchChallenges(List<Challenge> challenges, String query) {
  final q = normalizeForSearch(query);
  if (q.isEmpty) return challenges;
  return challenges
      .where((c) => normalizeForSearch(c.title).contains(q))
      .toList();
}

/// Newest first. Events with no date sink to the bottom rather than being
/// dropped — an unknown date is not the same as an old one.
List<Challenge> sortChallenges(List<Challenge> challenges, ChallengeSort sort) {
  switch (sort) {
    case ChallengeSort.closest:
      return rankChallenges(challenges);
    case ChallengeSort.recent:
      final dated = challenges.where((c) => c.updatedAt != null).toList()
        ..sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));
      return [...dated, ...challenges.where((c) => c.updatedAt == null)];
    case ChallengeSort.biggest:
      return challenges.toList()
        ..sort((a, b) {
          final byCount =
              b.totalAchievements.compareTo(a.totalAchievements);
          return byCount != 0 ? byCount : a.title.compareTo(b.title);
        });
  }
}
