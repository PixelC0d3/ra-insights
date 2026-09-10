import 'package:flutter_test/flutter_test.dart';
import 'package:ra_insights/core/parsing.dart';
import 'package:ra_insights/data/insights_repository.dart';
import 'package:ra_insights/domain/models/models.dart';

import 'helpers.dart';

void main() {
  group('tolerant coercions', () {
    test('numbers arrive as strings or ints', () {
      expect(asInt('42'), 42);
      expect(asInt(42), 42);
      expect(asInt('0'), 0);
      expect(asInt(null), 0);
      expect(asInt('not a number'), 0);
      expect(asIntOrNull(''), isNull);
    });

    test('dates come space-separated, not ISO', () {
      expect(asDate('2026-08-29 21:33:12'), DateTime(2026, 8, 29, 21, 33, 12));
      expect(asDate(''), isNull);
      expect(dayKeyOf('2026-08-29 21:33:12'), '2026-08-29');
      expect(dayKeyOf('short'), isNull);
    });

    test('relative media paths get the media host prefix', () {
      expect(mediaUrl('/Badge/1.png'),
          'https://media.retroachievements.org/Badge/1.png');
      expect(mediaUrl('https://x/y.png'), 'https://x/y.png');
      expect(mediaUrl(''), '');
    });
  });

  test('a payload with every field missing still parses', () {
    final a = EarnedAchievement.fromJson(const {});
    expect(a.achievementId, 0);
    expect(a.dayKey, isNull);
    expect(a.rarityMultiplier, isNull);
  });

  test('overlapping quarterly chunks are deduped by id|date|hardcore', () {
    final out = dedupeAchievements([
      ach(id: 1, date: '2026-06-30 23:59:00'),
      ach(id: 1, date: '2026-06-30 23:59:00'), // same unlock, both chunks
      ach(id: 1, date: '2026-06-30 23:59:00', hardcore: false), // distinct mode
      ach(id: 2, date: '2026-06-30 23:59:00'),
    ]);
    expect(out.length, 3);
  });

  test('award kind priority matches the site consolidation order', () {
    expect(AwardKind.mastered.priority, greaterThan(AwardKind.completed.priority));
    expect(AwardKind.completed.priority,
        greaterThan(AwardKind.beatenHardcore.priority));
    expect(AwardKind.beatenHardcore.priority,
        greaterThan(AwardKind.beatenSoftcore.priority));
  });
}
