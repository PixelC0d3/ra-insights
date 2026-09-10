/// Rarity: how hard an achievement actually is, and the tiers the UI colours by.
///
/// Two inputs, in order of preference:
///  * the **unlock rate** — how many of the game's players got it. Exact, but
///    only `API_GetGameInfoAndUserProgress` carries the player counts.
///  * the **TrueRatio multiplier** (`TrueRatio / Points`) — an approximation,
///    used for the recent-unlock endpoints, which ship no player counts.
library;

import '../models/models.dart';

enum RarityTier { common, uncommon, rare, veryRare, ultraRare }

/// Time window the "rarest" list is computed over. `all` means every unlock
/// since the account was created.
enum RarestWindow { all, days90, days30 }

extension RarestWindowDays on RarestWindow {
  /// `null` for [RarestWindow.all] — no cutoff at all.
  int? get days => switch (this) {
        RarestWindow.all => null,
        RarestWindow.days90 => 90,
        RarestWindow.days30 => 30,
      };
}

/// Narrows a list of unlocks to the last [days]. A `null` [days] returns the
/// list untouched; entries with no date are dropped, since they cannot be
/// placed in any window.
List<EarnedAchievement> withinDays(
  List<EarnedAchievement> items,
  int? days, {
  DateTime? now,
}) {
  if (days == null) return items;
  final cutoff = (now ?? DateTime.now()).subtract(Duration(days: days));
  return items
      .where((a) => a.dateTime != null && a.dateTime!.isAfter(cutoff))
      .toList();
}

/// Cutoffs in percent of players. Below 5% is where the site itself starts
/// calling an achievement rare.
RarityTier rarityFromUnlockRate(double percent) {
  if (percent < 5) return RarityTier.ultraRare;
  if (percent < 15) return RarityTier.veryRare;
  if (percent < 30) return RarityTier.rare;
  if (percent < 55) return RarityTier.uncommon;
  return RarityTier.common;
}

/// Fallback tiering. TrueRatio inflates as fewer people unlock something, so
/// the multiplier tracks rarity — loosely, which is why the exact rate wins
/// whenever it is available.
RarityTier rarityFromMultiplier(double multiplier) {
  if (multiplier >= 12) return RarityTier.ultraRare;
  if (multiplier >= 6) return RarityTier.veryRare;
  if (multiplier >= 3) return RarityTier.rare;
  if (multiplier >= 1.5) return RarityTier.uncommon;
  return RarityTier.common;
}

/// The tier for one achievement of a game, preferring the exact rate.
RarityTier? rarityOf(GameProgress game, GameAchievement achievement) {
  final rate = game.unlockRate(achievement);
  if (rate != null) return rarityFromUnlockRate(rate);
  final multiplier = achievement.rarityMultiplier;
  return multiplier == null ? null : rarityFromMultiplier(multiplier);
}

/// Filters out entries without usable rarity, sorts by the TrueRatio
/// multiplier desc, dedupes by achievement id and caps the list.
///
/// The multiplier, not raw TrueRatio: it is what the row displays, and a list
/// ordered by a number the user cannot see reads as unsorted. It is also the
/// better answer to "rarest" — raw TrueRatio rewards expensive achievements,
/// while the ratio measures how far above its point value one actually is.
List<EarnedAchievement> computeRarest(
  List<EarnedAchievement> achievements, {
  int limit = 5,
}) {
  final usable =
      achievements.where((a) => a.rarityMultiplier != null).toList()
        ..sort((a, b) {
          final byRatio =
              b.rarityMultiplier!.compareTo(a.rarityMultiplier!);
          // Same ratio: the costlier achievement is the harder one.
          return byRatio != 0 ? byRatio : b.trueRatio.compareTo(a.trueRatio);
        });

  final seen = <int>{};
  final out = <EarnedAchievement>[];
  for (final a in usable) {
    if (!seen.add(a.achievementId)) continue;
    out.add(a);
    if (out.length == limit) break;
  }
  return out;
}
