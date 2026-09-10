import 'package:flutter_test/flutter_test.dart';
import 'package:ra_insights/domain/models/models.dart';

void main() {
  Map<String, dynamic> payload() => {
        'GameID': '3',
        'Title': 'Contra',
        'ImageIcon': '/Images/001.png',
        'ConsoleName': 'NES',
        'NumAchieved': '4',
        'NumAchievedHardcore': '4',
        'NumPossibleAchievements': '40',
        'ScoreAchieved': '16',
        'ScoreAchievedHardcore': '16',
        'PossibleScore': '533',
        'LastPlayed': '2026-08-30 21:10:00',
      };

  test('parses the counters the site shows', () {
    final g = RecentGame.fromJson(payload());
    expect(g.earned, 4);
    expect(g.numPossible, 40);
    expect(g.pointsEarned, 16);
    expect(g.possibleScore, 533);
    expect(g.percent, 10);
    expect(g.hasAchievements, isTrue);
  });

  test('takes the higher of softcore and hardcore tallies', () {
    final g = RecentGame.fromJson({
      ...payload(),
      'NumAchieved': '0',
      'NumAchievedHardcore': '7',
      'ScoreAchieved': '0',
      'ScoreAchievedHardcore': '90',
    });
    expect(g.earned, 7);
    expect(g.pointsEarned, 90);
  });

  test('a game without achievements has no progress', () {
    final g = RecentGame.fromJson({
      ...payload(),
      'NumPossibleAchievements': '0',
      'PossibleScore': '0',
      'NumAchieved': '0',
      'NumAchievedHardcore': '0',
    });
    expect(g.hasAchievements, isFalse);
    expect(g.progress, 0);
    expect(g.percent, 0);
  });

  test('survives a cache round-trip', () {
    final g = RecentGame.fromJson(payload());
    final back = RecentGame.fromJson(g.toJson());
    expect(back.earned, g.earned);
    expect(back.pointsEarned, g.pointsEarned);
    expect(back.possibleScore, g.possibleScore);
    expect(back.lastPlayed, g.lastPlayed);
  });
}
