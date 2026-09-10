import 'package:flutter_test/flutter_test.dart';
import 'package:ra_insights/domain/models/models.dart';

void main() {
  Map<String, dynamic> payload({Object? achievements}) => {
        'ID': 42,
        'Title': 'Alwa\'s Awakening',
        'ConsoleName': 'Homebrew',
        'ImageIcon': '/Images/1.png',
        'NumAchievements': 3,
        'NumAwardedToUser': 2,
        'NumAwardedToUserHardcore': 2,
        'HighestAwardKind': 'beaten-hardcore',
        'Achievements': achievements ??
            {
              '10': {
                'ID': 10,
                'Title': 'First',
                'Points': 5,
                'TrueRatio': 10,
                'BadgeName': '111',
                'DisplayOrder': 1,
                'DateEarnedHardcore': '2026-05-11 10:00:00',
              },
              '11': {
                'ID': 11,
                'Title': 'Second',
                'Points': 10,
                'TrueRatio': 40,
                'BadgeName': '112',
                'DisplayOrder': 0,
                'DateEarned': '2026-05-11 11:00:00',
              },
              '12': {
                'ID': 12,
                'Title': 'Locked',
                'Points': 25,
                'TrueRatio': 100,
                'BadgeName': '113',
                'DisplayOrder': 2,
                'Type': 'missable',
              },
            },
      };

  test('achievements arrive as a map keyed by id and come out ordered', () {
    final game = GameProgress.fromJson(payload());
    expect(game.achievements.map((a) => a.id), [11, 10, 12]);
  });

  test('earned state distinguishes hardcore from casual', () {
    final game = GameProgress.fromJson(payload());
    final hardcore = game.achievements.firstWhere((a) => a.id == 10);
    final casual = game.achievements.firstWhere((a) => a.id == 11);
    final locked = game.achievements.firstWhere((a) => a.id == 12);

    expect(hardcore.isEarned, isTrue);
    expect(hardcore.isHardcore, isTrue);
    expect(casual.isEarned, isTrue);
    expect(casual.isHardcore, isFalse);
    expect(locked.isEarned, isFalse);
    expect(locked.earnedAt, isNull);
  });

  test('progress, points and remaining difficulty are derived', () {
    final game = GameProgress.fromJson(payload());
    expect(game.earned, 2);
    expect(game.remaining, 1);
    expect(game.percent, 67);
    expect(game.pointsEarned, 15);
    expect(game.pointsTotal, 40);
    expect(game.remainingDifficulty, 100);
  });

  test('a game with no achievements does not divide by zero', () {
    final game = GameProgress.fromJson({
      'ID': 1,
      'Title': 'Empty',
      'NumAchievements': 0,
      'Achievements': const <String, dynamic>{},
    });
    expect(game.progress, 0);
    expect(game.percent, 0);
    expect(game.remainingDifficulty, 0);
  });

  test('an Achievements array is accepted as well as a map', () {
    final game = GameProgress.fromJson(payload(achievements: [
      {'ID': 1, 'Title': 'A', 'Points': 5, 'DisplayOrder': 0},
    ]));
    expect(game.achievements.single.id, 1);
  });

  test('locked badges use the _lock suffix', () {
    final game = GameProgress.fromJson(payload());
    final locked = game.achievements.firstWhere((a) => a.id == 12);
    expect(locked.lockedBadgeUrl, endsWith('/Badge/113_lock.png'));
    expect(locked.badgeUrl, endsWith('/Badge/113.png'));
  });
}
