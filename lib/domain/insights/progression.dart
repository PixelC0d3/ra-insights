/// Per-console progression — the API replacement for `scrapeConsoleBreakdown()`.
///
/// Same output shape as the DOM scrape it retires, built from
/// `API_GetUserCompletionProgress`.
library;

import '../models/models.dart';

enum ProgressionFilter { all, withProgress, mastered }

class ConsoleProgress {
  const ConsoleProgress({
    required this.consoleId,
    required this.consoleName,
    required this.total,
    required this.unfinished,
    required this.beaten,
    required this.mastered,
  });

  final int consoleId;
  final String consoleName;
  final int total;
  final int unfinished;
  final int beaten;
  final int mastered;

  int get finished => beaten + mastered;
  double get masteryRate => total > 0 ? mastered / total : 0;
}

class ProgressionBreakdown {
  const ProgressionBreakdown({
    required this.consoles,
    required this.totalGames,
    required this.totalMastered,
    required this.totalBeaten,
  });

  const ProgressionBreakdown.empty()
      : consoles = const [],
        totalGames = 0,
        totalMastered = 0,
        totalBeaten = 0;

  final List<ConsoleProgress> consoles;
  final int totalGames;
  final int totalMastered;
  final int totalBeaten;

  bool get isEmpty => consoles.isEmpty;

  /// Same number the stats cards used to read off the profile page.
  int get masteryRatePercent =>
      totalGames > 0 ? (totalMastered / totalGames * 100).round() : 0;
}

/// [entries] is the full, already paginated `Results` list.
ProgressionBreakdown computeProgression(List<CompletionEntry> entries) {
  if (entries.isEmpty) return const ProgressionBreakdown.empty();

  final byConsole = <int, List<CompletionEntry>>{};
  final names = <int, String>{};
  for (final e in entries) {
    byConsole.putIfAbsent(e.consoleId, () => []).add(e);
    names[e.consoleId] = e.consoleName;
  }

  var totalGames = 0;
  var totalMastered = 0;
  var totalBeaten = 0;
  final consoles = <ConsoleProgress>[];

  byConsole.forEach((consoleId, games) {
    var mastered = 0;
    var beaten = 0;
    for (final g in games) {
      final kind = g.highestAwardKind;
      if (kind != null && kind.isMastery) {
        mastered++;
      } else if (kind != null && kind.isBeaten) {
        beaten++;
      }
    }
    final unfinished = games.length - mastered - beaten;
    totalGames += games.length;
    totalMastered += mastered;
    totalBeaten += beaten;
    consoles.add(ConsoleProgress(
      consoleId: consoleId,
      consoleName: names[consoleId] ?? 'Console $consoleId',
      total: games.length,
      unfinished: unfinished,
      beaten: beaten,
      mastered: mastered,
    ));
  });

  consoles.sort((a, b) {
    final byTotal = b.total.compareTo(a.total);
    return byTotal != 0 ? byTotal : a.consoleName.compareTo(b.consoleName);
  });

  return ProgressionBreakdown(
    consoles: consoles,
    totalGames: totalGames,
    totalMastered: totalMastered,
    totalBeaten: totalBeaten,
  );
}

List<ConsoleProgress> applyProgressionFilter(
  List<ConsoleProgress> consoles,
  ProgressionFilter filter,
) =>
    switch (filter) {
      ProgressionFilter.all => consoles,
      ProgressionFilter.withProgress =>
        consoles.where((c) => c.finished > 0).toList(),
      ProgressionFilter.mastered => consoles.where((c) => c.mastered > 0).toList(),
    };

List<CompletionEntry> filterConsoleGames(
  List<CompletionEntry> entries,
  ProgressionFilter filter,
) =>
    switch (filter) {
      ProgressionFilter.all => entries,
      ProgressionFilter.withProgress =>
        entries.where((e) => e.earned > 0).toList(),
      ProgressionFilter.mastered =>
        entries.where((e) => e.highestAwardKind?.isMastery ?? false).toList(),
    };
