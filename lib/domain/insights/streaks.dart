/// Unlock streaks — port of `insights/streaks.js`.
library;

import '../models/models.dart';

class StreakStats {
  const StreakStats({
    required this.current,
    required this.best,
    required this.activeDays,
    required this.totalAchievements,
    required this.unlockedToday,
  });

  const StreakStats.empty()
      : current = 0,
        best = 0,
        activeDays = 0,
        totalAchievements = 0,
        unlockedToday = false;

  final int current;
  final int best;
  final int activeDays;
  final int totalAchievements;

  /// Whether today already has an unlock. Drives the "streak at risk" nudge.
  final bool unlockedToday;

  bool get isEmpty => activeDays == 0;
  bool get atRisk => current >= 3 && !unlockedToday;
}

/// Counts unlocks per `YYYY-MM-DD`.
Map<String, int> unlocksByDay(List<EarnedAchievement> achievements) {
  final map = <String, int>{};
  for (final a in achievements) {
    final day = a.dayKey;
    if (day == null) continue;
    map[day] = (map[day] ?? 0) + 1;
  }
  return map;
}

/// [today] defaults to the current UTC day, matching the API's server time.
StreakStats computeStreaks(
  List<EarnedAchievement> achievements, {
  DateTime? today,
}) {
  if (achievements.isEmpty) return const StreakStats.empty();

  final dayMap = unlocksByDay(achievements);
  if (dayMap.isEmpty) {
    return StreakStats(
      current: 0,
      best: 0,
      activeDays: 0,
      totalAchievements: achievements.length,
      unlockedToday: false,
    );
  }

  final now = (today ?? DateTime.now().toUtc());
  var cursor = DateTime.utc(now.year, now.month, now.day);
  final todayKey = _key(cursor);
  final unlockedToday = dayMap.containsKey(todayKey);

  // No unlock today does not break the streak yet — the day is not over.
  if (!unlockedToday) cursor = cursor.subtract(const Duration(days: 1));

  var current = 0;
  while (dayMap.containsKey(_key(cursor))) {
    current++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  final sortedDays = dayMap.keys.toList()..sort();
  var best = 1;
  var run = 1;
  for (var i = 1; i < sortedDays.length; i++) {
    final prev = DateTime.parse('${sortedDays[i - 1]}T00:00:00Z');
    final curr = DateTime.parse('${sortedDays[i]}T00:00:00Z');
    if (curr.difference(prev).inDays == 1) {
      run++;
      if (run > best) best = run;
    } else {
      run = 1;
    }
  }
  if (current > best) best = current;

  return StreakStats(
    current: current,
    best: best,
    activeDays: dayMap.length,
    totalAchievements: achievements.length,
    unlockedToday: unlockedToday,
  );
}

String _key(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
