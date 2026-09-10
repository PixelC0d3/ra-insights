import 'package:flutter_test/flutter_test.dart';
import 'package:ra_insights/domain/insights/streaks.dart';

import 'helpers.dart';

void main() {
  final today = DateTime.utc(2026, 8, 29);
  String day(int ago) {
    final d = today.subtract(Duration(days: ago));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} 12:00:00';
  }

  test('empty input yields an empty state, not a crash', () {
    final s = computeStreaks(const [], today: today);
    expect(s.current, 0);
    expect(s.best, 0);
    expect(s.isEmpty, isTrue);
  });

  test('nothing unlocked today but something yesterday keeps the streak alive', () {
    final s = computeStreaks(
      [ach(date: day(1)), ach(id: 2, date: day(2)), ach(id: 3, date: day(3))],
      today: today,
    );
    expect(s.current, 3);
    expect(s.unlockedToday, isFalse);
    expect(s.atRisk, isTrue);
  });

  test('unlock today counts and clears the at-risk flag', () {
    final s = computeStreaks(
      [ach(date: day(0)), ach(id: 2, date: day(1)), ach(id: 3, date: day(2))],
      today: today,
    );
    expect(s.current, 3);
    expect(s.unlockedToday, isTrue);
    expect(s.atRisk, isFalse);
  });

  test('a gap in the middle still yields the correct best streak', () {
    final s = computeStreaks(
      [
        ach(date: day(0)),
        ach(id: 2, date: day(5)),
        ach(id: 3, date: day(6)),
        ach(id: 4, date: day(7)),
        ach(id: 5, date: day(8)),
      ],
      today: today,
    );
    expect(s.current, 1);
    expect(s.best, 4);
    expect(s.activeDays, 5);
  });

  test('current streak longer than any historical run becomes the best', () {
    final s = computeStreaks(
      [for (var i = 0; i < 6; i++) ach(id: i, date: day(i))],
      today: today,
    );
    expect(s.current, 6);
    expect(s.best, 6);
  });

  test('multiple unlocks on the same day count as one active day', () {
    final s = computeStreaks(
      [ach(id: 1, date: day(1)), ach(id: 2, date: day(1)), ach(id: 3, date: day(1))],
      today: today,
    );
    expect(s.activeDays, 1);
    expect(s.current, 1);
    expect(s.totalAchievements, 3);
  });

  test('entries without a date are ignored', () {
    final s = computeStreaks([ach(date: ''), ach(id: 2, date: day(1))], today: today);
    expect(s.activeDays, 1);
    expect(s.current, 1);
  });

  test('streak broken more than a day ago is zero', () {
    final s = computeStreaks([ach(date: day(4)), ach(id: 2, date: day(5))], today: today);
    expect(s.current, 0);
    expect(s.best, 2);
  });
}
