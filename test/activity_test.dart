import 'package:flutter_test/flutter_test.dart';
import 'package:ra_insights/domain/insights/activity.dart';
import 'package:ra_insights/domain/insights/heatmap.dart';
import 'package:ra_insights/domain/models/models.dart';

void main() {
  final today = DateTime.utc(2026, 8, 29);

  EarnedAchievement unlock({
    int id = 1,
    int gameId = 10,
    String game = 'Sonic',
    String date = '2026-08-20 12:00:00',
    int points = 5,
    int trueRatio = 12,
  }) =>
      EarnedAchievement.fromJson({
        'AchievementID': id,
        'GameID': gameId,
        'GameTitle': game,
        'ConsoleName': 'Mega Drive',
        'Date': date,
        'Points': points,
        'TrueRatio': trueRatio,
      });

  UserAward award({
    String type = 'Mastery/Completion',
    int extra = 1,
    int gameId = 20,
    String date = '2026-08-25',
    String title = 'Alwa',
  }) =>
      UserAward.fromJson({
        'AwardedAt': '${date}T18:00:00+00:00',
        'AwardType': type,
        'AwardData': '$gameId',
        'AwardDataExtra': extra,
        'Title': title,
        'ImageIcon': '/Images/9.png',
        'ConsoleName': 'Homebrew',
      });

  group('index', () {
    test('unlocks and awards become events tagged with mode and day', () {
      final events = buildActivityEvents(
        [unlock()],
        [award(), award(type: 'Game Beaten', gameId: 30, date: '2026-08-26')],
        today: today,
      );

      expect(events.length, 3);
      expect(events.where((e) => e.mode == HeatmapMode.achievements).length, 1);
      expect(events.where((e) => e.mode == HeatmapMode.mastered).single.dayKey,
          '2026-08-25');
      expect(events.where((e) => e.mode == HeatmapMode.beaten).single.gameId, 30);
    });

    test('awards older than a year and unusable rows are dropped', () {
      final events = buildActivityEvents(
        [unlock(gameId: 0), unlock(id: 2, date: '')],
        [
          award(date: '2024-01-01'),
          UserAward.fromJson(const {'AwardType': 'Mastery/Completion'}),
        ],
        today: today,
      );
      expect(events, isEmpty);
    });

    test('game icons come from the completion payload, awards fall back to their own', () {
      final events = buildActivityEvents(
        [unlock(gameId: 10)],
        [award(gameId: 20)],
        icons: {10: 'https://media.retroachievements.org/Images/1.png'},
        today: today,
      );
      expect(events.firstWhere((e) => e.gameId == 10).iconUrl,
          endsWith('/Images/1.png'));
      expect(events.firstWhere((e) => e.gameId == 20).iconUrl,
          endsWith('/Images/9.png'));
    });
  });

  group('filters', () {
    final events = buildActivityEvents(
      [
        unlock(id: 1, gameId: 10, date: '2026-08-20 10:00:00'),
        unlock(id: 2, gameId: 10, date: '2026-08-20 11:00:00'),
        unlock(id: 3, gameId: 11, game: 'Zelda', date: '2026-08-21 10:00:00'),
      ],
      [award(gameId: 20, date: '2026-08-20')],
      today: today,
    );

    test('mode filter keeps only the selected kinds', () {
      final onlyAwards =
          filterActivity(events, modes: const {HeatmapMode.mastered});
      expect(onlyAwards.length, 1);
      expect(onlyAwards.single.gameId, 20);
    });

    test('day filter narrows to a single date', () {
      final day = filterActivity(events, dayKey: '2026-08-21');
      expect(day.length, 1);
      expect(day.single.gameId, 11);
    });

    test('mode and day compose', () {
      final out = filterActivity(
        events,
        modes: const {HeatmapMode.achievements},
        dayKey: '2026-08-20',
      );
      expect(out.length, 2);
      expect(out.every((e) => e.gameId == 10), isTrue);
    });

    test('the grid data derived from the index matches the chip totals', () {
      final data = heatmapDataFrom(events);
      expect(data.achievements['2026-08-20'], 2);
      expect(data.achievements['2026-08-21'], 1);
      expect(data.mastered['2026-08-20'], 1);
      expect(data.beaten, isEmpty);
    });
  });

  group('lists', () {
    test('games are grouped, scored and flagged by award', () {
      final events = buildActivityEvents(
        [
          unlock(id: 1, gameId: 10, points: 5, trueRatio: 12),
          unlock(id: 2, gameId: 10, points: 10, trueRatio: 40),
        ],
        [award(gameId: 10, date: '2026-08-26', title: 'Sonic')],
        today: today,
      );

      final games = gamesFromActivity(events);
      expect(games.length, 1);
      expect(games.single.unlocks, 2);
      expect(games.single.points, 15);
      expect(games.single.rarest, 40);
      expect(games.single.mastered, isTrue);
      expect(games.single.beaten, isFalse);
    });

    test('a game only present through an award still shows up, with zero unlocks', () {
      final games = gamesFromActivity(
          buildActivityEvents(const [], [award(gameId: 77)], today: today));
      expect(games.single.gameId, 77);
      expect(games.single.unlocks, 0);
      expect(games.single.title, 'Alwa');
    });

    test('most recent activity first', () {
      final games = gamesFromActivity(buildActivityEvents(
        [
          unlock(gameId: 10, game: 'Old', date: '2026-01-02 10:00:00'),
          unlock(gameId: 20, game: 'New', date: '2026-08-28 10:00:00'),
        ],
        const [],
        today: today,
      ));
      expect(games.first.title, 'New');
    });

    test('the achievement list carries only unlocks, newest first', () {
      final events = buildActivityEvents(
        [
          unlock(id: 1, date: '2026-08-20 10:00:00'),
          unlock(id: 2, date: '2026-08-28 10:00:00'),
        ],
        [award()],
        today: today,
      );
      final list = achievementsFromActivity(events);
      expect(list.map((a) => a.achievementId), [2, 1]);
    });

    test('an awards-only filter yields no achievements', () {
      final events = buildActivityEvents([unlock()], [award()], today: today);
      final onlyMastered =
          filterActivity(events, modes: const {HeatmapMode.mastered});
      expect(achievementsFromActivity(onlyMastered), isEmpty);
      expect(gamesFromActivity(onlyMastered).length, 1);
    });

    test('empty index yields empty lists', () {
      expect(gamesFromActivity(const []), isEmpty);
      expect(achievementsFromActivity(const []), isEmpty);
    });
  });
}
