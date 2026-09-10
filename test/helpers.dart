import 'package:ra_insights/domain/models/models.dart';

EarnedAchievement ach({
  int id = 1,
  String date = '2026-08-29 12:00:00',
  int trueRatio = 10,
  int points = 5,
  bool hardcore = true,
  String title = 'Ach',
  String gameTitle = 'Game',
  int gameId = 7,
}) =>
    EarnedAchievement.fromJson({
      'AchievementID': id,
      'Title': title,
      'Description': '',
      'Points': points,
      'TrueRatio': trueRatio,
      'BadgeName': '12345',
      'BadgeURL': '/Badge/12345.png',
      'GameID': gameId,
      'GameTitle': gameTitle,
      'ConsoleName': 'Mega Drive',
      'Date': date,
      'HardcoreMode': hardcore ? 1 : 0,
    });

RecentGame game({
  int id = 1,
  String title = 'Game',
  int earned = 5,
  int total = 10,
}) =>
    RecentGame.fromJson({
      'GameID': id,
      'Title': title,
      'ImageIcon': '/Images/1.png',
      'ConsoleName': 'SNES',
      'NumAchieved': earned,
      'NumPossibleAchievements': total,
      'LastPlayed': '2026-08-29 10:00:00',
    });
