/// Games closest to mastery — port of `insights/almost-there.js` + its slice
/// of `data.js`.
library;

import '../models/models.dart';

class AlmostThereGame {
  const AlmostThereGame({
    required this.gameId,
    required this.title,
    required this.iconUrl,
    required this.consoleName,
    required this.earned,
    required this.total,
  });

  final int gameId;
  final String title;
  final String iconUrl;
  final String consoleName;
  final int earned;
  final int total;

  int get remaining => total - earned;
  double get progress => total > 0 ? earned / total : 0;
  int get percent => total > 0 ? (earned / total * 100).round() : 0;
}

/// Threshold and cap match the userscript: at least 50% done, not finished,
/// top 5 by proximity.
List<AlmostThereGame> computeAlmostThere(
  List<RecentGame> games, {
  double minProgress = 0.5,
  int limit = 5,
}) {
  final out = <AlmostThereGame>[];
  for (final g in games) {
    final total = g.numPossible;
    final earned = g.numAchieved;
    if (total <= 0 || earned >= total) continue;
    if (earned / total < minProgress) continue;
    out.add(AlmostThereGame(
      gameId: g.gameId,
      title: g.title,
      iconUrl: g.iconUrl,
      consoleName: g.consoleName,
      earned: earned,
      total: total,
    ));
  }
  out.sort((a, b) => b.progress.compareTo(a.progress));
  return out.length > limit ? out.sublist(0, limit) : out;
}
