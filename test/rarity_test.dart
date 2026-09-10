import 'package:flutter_test/flutter_test.dart';
import 'package:ra_insights/domain/insights/rarity.dart';
import 'package:ra_insights/domain/models/models.dart';

import 'helpers.dart';

void main() {
  _tiers();
  _windows();
  test('empty input yields an empty list', () {
    expect(computeRarest(const []), isEmpty);
  });

  test('sorted by the rarity multiplier, descending', () {
    final out = computeRarest([
      ach(id: 1, trueRatio: 10),
      ach(id: 2, trueRatio: 90),
      ach(id: 3, trueRatio: 50),
    ]);
    expect(out.map((a) => a.achievementId), [2, 3, 1]);
  });

  test('the multiplier outranks raw TrueRatio', () {
    // 340/25 = x13.6 against 315/5 = x63.0: the cheap achievement is the one
    // that beat its point value hardest, so it leads.
    final out = computeRarest([
      ach(id: 1, trueRatio: 340, points: 25),
      ach(id: 2, trueRatio: 315, points: 5),
    ]);
    expect(out.map((a) => a.achievementId), [2, 1]);
  });

  test('equal multipliers fall back to the costlier achievement', () {
    final out = computeRarest([
      ach(id: 1, trueRatio: 20, points: 5),
      ach(id: 2, trueRatio: 80, points: 20),
    ]);
    expect(out.map((a) => a.achievementId), [2, 1]);
  });

  test('missing or zero TrueRatio is filtered out, never NaN', () {
    final out = computeRarest([
      ach(id: 1, trueRatio: 0),
      // TrueRatio absent from the payload entirely.
      EarnedAchievement.fromJson({'AchievementID': 2, 'Points': 5, 'Date': '2026-08-29 12:00:00'}),
      ach(id: 3, trueRatio: 25),
    ]);
    expect(out.map((a) => a.achievementId), [3]);
    expect(out.single.rarityMultiplier, 5.0);
  });

  test('duplicates are collapsed keeping the highest ratio', () {
    final out = computeRarest([
      ach(id: 7, trueRatio: 30),
      ach(id: 7, trueRatio: 80),
      ach(id: 8, trueRatio: 40),
    ]);
    expect(out.length, 2);
    expect(out.first.achievementId, 7);
    expect(out.first.trueRatio, 80);
  });

  test('capped at five', () {
    final out =
        computeRarest([for (var i = 0; i < 12; i++) ach(id: i, trueRatio: i + 1)]);
    expect(out.length, 5);
    expect(out.first.trueRatio, 12);
  });

  test('zero points is never Infinity, and cannot be ranked', () {
    final zero = ach(trueRatio: 40, points: 0);
    expect(zero.rarityMultiplier, isNull);
    // No multiplier means no place in a list ordered by it.
    expect(computeRarest([zero]), isEmpty);
  });
}

void _tiers() {
  group('rarity tiers', () {
    test('unlock rate maps to the escalating tiers', () {
      expect(rarityFromUnlockRate(0.4), RarityTier.ultraRare);
      expect(rarityFromUnlockRate(4.9), RarityTier.ultraRare);
      expect(rarityFromUnlockRate(5), RarityTier.veryRare);
      expect(rarityFromUnlockRate(14.9), RarityTier.veryRare);
      expect(rarityFromUnlockRate(15), RarityTier.rare);
      expect(rarityFromUnlockRate(29.9), RarityTier.rare);
      expect(rarityFromUnlockRate(30), RarityTier.uncommon);
      expect(rarityFromUnlockRate(54.9), RarityTier.uncommon);
      expect(rarityFromUnlockRate(55), RarityTier.common);
      expect(rarityFromUnlockRate(100), RarityTier.common);
    });

    test('the TrueRatio multiplier is the fallback ladder', () {
      expect(rarityFromMultiplier(1.0), RarityTier.common);
      expect(rarityFromMultiplier(1.5), RarityTier.uncommon);
      expect(rarityFromMultiplier(3), RarityTier.rare);
      expect(rarityFromMultiplier(6), RarityTier.veryRare);
      expect(rarityFromMultiplier(40), RarityTier.ultraRare);
    });

    GameProgress game({required int players, required int awarded}) =>
        GameProgress.fromJson({
          'ID': 1,
          'Title': 'Game',
          'NumDistinctPlayersCasual': players,
          'Achievements': {
            '10': {
              'ID': 10,
              'Title': 'A',
              'Points': 5,
              'TrueRatio': 11,
              'NumAwarded': awarded,
            },
          },
        });

    test('unlock rate is awarded over distinct players', () {
      final g = game(players: 1000, awarded: 92);
      expect(g.unlockRate(g.achievements.first), closeTo(9.2, 0.001));
      expect(rarityOf(g, g.achievements.first), RarityTier.veryRare);
    });

    test('no player count falls back to the multiplier, never divides by zero',
        () {
      final g = game(players: 0, awarded: 92);
      expect(g.hasPlayerCounts, isFalse);
      expect(g.unlockRate(g.achievements.first), isNull);
      // TrueRatio 11 / 5 points = x2.2 → uncommon.
      expect(rarityOf(g, g.achievements.first), RarityTier.uncommon);
    });

    test('the newer players_total spelling is accepted', () {
      final g = GameProgress.fromJson({
        'ID': 1,
        'players_total': 200,
        'Achievements': {
          '10': {'ID': 10, 'Points': 5, 'TrueRatio': 11, 'NumAwarded': 2},
        },
      });
      expect(g.unlockRate(g.achievements.first), closeTo(1.0, 0.001));
      expect(rarityOf(g, g.achievements.first), RarityTier.ultraRare);
    });

    test('player counts survive a cache round-trip', () {
      final g = game(players: 1000, awarded: 92);
      final back = GameProgress.fromJson(g.toJson());
      expect(back.numDistinctPlayers, 1000);
      expect(back.unlockRate(back.achievements.first), closeTo(9.2, 0.001));
    });

    test('a rate above 100 is clamped instead of overflowing the tier', () {
      final g = game(players: 10, awarded: 50);
      expect(g.unlockRate(g.achievements.first), 100);
      expect(rarityOf(g, g.achievements.first), RarityTier.common);
    });
  });
}


void _windows() {
  group('rarest windows', () {
    String at(int daysAgo) {
      final d = DateTime(2026, 8, 31).subtract(Duration(days: daysAgo));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.month == 0 ? 1 : d.day.toString().padLeft(2, '0')} 12:00:00';
    }

    final now = DateTime(2026, 8, 31, 23);

    test('the window enum maps to its cutoff', () {
      expect(RarestWindow.all.days, isNull);
      expect(RarestWindow.days90.days, 90);
      expect(RarestWindow.days30.days, 30);
    });

    test('a null cutoff returns the list untouched', () {
      final items = [ach(id: 1, date: at(5)), ach(id: 2, date: at(900))];
      expect(withinDays(items, null), same(items));
    });

    test('older unlocks are dropped, recent ones kept', () {
      final items = [
        ach(id: 1, date: at(2)),
        ach(id: 2, date: at(45)),
        ach(id: 3, date: at(400)),
      ];
      expect(withinDays(items, 30, now: now).map((a) => a.achievementId), [1]);
      expect(
          withinDays(items, 90, now: now).map((a) => a.achievementId), [1, 2]);
      expect(withinDays(items, null, now: now).length, 3);
    });

    test('undated entries cannot be placed in a window and are dropped', () {
      final items = [ach(id: 1, date: ''), ach(id: 2, date: at(1))];
      expect(withinDays(items, 30, now: now).map((a) => a.achievementId), [2]);
    });

    test('the rarest list can be capped at ten', () {
      final items = [
        for (var i = 1; i <= 25; i++) ach(id: i, trueRatio: i, date: at(1)),
      ];
      final top = computeRarest(items, limit: 10);
      expect(top.length, 10);
      expect(top.first.trueRatio, 25);
      expect(top.last.trueRatio, 16);
    });
  });
}
