import 'package:flutter_test/flutter_test.dart';
import 'package:ra_insights/domain/insights/progression.dart';
import 'package:ra_insights/domain/models/models.dart';

void main() {
  CompletionEntry entry({
    int id = 1,
    int consoleId = 1,
    String consoleName = 'NES',
    String? kind,
    int awarded = 5,
    int max = 10,
  }) =>
      CompletionEntry.fromJson({
        'GameID': id,
        'Title': 'Game $id',
        'ConsoleID': consoleId,
        'ConsoleName': consoleName,
        'MaxPossible': max,
        'NumAwarded': awarded,
        'NumAwardedHardcore': awarded,
        'HighestAwardKind': kind,
      });

  test('empty input yields an empty breakdown without dividing by zero', () {
    final b = computeProgression(const []);
    expect(b.isEmpty, isTrue);
    expect(b.masteryRatePercent, 0);
  });

  test('totals replace what scrapeConsoleBreakdown() used to read off the DOM', () {
    final b = computeProgression([
      entry(id: 1, kind: 'mastered'),
      entry(id: 2, kind: 'completed'),
      entry(id: 3, kind: 'beaten-hardcore'),
      entry(id: 4, kind: 'beaten-softcore'),
      entry(id: 5),
      entry(id: 6, consoleId: 2, consoleName: 'SNES', kind: 'mastered'),
    ]);

    expect(b.totalGames, 6);
    expect(b.totalMastered, 3); // mastered + completed
    expect(b.totalBeaten, 2);
    expect(b.masteryRatePercent, 50);

    final nes = b.consoles.firstWhere((c) => c.consoleId == 1);
    expect(nes.total, 5);
    expect(nes.mastered, 2);
    expect(nes.beaten, 2);
    expect(nes.unfinished, 1);
  });

  test('consoles are ordered by game count', () {
    final b = computeProgression([
      entry(id: 1, consoleId: 2, consoleName: 'SNES'),
      entry(id: 2, consoleId: 1, consoleName: 'NES'),
      entry(id: 3, consoleId: 1, consoleName: 'NES'),
    ]);
    expect(b.consoles.first.consoleName, 'NES');
  });

  test('filters narrow the console list', () {
    final b = computeProgression([
      entry(id: 1, consoleId: 1, consoleName: 'NES', kind: 'mastered'),
      entry(id: 2, consoleId: 2, consoleName: 'SNES', kind: 'beaten-hardcore'),
      entry(id: 3, consoleId: 3, consoleName: 'GB'),
    ]);
    expect(applyProgressionFilter(b.consoles, ProgressionFilter.all).length, 3);
    expect(
        applyProgressionFilter(b.consoles, ProgressionFilter.withProgress).length, 2);
    expect(applyProgressionFilter(b.consoles, ProgressionFilter.mastered).length, 1);
  });

  test('"beaten-casual" is accepted alongside the legacy "beaten-softcore"', () {
    expect(AwardKind.parse('beaten-casual'), AwardKind.beatenSoftcore);
    expect(AwardKind.parse('beaten-softcore'), AwardKind.beatenSoftcore);
    expect(AwardKind.parse('nonsense'), isNull);
  });

  test('award kind survives a cache round-trip', () {
    // Writing `AwardKind.name` instead of the API spelling used to drop every
    // beaten award on the way back out of the cache.
    for (final kind in AwardKind.values) {
      final cached = entry(kind: kind.wire).toJson();
      final back = CompletionEntry.fromJson(cached);
      expect(back.highestAwardKind, kind, reason: kind.name);
    }
  });

  test('a cache written with the old enum names still parses', () {
    for (final kind in AwardKind.values) {
      expect(AwardKind.parse(kind.name), kind, reason: kind.name);
    }
  });

  test('beaten games are counted even when the payload came from cache', () {
    final cached = [
      entry(id: 1, kind: 'beaten-hardcore'),
      entry(id: 2, kind: 'beaten-softcore'),
      entry(id: 3, kind: 'mastered'),
    ].map((e) => CompletionEntry.fromJson(e.toJson())).toList();

    final b = computeProgression(cached);
    expect(b.totalBeaten, 2);
    expect(b.totalMastered, 1);
  });
}
