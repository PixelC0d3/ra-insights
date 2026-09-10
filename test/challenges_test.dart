import 'package:flutter_test/flutter_test.dart';
import 'package:ra_insights/domain/insights/challenge_match.dart';
import 'package:ra_insights/domain/insights/challenges.dart';
import 'package:ra_insights/domain/insights/rarity.dart';
import 'package:ra_insights/domain/models/models.dart';

import 'helpers.dart';

GameListEntry event({
  int id = 100,
  String title = 'Event',
  int achievements = 10,
  int points = 50,
}) =>
    GameListEntry.fromJson({
      'ID': id,
      'Title': title,
      'ImageIcon': '/Images/1.png',
      'ConsoleID': 101,
      'ConsoleName': 'Events',
      'NumAchievements': achievements,
      'Points': points,
    });

CompletionEntry completion({
  int id = 100,
  int awarded = 0,
  int max = 10,
}) =>
    CompletionEntry.fromJson({
      'GameID': id,
      'Title': 'Event',
      'ImageIcon': '/Images/1.png',
      'ConsoleID': 101,
      'ConsoleName': 'Events',
      'MaxPossible': max,
      'NumAwarded': awarded,
      'NumAwardedHardcore': awarded,
    });

GameAchievement eventAchievement({
  int id = 1,
  String title = 'Task',
  String description = 'Great Wall of China - Simatai: Collect 30 rare items',
}) =>
    GameAchievement.fromJson({
      'ID': id,
      'Title': title,
      'Description': description,
      'Points': 10,
      'TrueRatio': 100,
      'BadgeName': '1',
    });

CompletionEntry library(String title, {int id = 7}) =>
    CompletionEntry.fromJson({
      'GameID': id,
      'Title': title,
      'ImageIcon': '/Images/1.png',
      'ConsoleID': 1,
      'ConsoleName': 'NES',
      'MaxPossible': 40,
      'NumAwarded': 4,
      'NumAwardedHardcore': 4,
    });

void main() {
  _extras();
  group('buildChallenges', () {
    test('counts unlocks per event from the history', () {
      final out = buildChallenges(
        [event(id: 100, achievements: 10), event(id: 200, achievements: 5)],
        [
          ach(id: 1, gameId: 100),
          ach(id: 2, gameId: 100),
          ach(id: 9, gameId: 999),
        ],
      );
      expect(out.first.earned, 2);
      expect(out.first.started, isTrue);
      expect(out.last.earned, 0);
      expect(out.last.started, isFalse);
    });

    test('the same achievement in softcore and hardcore counts once', () {
      final out = buildChallenges(
        [event(id: 100)],
        [
          ach(id: 1, gameId: 100, hardcore: false),
          ach(id: 1, gameId: 100),
        ],
      );
      expect(out.single.earned, 1);
    });

    test('a completion entry outranks the counted rows', () {
      final out = buildChallenges(
        [event(id: 100, achievements: 10)],
        [ach(id: 1, gameId: 100)],
        completion: [completion(id: 100, awarded: 7, max: 12)],
      );
      expect(out.single.earned, 7);
      expect(out.single.totalAchievements, 12);
    });

    test('an event with no achievements does not divide by zero', () {
      final out = buildChallenges([event(achievements: 0)], const []);
      expect(out.single.progress, 0);
      expect(out.single.percent, 0);
      expect(out.single.remaining, 0);
      expect(out.single.completed, isFalse);
    });

    test('earning everything marks it completed', () {
      final out = buildChallenges(
        [event(id: 100, achievements: 2)],
        [ach(id: 1, gameId: 100), ach(id: 2, gameId: 100)],
      );
      expect(out.single.completed, isTrue);
      expect(out.single.remaining, 0);
    });
  });

  group('filters and ranking', () {
    List<Challenge> sample() => buildChallenges(
          [
            event(id: 100, title: 'Half', achievements: 10),
            event(id: 200, title: 'Untouched', achievements: 4),
            event(id: 300, title: 'Done', achievements: 2),
          ],
          [
            for (var i = 1; i <= 5; i++) ach(id: i, gameId: 100),
            ach(id: 20, gameId: 300),
            ach(id: 21, gameId: 300),
          ],
        );

    test('each filter cuts the expected bucket', () {
      final all = sample();
      expect(filterChallenges(all, ChallengeFilter.all).length, 3);
      expect(
          filterChallenges(all, ChallengeFilter.inProgress)
              .map((c) => c.title),
          ['Half']);
      expect(
          filterChallenges(all, ChallengeFilter.notStarted)
              .map((c) => c.title),
          ['Untouched']);
      expect(
          filterChallenges(all, ChallengeFilter.completed).map((c) => c.title),
          ['Done']);
    });

    test('started but unfinished ranks above untouched and finished', () {
      final ranked = rankChallenges(sample());
      expect(ranked.first.title, 'Half');
      expect(ranked.last.title, 'Done');
    });

    test('barely started still outranks untouched, however long the tail', () {
      // 1 of 42 is what a real event looks like after one unlock. A score that
      // subtracts the remaining count would bury this below the untouched one.
      final ranked = rankChallenges(buildChallenges(
        [
          event(id: 100, title: 'Barely', achievements: 42),
          event(id: 200, title: 'Untouched', achievements: 3),
        ],
        [ach(id: 1, gameId: 100)],
      ));
      expect(ranked.map((c) => c.title), ['Barely', 'Untouched']);
    });

    test('same progress puts the shorter tail first', () {
      final ranked = rankChallenges(buildChallenges(
        [
          event(id: 100, title: 'Long', achievements: 20),
          event(id: 200, title: 'Short', achievements: 4),
        ],
        [
          for (var i = 1; i <= 10; i++) ach(id: i, gameId: 100),
          ach(id: 1, gameId: 200),
          ach(id: 2, gameId: 200),
        ],
      ));
      expect(ranked.map((c) => c.title), ['Short', 'Long']);
    });

    test('limit caps the list', () {
      expect(rankChallenges(sample(), limit: 2).length, 2);
      expect(rankChallenges(sample(), limit: 99).length, 3);
    });
  });

  group('candidateGameFrom', () {
    test('reads the game out of "<Wonder> - <Game>: <task>"', () {
      expect(
        candidateGameFrom(
            'Great Wall of China - Simatai: Collect 30 rare items'),
        'Simatai',
      );
      expect(
        candidateGameFrom('Stonehenge - Tiddleywink: Defeat Rachessa'),
        'Tiddleywink',
      );
    });

    test('missing either separator yields nothing rather than a guess', () {
      expect(candidateGameFrom('Just a plain description'), isNull);
      expect(candidateGameFrom('No dash here: still nothing'), isNull);
      expect(candidateGameFrom('Wonder - : empty candidate'), isNull);
      expect(candidateGameFrom(''), isNull);
    });
  });

  group('matchTargets', () {
    test('an exact library title is a strong match', () {
      final out = matchTargets(
        [eventAchievement(description: 'Wonder - Contra: beat stage 1')],
        [library('Contra')],
      );
      expect(out.single.candidateTitle, 'Contra');
      expect(out.single.confidence, MatchConfidence.strong);
      expect(out.single.isInLibrary, isTrue);
    });

    test('a partial title is a weak match', () {
      final out = matchTargets(
        [eventAchievement(description: 'Wonder - Zelda: find the sword')],
        [library('The Legend of Zelda')],
      );
      expect(out.single.confidence, MatchConfidence.weak);
      expect(out.single.match!.title, 'The Legend of Zelda');
    });

    test('accents do not break the match', () {
      final out = matchTargets(
        [eventAchievement(description: 'Wonder - Pokemon: catch them all')],
        [library('Pokémon')],
      );
      expect(out.single.confidence, MatchConfidence.strong);
    });

    test('a named game outside the library is not a match but is reported',
        () {
      final out = matchTargets(
        [eventAchievement(description: 'Wonder - Battletoads: survive')],
        [library('Contra')],
      );
      expect(out.single.candidateTitle, 'Battletoads');
      expect(out.single.isInLibrary, isFalse);
      expect(out.single.confidence, MatchConfidence.none);
    });

    test('unparseable text yields no candidate and never throws', () {
      final out = matchTargets(
        [eventAchievement(title: 'Plain', description: 'Nothing structured')],
        [library('Contra')],
      );
      expect(out.single.candidateTitle, isNull);
      expect(out.single.confidence, MatchConfidence.none);
    });

    test('the title is used when the description has no game', () {
      final out = matchTargets(
        [
          eventAchievement(
              title: 'Wonder - Contra: clear it',
              description: 'no separators here')
        ],
        [library('Contra')],
      );
      expect(out.single.candidateTitle, 'Contra');
      expect(out.single.confidence, MatchConfidence.strong);
    });
  });
}

void _extras() {
  group('search and sort', () {
    List<Challenge> sample() => buildChallenges(
          [
            event(id: 1, title: 'RA Roulette 2025'),
            event(id: 2, title: 'Challenge League 7 Wonders'),
            event(id: 3, title: 'Achievement of the Week'),
          ],
          const [],
        );

    test('search is accent- and case-insensitive on the title', () {
      expect(searchChallenges(sample(), 'roulette').single.title,
          'RA Roulette 2025');
      expect(searchChallenges(sample(), 'LEAGUE').single.title,
          'Challenge League 7 Wonders');
      expect(searchChallenges(sample(), '').length, 3);
      expect(searchChallenges(sample(), 'zzz'), isEmpty);
    });

    test('recent puts the newest set first and undated ones last', () {
      final items = buildChallenges(
        [
          GameListEntry.fromJson({
            'ID': 1,
            'Title': 'Old',
            'NumAchievements': 5,
            'DateModified': '2024-01-01 00:00:00',
          }),
          GameListEntry.fromJson({
            'ID': 2,
            'Title': 'New',
            'NumAchievements': 5,
            'DateModified': '2026-08-01 00:00:00',
          }),
          GameListEntry.fromJson({'ID': 3, 'Title': 'Undated', 'NumAchievements': 5}),
        ],
        const [],
      );
      expect(sortChallenges(items, ChallengeSort.recent).map((c) => c.title),
          ['New', 'Old', 'Undated']);
    });

    test('biggest sorts by achievement count', () {
      final items = buildChallenges(
        [
          event(id: 1, title: 'Small', achievements: 3),
          event(id: 2, title: 'Huge', achievements: 291),
        ],
        const [],
      );
      expect(sortChallenges(items, ChallengeSort.biggest).first.title, 'Huge');
    });
  });

  group('earned rarity', () {
    test('averages the multipliers of what was unlocked there', () {
      final out = buildChallenges(
        [event(id: 100)],
        [
          ach(id: 1, gameId: 100, trueRatio: 10, points: 5),
          ach(id: 2, gameId: 100, trueRatio: 30, points: 5),
        ],
      );
      // x2.0 and x6.0 average to x4.0 → rare.
      expect(out.single.earnedRarity, closeTo(4.0, 0.001));
      expect(out.single.rarityTier, RarityTier.rare);
    });

    test('an untouched event has no rarity to show', () {
      final out = buildChallenges([event(id: 100)], const []);
      expect(out.single.earnedRarity, isNull);
      expect(out.single.rarityTier, isNull);
    });

    test('zero-point unlocks are skipped, never Infinity', () {
      final out = buildChallenges(
        [event(id: 100)],
        [ach(id: 1, gameId: 100, trueRatio: 40, points: 0)],
      );
      expect(out.single.earnedRarity, isNull);
    });
  });
}
