/// 365-day activity grid — port of `insights/timeline.js`.
library;

import '../models/models.dart';
import '../../core/parsing.dart';
import 'streaks.dart';

enum HeatmapMode { achievements, mastered, beaten }

class HeatmapCell {
  const HeatmapCell({
    required this.dayKey,
    required this.date,
    required this.week,
    required this.weekday,
    required this.count,
    required this.level,
    required this.source,
  });

  final String dayKey;
  final DateTime date;
  final int week;

  /// 0 = Sunday, matching the site's grid.
  final int weekday;
  final int count;

  /// 0..4 intensity bucket.
  final int level;

  /// Which mode colours this cell (priority mastered > beaten > achievements).
  final HeatmapMode? source;
}

class HeatmapMonthLabel {
  const HeatmapMonthLabel(this.week, this.month);
  final int week;
  final int month;
}

class HeatmapGrid {
  const HeatmapGrid({
    required this.cells,
    required this.weeks,
    required this.monthLabels,
    required this.total,
    required this.maxCount,
  });

  const HeatmapGrid.empty()
      : cells = const [],
        weeks = 0,
        monthLabels = const [],
        total = 0,
        maxCount = 0;

  final List<HeatmapCell> cells;
  final int weeks;
  final List<HeatmapMonthLabel> monthLabels;
  final int total;
  final int maxCount;

  bool get isEmpty => cells.isEmpty;
}

/// Day counts per mode, ready to be combined by [buildHeatmap].
class HeatmapData {
  const HeatmapData({
    required this.achievements,
    required this.mastered,
    required this.beaten,
  });

  const HeatmapData.empty()
      : achievements = const {},
        mastered = const {},
        beaten = const {};

  final Map<String, int> achievements;
  final Map<String, int> mastered;
  final Map<String, int> beaten;

  Map<String, int> forMode(HeatmapMode m) => switch (m) {
        HeatmapMode.achievements => achievements,
        HeatmapMode.mastered => mastered,
        HeatmapMode.beaten => beaten,
      };
}

/// Awards older than a year are irrelevant to the grid, so they are dropped here.
HeatmapData buildHeatmapData(
  List<EarnedAchievement> yearly,
  List<UserAward> awards, {
  DateTime? today,
}) {
  final now = today ?? DateTime.now().toUtc();
  final cutoff = DateTime.utc(now.year, now.month, now.day)
      .subtract(const Duration(days: 365));

  final mastered = <String, int>{};
  final beaten = <String, int>{};
  for (final award in awards) {
    final at = award.awardedAt;
    if (at == null) continue;
    final atUtc = at.isUtc ? at : at.toUtc();
    if (atUtc.isBefore(cutoff)) continue;
    final key = dayKeyOfDate(atUtc);
    final kind = award.kind;
    if (kind == null) continue;
    if (kind.isMastery) {
      mastered[key] = (mastered[key] ?? 0) + 1;
    } else if (kind.isBeaten) {
      beaten[key] = (beaten[key] ?? 0) + 1;
    }
  }

  return HeatmapData(
    achievements: unlocksByDay(yearly),
    mastered: mastered,
    beaten: beaten,
  );
}

/// Builds the grid for the [modes] currently toggled on. The grid always starts
/// on a Sunday so weekday rows line up, and ends on [today].
HeatmapGrid buildHeatmap(
  HeatmapData data, {
  Set<HeatmapMode> modes = const {
    HeatmapMode.achievements,
    HeatmapMode.mastered,
    HeatmapMode.beaten,
  },
  DateTime? today,
}) {
  if (modes.isEmpty) return const HeatmapGrid.empty();

  final now = today ?? DateTime.now().toUtc();
  final end = DateTime.utc(now.year, now.month, now.day);
  // DateTime.weekday is 1..7 (Mon..Sun); the grid wants 0..6 (Sun..Sat).
  final endDow = end.weekday % 7;
  final start = end.subtract(Duration(days: 364 + endDow));
  final totalDays = end.difference(start).inDays + 1;
  final weeks = (totalDays / 7).ceil();

  final merged = <String, int>{};
  for (final m in modes) {
    data.forMode(m).forEach((day, count) {
      merged[day] = (merged[day] ?? 0) + count;
    });
  }

  var maxCount = 0;
  var total = 0;
  final raw = <(String, DateTime, int, int, int)>[];
  for (var w = 0; w < weeks; w++) {
    for (var dow = 0; dow < 7; dow++) {
      final d = start.add(Duration(days: w * 7 + dow));
      if (d.isAfter(end)) continue;
      final key = dayKeyOfDate(d);
      final count = merged[key] ?? 0;
      if (count > maxCount) maxCount = count;
      total += count;
      raw.add((key, d, w, dow, count));
    }
  }

  const priority = [HeatmapMode.mastered, HeatmapMode.beaten, HeatmapMode.achievements];
  final single = modes.length == 1 ? modes.first : null;

  final cells = raw.map((r) {
    final (key, date, week, dow, count) = r;
    HeatmapMode? source;
    if (count > 0) {
      source = single;
      if (source == null) {
        for (final m in priority) {
          if (modes.contains(m) && (data.forMode(m)[key] ?? 0) > 0) {
            source = m;
            break;
          }
        }
      }
    }
    return HeatmapCell(
      dayKey: key,
      date: date,
      week: week,
      weekday: dow,
      count: count,
      level: intensityLevel(count, maxCount),
      source: source,
    );
  }).toList();

  final monthLabels = <HeatmapMonthLabel>[];
  final seenMonths = <String>{};
  for (final c in cells) {
    if (c.weekday != 0) continue;
    final key = '${c.date.year}-${c.date.month}';
    if (seenMonths.add(key)) {
      monthLabels.add(HeatmapMonthLabel(c.week, c.date.month));
    }
  }

  return HeatmapGrid(
    cells: cells,
    weeks: weeks,
    monthLabels: monthLabels,
    total: total,
    maxCount: maxCount,
  );
}

/// 0..4, relative to the busiest day — sparse profiles still get contrast.
int intensityLevel(int count, int maxCount) {
  if (count <= 0) return 0;
  if (maxCount <= 4) return count < 4 ? count : 4;
  final pct = count / maxCount;
  if (pct <= 0.25) return 1;
  if (pct <= 0.5) return 2;
  if (pct <= 0.75) return 3;
  return 4;
}
