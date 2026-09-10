import 'package:flutter_test/flutter_test.dart';
import 'package:ra_insights/domain/insights/heatmap.dart';
import 'package:ra_insights/domain/models/models.dart';

import 'helpers.dart';

void main() {
  final today = DateTime.utc(2026, 8, 29); // Saturday
  String day(int ago) {
    final d = today.subtract(Duration(days: ago));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  UserAward award(String type, int extra, String date) => UserAward.fromJson({
        'AwardedAt': '${date}T18:00:00+00:00',
        'AwardType': type,
        'AwardData': '42',
        'AwardDataExtra': extra,
        'Title': 'Game',
      });

  test('grid covers a full year, starts on Sunday and ends today', () {
    final grid = buildHeatmap(const HeatmapData.empty(), today: today);
    expect(grid.cells.first.weekday, 0);
    expect(grid.cells.last.dayKey, '2026-08-29');
    expect(grid.cells.length, greaterThanOrEqualTo(365));
    expect(grid.weeks, 53);
  });

  test('awards map to mastered and beaten buckets', () {
    final data = buildHeatmapData(
      [ach(date: '${day(2)} 10:00:00')],
      [
        award('Mastery/Completion', 1, day(1)), // mastered
        award('Mastery/Completion', 0, day(1)), // completed also counts as mastery
        award('Game Beaten', 1, day(3)),
        award('Game Beaten', 0, day(3)), // casual (ex-softcore)
      ],
      today: today,
    );
    expect(data.mastered[day(1)], 2);
    expect(data.beaten[day(3)], 2);
    expect(data.achievements[day(2)], 1);
  });

  test('awards older than a year are dropped', () {
    final data = buildHeatmapData(
      const [],
      [award('Game Beaten', 1, '2024-01-05')],
      today: today,
    );
    expect(data.beaten, isEmpty);
  });

  test('modes are combinable and counts add up', () {
    final data = HeatmapData(
      achievements: {day(1): 3},
      mastered: {day(1): 1},
      beaten: const {},
    );
    final all = buildHeatmap(data, today: today);
    expect(all.total, 4);

    final onlyAch = buildHeatmap(data,
        modes: const {HeatmapMode.achievements}, today: today);
    expect(onlyAch.total, 3);
  });

  test('mastered wins the colour when several modes hit the same day', () {
    final data = HeatmapData(
      achievements: {day(1): 3},
      mastered: {day(1): 1},
      beaten: {day(1): 1},
    );
    final grid = buildHeatmap(data, today: today);
    final cell = grid.cells.firstWhere((c) => c.dayKey == day(1));
    expect(cell.source, HeatmapMode.mastered);
  });

  test('no modes selected yields an empty grid', () {
    expect(buildHeatmap(const HeatmapData.empty(), modes: const {}, today: today)
        .isEmpty, isTrue);
  });

  group('intensity buckets', () {
    test('zero is level zero', () => expect(intensityLevel(0, 10), 0));
    test('sparse data uses raw counts', () {
      expect(intensityLevel(1, 3), 1);
      expect(intensityLevel(3, 3), 3);
    });
    test('dense data scales against the busiest day', () {
      expect(intensityLevel(5, 20), 1);
      expect(intensityLevel(10, 20), 2);
      expect(intensityLevel(15, 20), 3);
      expect(intensityLevel(20, 20), 4);
    });
  });
}
