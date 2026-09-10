/// Domain models. Pure Dart: no Flutter, no HTTP, no database.
library;

import '../../core/parsing.dart';

class UserProfile {
  const UserProfile({
    required this.user,
    required this.userPic,
    required this.totalPoints,
    required this.totalTruePoints,
    required this.rank,
    required this.memberSince,
  });

  final String user;
  final String userPic;
  final int totalPoints;
  final int totalTruePoints;
  final int? rank;
  final DateTime? memberSince;

  String get avatarUrl => mediaUrl(userPic);

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        user: asStr(j['User']),
        userPic: asStr(j['UserPic']),
        totalPoints: asInt(j['TotalPoints']),
        totalTruePoints: asInt(j['TotalTruePoints']),
        rank: asIntOrNull(j['Rank']),
        memberSince: asDate(j['MemberSince']),
      );

  Map<String, dynamic> toJson() => {
        'User': user,
        'UserPic': userPic,
        'TotalPoints': totalPoints,
        'TotalTruePoints': totalTruePoints,
        'Rank': rank,
        'MemberSince': memberSince?.toIso8601String(),
      };
}

class UserSummary {
  const UserSummary({
    required this.user,
    required this.userPic,
    required this.totalPoints,
    required this.totalTruePoints,
    required this.rank,
    required this.totalRanked,
  });

  final String user;
  final String userPic;
  final int totalPoints;
  final int totalTruePoints;
  final int? rank;
  final int? totalRanked;

  String get avatarUrl => mediaUrl(userPic);

  factory UserSummary.fromJson(Map<String, dynamic> j) => UserSummary(
        user: asStr(j['User']),
        userPic: asStr(j['UserPic']),
        totalPoints: asInt(j['TotalPoints']),
        totalTruePoints: asInt(j['TotalTruePoints']),
        rank: asIntOrNull(j['Rank']),
        totalRanked: asIntOrNull(j['TotalRanked']),
      );

  Map<String, dynamic> toJson() => {
        'User': user,
        'UserPic': userPic,
        'TotalPoints': totalPoints,
        'TotalTruePoints': totalTruePoints,
        'Rank': rank,
        'TotalRanked': totalRanked,
      };
}

/// One entry of `API_GetUserRecentlyPlayedGames`.
class RecentGame {
  const RecentGame({
    required this.gameId,
    required this.title,
    required this.imageIcon,
    required this.consoleName,
    required this.numAchieved,
    required this.numAchievedHardcore,
    required this.numPossible,
    required this.scoreAchieved,
    required this.scoreAchievedHardcore,
    required this.possibleScore,
    required this.lastPlayed,
  });

  final int gameId;
  final String title;
  final String imageIcon;
  final String consoleName;
  final int numAchieved;
  final int numAchievedHardcore;
  final int numPossible;
  final int scoreAchieved;
  final int scoreAchievedHardcore;
  final int possibleScore;
  final DateTime? lastPlayed;

  String get iconUrl => mediaUrl(imageIcon);

  /// The site shows whichever tally is higher: some payloads report hardcore
  /// as a subset of softcore, others as a separate count.
  int get earned =>
      numAchievedHardcore > numAchieved ? numAchievedHardcore : numAchieved;

  int get pointsEarned => scoreAchievedHardcore > scoreAchieved
      ? scoreAchievedHardcore
      : scoreAchieved;

  bool get hasAchievements => numPossible > 0;
  double get progress => numPossible > 0 ? earned / numPossible : 0;
  int get percent => (progress * 100).round();

  factory RecentGame.fromJson(Map<String, dynamic> j) => RecentGame(
        gameId: asInt(j['GameID']),
        title: asStr(j['Title']),
        imageIcon: asStr(j['ImageIcon']),
        consoleName: asStr(j['ConsoleName']),
        numAchieved: asInt(j['NumAchieved']),
        numAchievedHardcore: asInt(j['NumAchievedHardcore']),
        numPossible: asInt(j['NumPossibleAchievements']),
        scoreAchieved: asInt(j['ScoreAchieved']),
        scoreAchievedHardcore: asInt(j['ScoreAchievedHardcore']),
        possibleScore: asInt(j['PossibleScore']),
        lastPlayed: asDate(j['LastPlayed']),
      );

  Map<String, dynamic> toJson() => {
        'GameID': gameId,
        'Title': title,
        'ImageIcon': imageIcon,
        'ConsoleName': consoleName,
        'NumAchieved': numAchieved,
        'NumAchievedHardcore': numAchievedHardcore,
        'NumPossibleAchievements': numPossible,
        'ScoreAchieved': scoreAchieved,
        'ScoreAchievedHardcore': scoreAchievedHardcore,
        'PossibleScore': possibleScore,
        'LastPlayed': lastPlayed?.toIso8601String(),
      };
}

/// One unlock, from `API_GetUserRecentAchievements` or
/// `API_GetAchievementsEarnedBetween` / `...EarnedOnDay` (same shape).
class EarnedAchievement {
  const EarnedAchievement({
    required this.achievementId,
    required this.title,
    required this.description,
    required this.points,
    required this.trueRatio,
    required this.badgeName,
    required this.badgeUrl,
    required this.gameId,
    required this.gameTitle,
    required this.consoleName,
    required this.date,
    required this.hardcoreMode,
  });

  final int achievementId;
  final String title;
  final String description;
  final int points;
  final int trueRatio;
  final String badgeName;
  final String badgeUrl;
  final int gameId;
  final String gameTitle;
  final String consoleName;

  /// Raw API date string, kept verbatim so day bucketing matches the site.
  final String date;
  final bool hardcoreMode;

  /// `YYYY-MM-DD`, or null when the API omitted the date.
  String? get dayKey => dayKeyOf(date);

  DateTime? get dateTime => asDate(date);

  String get badgeImageUrl {
    if (badgeUrl.isNotEmpty) return mediaUrl(badgeUrl);
    if (badgeName.isEmpty) return '';
    return mediaUrl('/Badge/$badgeName.png');
  }

  /// Rarity multiplier shown in the UI. `null` when it cannot be computed.
  double? get rarityMultiplier =>
      (trueRatio > 0 && points > 0) ? trueRatio / points : null;

  /// Dedupe key for the overlapping quarterly chunks.
  String get chunkKey => '$achievementId|$date|${hardcoreMode ? 1 : 0}';

  factory EarnedAchievement.fromJson(Map<String, dynamic> j) => EarnedAchievement(
        achievementId: asInt(j['AchievementID']),
        title: asStr(j['Title']),
        description: asStr(j['Description']),
        points: asInt(j['Points']),
        trueRatio: asInt(j['TrueRatio']),
        badgeName: asStr(j['BadgeName']),
        badgeUrl: asStr(j['BadgeURL']),
        gameId: asInt(j['GameID']),
        gameTitle: asStr(j['GameTitle']),
        consoleName: asStr(j['ConsoleName']),
        date: asStr(j['Date']),
        hardcoreMode: asBool(j['HardcoreMode']),
      );

  Map<String, dynamic> toJson() => {
        'AchievementID': achievementId,
        'Title': title,
        'Description': description,
        'Points': points,
        'TrueRatio': trueRatio,
        'BadgeName': badgeName,
        'BadgeURL': badgeUrl,
        'GameID': gameId,
        'GameTitle': gameTitle,
        'ConsoleName': consoleName,
        'Date': date,
        'HardcoreMode': hardcoreMode ? 1 : 0,
      };
}

/// Award kinds, in the consolidation priority the site uses.
enum AwardKind {
  beatenSoftcore(1, 'Beaten (casual)'),
  beatenHardcore(2, 'Beaten'),
  completed(3, 'Completed (casual)'),
  mastered(4, 'Mastered');

  const AwardKind(this.priority, this.label);
  final int priority;
  final String label;

  bool get isMastery => this == mastered || this == completed;
  bool get isBeaten => this == beatenHardcore || this == beatenSoftcore;

  /// The API spelling. Cached payloads are written with this, never with
  /// [name] — a round-trip through `name` would not parse back.
  String get wire => switch (this) {
        AwardKind.mastered => 'mastered',
        AwardKind.completed => 'completed',
        AwardKind.beatenHardcore => 'beaten-hardcore',
        AwardKind.beatenSoftcore => 'beaten-softcore',
      };

  /// `"softcore"` was renamed to `"casual"` on the site in Aug/2026, and older
  /// caches may hold the Dart enum name; separators are ignored so every
  /// spelling parses.
  static AwardKind? parse(String raw) {
    final v = raw.trim().toLowerCase().replaceAll(RegExp(r'[-_\s]'), '');
    switch (v) {
      case 'mastered':
        return AwardKind.mastered;
      case 'completed':
        return AwardKind.completed;
      case 'beatenhardcore':
        return AwardKind.beatenHardcore;
      case 'beatensoftcore':
      case 'beatencasual':
        return AwardKind.beatenSoftcore;
    }
    return null;
  }
}

/// One entry of `API_GetUserAwards().VisibleUserAwards`.
class UserAward {
  const UserAward({
    required this.awardedAt,
    required this.awardType,
    required this.awardData,
    required this.awardDataExtra,
    required this.title,
    required this.imageIcon,
    required this.consoleName,
  });

  final DateTime? awardedAt;
  final String awardType;
  final String awardData;
  final int awardDataExtra;
  final String title;
  final String imageIcon;
  final String consoleName;

  int? get gameId => asIntOrNull(awardData);

  String get iconUrl => mediaUrl(imageIcon);

  /// `Mastery/Completion` + extra 1 => mastered, extra 0 => completed.
  /// `Game Beaten` + extra 1 => hardcore, extra 0 => casual (ex-softcore).
  AwardKind? get kind {
    final t = awardType.trim().toLowerCase();
    if (t == 'mastery/completion' || t == 'mastery') {
      return awardDataExtra == 1 ? AwardKind.mastered : AwardKind.completed;
    }
    if (t == 'game beaten') {
      return awardDataExtra == 1 ? AwardKind.beatenHardcore : AwardKind.beatenSoftcore;
    }
    return null;
  }

  factory UserAward.fromJson(Map<String, dynamic> j) => UserAward(
        awardedAt: asDate(j['AwardedAt']),
        awardType: asStr(j['AwardType']),
        awardData: asStr(j['AwardData']),
        awardDataExtra: asInt(j['AwardDataExtra']),
        title: asStr(j['Title']),
        imageIcon: asStr(j['ImageIcon']),
        consoleName: asStr(j['ConsoleName']),
      );

  Map<String, dynamic> toJson() => {
        'AwardedAt': awardedAt?.toIso8601String(),
        'AwardType': awardType,
        'AwardData': awardData,
        'AwardDataExtra': awardDataExtra,
        'Title': title,
        'ImageIcon': imageIcon,
        'ConsoleName': consoleName,
      };
}

/// One entry of `API_GetUserCompletionProgress().Results`.
class CompletionEntry {
  const CompletionEntry({
    required this.gameId,
    required this.title,
    required this.imageIcon,
    required this.consoleId,
    required this.consoleName,
    required this.maxPossible,
    required this.numAwarded,
    required this.numAwardedHardcore,
    required this.highestAwardKind,
    required this.highestAwardDate,
    required this.mostRecentAwardedDate,
  });

  final int gameId;
  final String title;
  final String imageIcon;
  final int consoleId;
  final String consoleName;
  final int maxPossible;
  final int numAwarded;
  final int numAwardedHardcore;
  final AwardKind? highestAwardKind;
  final DateTime? highestAwardDate;
  final DateTime? mostRecentAwardedDate;

  String get iconUrl => mediaUrl(imageIcon);

  /// Hardcore counts first — that is what the site's progression table shows.
  int get earned => numAwardedHardcore > numAwarded ? numAwardedHardcore : numAwarded;

  double get progress => maxPossible > 0 ? earned / maxPossible : 0;

  factory CompletionEntry.fromJson(Map<String, dynamic> j) => CompletionEntry(
        gameId: asInt(j['GameID']),
        title: asStr(j['Title']),
        imageIcon: asStr(j['ImageIcon']),
        consoleId: asInt(j['ConsoleID']),
        consoleName: asStr(j['ConsoleName']),
        maxPossible: asInt(j['MaxPossible']),
        numAwarded: asInt(j['NumAwarded']),
        numAwardedHardcore: asInt(j['NumAwardedHardcore']),
        highestAwardKind: AwardKind.parse(asStr(j['HighestAwardKind'])),
        highestAwardDate: asDate(j['HighestAwardDate']),
        mostRecentAwardedDate: asDate(j['MostRecentAwardedDate']),
      );

  Map<String, dynamic> toJson() => {
        'GameID': gameId,
        'Title': title,
        'ImageIcon': imageIcon,
        'ConsoleID': consoleId,
        'ConsoleName': consoleName,
        'MaxPossible': maxPossible,
        'NumAwarded': numAwarded,
        'NumAwardedHardcore': numAwardedHardcore,
        'HighestAwardKind': highestAwardKind?.wire,
        'HighestAwardDate': highestAwardDate?.toIso8601String(),
        'MostRecentAwardedDate': mostRecentAwardedDate?.toIso8601String(),
      };
}

/// One achievement of a game, from `API_GetGameInfoAndUserProgress`.
/// Unlike [EarnedAchievement] this also covers achievements the user has *not*
/// unlocked yet — that is the whole point of the game screen.
class GameAchievement {
  const GameAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.trueRatio,
    required this.badgeName,
    required this.type,
    required this.numAwarded,
    required this.numAwardedHardcore,
    required this.dateEarned,
    required this.dateEarnedHardcore,
    required this.displayOrder,
  });

  final int id;
  final String title;
  final String description;
  final int points;
  final int trueRatio;
  final String badgeName;

  /// `progression`, `win_condition`, `missable` — empty for regular ones.
  final String type;
  final int numAwarded;
  final int numAwardedHardcore;
  final DateTime? dateEarned;
  final DateTime? dateEarnedHardcore;
  final int displayOrder;

  bool get isEarned => dateEarned != null || dateEarnedHardcore != null;
  bool get isHardcore => dateEarnedHardcore != null;
  DateTime? get earnedAt => dateEarnedHardcore ?? dateEarned;

  String get badgeUrl =>
      badgeName.isEmpty ? '' : mediaUrl('/Badge/$badgeName.png');

  /// Locked badges are served with the `_lock` suffix.
  String get lockedBadgeUrl =>
      badgeName.isEmpty ? '' : mediaUrl('/Badge/${badgeName}_lock.png');

  double? get rarityMultiplier =>
      (trueRatio > 0 && points > 0) ? trueRatio / points : null;

  factory GameAchievement.fromJson(Map<String, dynamic> j) => GameAchievement(
        id: asInt(j['ID'] ?? j['id']),
        title: asStr(j['Title']),
        description: asStr(j['Description']),
        points: asInt(j['Points']),
        trueRatio: asInt(j['TrueRatio']),
        badgeName: asStr(j['BadgeName']),
        type: asStr(j['Type']),
        numAwarded: asInt(j['NumAwarded']),
        numAwardedHardcore: asInt(j['NumAwardedHardcore']),
        dateEarned: asDate(j['DateEarned']),
        dateEarnedHardcore: asDate(j['DateEarnedHardcore']),
        displayOrder: asInt(j['DisplayOrder']),
      );

  Map<String, dynamic> toJson() => {
        'ID': id,
        'Title': title,
        'Description': description,
        'Points': points,
        'TrueRatio': trueRatio,
        'BadgeName': badgeName,
        'Type': type,
        'NumAwarded': numAwarded,
        'NumAwardedHardcore': numAwardedHardcore,
        'DateEarned': dateEarned?.toIso8601String(),
        'DateEarnedHardcore': dateEarnedHardcore?.toIso8601String(),
        'DisplayOrder': displayOrder,
      };
}

/// A game plus the user's progress in it.
class GameProgress {
  const GameProgress({
    required this.gameId,
    required this.title,
    required this.consoleName,
    required this.imageIcon,
    required this.imageBoxArt,
    required this.genre,
    required this.developer,
    required this.publisher,
    required this.released,
    required this.numAchievements,
    required this.numAwardedToUser,
    required this.numAwardedToUserHardcore,
    required this.numDistinctPlayers,
    required this.numDistinctPlayersHardcore,
    required this.highestAwardKind,
    required this.achievements,
  });

  final int gameId;
  final String title;
  final String consoleName;
  final String imageIcon;
  final String imageBoxArt;
  final String genre;
  final String developer;
  final String publisher;
  final String released;
  final int numAchievements;
  final int numAwardedToUser;
  final int numAwardedToUserHardcore;

  /// How many people have played the set at all. The denominator of every
  /// unlock rate — without it rarity can only be approximated from TrueRatio.
  final int numDistinctPlayers;
  final int numDistinctPlayersHardcore;
  final AwardKind? highestAwardKind;
  final List<GameAchievement> achievements;

  bool get hasPlayerCounts => numDistinctPlayers > 0;

  /// Percentage of the game's players that unlocked [a] — the same number the
  /// site prints under each badge. `null` when the payload carried no counts.
  double? unlockRate(GameAchievement a) {
    if (numDistinctPlayers <= 0) return null;
    return (a.numAwarded / numDistinctPlayers * 100).clamp(0, 100).toDouble();
  }

  String get iconUrl => mediaUrl(imageIcon);
  String get boxArtUrl => mediaUrl(imageBoxArt);

  int get earned =>
      numAwardedToUserHardcore > numAwardedToUser
          ? numAwardedToUserHardcore
          : numAwardedToUser;

  int get remaining => numAchievements - earned;
  double get progress => numAchievements > 0 ? earned / numAchievements : 0;
  int get percent => (progress * 100).round();

  int get pointsEarned => achievements
      .where((a) => a.isEarned)
      .fold(0, (sum, a) => sum + a.points);

  int get pointsTotal => achievements.fold(0, (sum, a) => sum + a.points);

  /// Average TrueRatio of what is still locked — how hard the tail really is.
  double get remainingDifficulty {
    final locked = achievements.where((a) => !a.isEarned).toList();
    if (locked.isEmpty) return 0;
    return locked.fold(0, (sum, a) => sum + a.trueRatio) / locked.length;
  }

  factory GameProgress.fromJson(Map<String, dynamic> j) {
    // `Achievements` is a map keyed by achievement id, not an array.
    final raw = j['Achievements'];
    final list = <GameAchievement>[];
    if (raw is Map) {
      for (final v in raw.values) {
        if (v is Map) {
          list.add(GameAchievement.fromJson(Map<String, dynamic>.from(v)));
        }
      }
    } else if (raw is List) {
      for (final v in raw) {
        if (v is Map) {
          list.add(GameAchievement.fromJson(Map<String, dynamic>.from(v)));
        }
      }
    }
    list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return GameProgress(
      gameId: asInt(j['ID'] ?? j['id']),
      title: asStr(j['Title']),
      consoleName: asStr(j['ConsoleName']),
      imageIcon: asStr(j['ImageIcon']),
      imageBoxArt: asStr(j['ImageBoxArt']),
      genre: asStr(j['Genre']),
      developer: asStr(j['Developer']),
      publisher: asStr(j['Publisher']),
      released: asStr(j['Released']),
      numAchievements: asInt(j['NumAchievements'], list.length),
      numAwardedToUser: asInt(j['NumAwardedToUser']),
      numAwardedToUserHardcore: asInt(j['NumAwardedToUserHardcore']),
      // The API renamed these; older payloads and caches still use the
      // NumDistinctPlayers* spelling.
      numDistinctPlayers:
          asInt(j['NumDistinctPlayersCasual'] ?? j['players_total']),
      numDistinctPlayersHardcore:
          asInt(j['NumDistinctPlayersHardcore'] ?? j['players_hardcore']),
      highestAwardKind: AwardKind.parse(asStr(j['HighestAwardKind'])),
      achievements: list,
    );
  }

  Map<String, dynamic> toJson() => {
        'ID': gameId,
        'Title': title,
        'ConsoleName': consoleName,
        'ImageIcon': imageIcon,
        'ImageBoxArt': imageBoxArt,
        'Genre': genre,
        'Developer': developer,
        'Publisher': publisher,
        'Released': released,
        'NumAchievements': numAchievements,
        'NumAwardedToUser': numAwardedToUser,
        'NumAwardedToUserHardcore': numAwardedToUserHardcore,
        'NumDistinctPlayersCasual': numDistinctPlayers,
        'NumDistinctPlayersHardcore': numDistinctPlayersHardcore,
        'HighestAwardKind': highestAwardKind?.wire,
        'Achievements': {
          for (final a in achievements) a.id.toString(): a.toJson(),
        },
      };
}

/// A comment on a user's wall (`API_GetComments`, read-only).
class UserComment {
  const UserComment({
    required this.user,
    required this.commentText,
    required this.submitted,
  });

  final String user;
  final String commentText;
  final DateTime? submitted;

  factory UserComment.fromJson(Map<String, dynamic> j) => UserComment(
        user: asStr(j['User'] ?? j['UserName']),
        commentText: asStr(j['CommentText'] ?? j['Comment']),
        submitted: asDate(j['Submitted'] ?? j['SubmittedAt']),
      );
}

/// One system from `API_GetConsoleIDs`. Includes non-gaming systems like Hubs
/// and Events when the endpoint is called without the `g` filter.
class ConsoleInfo {
  const ConsoleInfo({required this.id, required this.name});

  final int id;
  final String name;

  factory ConsoleInfo.fromJson(Map<String, dynamic> j) => ConsoleInfo(
        id: asInt(j['ID'] ?? j['id']),
        name: asStr(j['Name'] ?? j['name']),
      );

  Map<String, dynamic> toJson() => {'ID': id, 'Name': name};
}

/// One entry from `API_GetGameList`. Events are listed here like any other
/// game, which is how the challenges catalogue is built.
class GameListEntry {
  const GameListEntry({
    required this.gameId,
    required this.title,
    required this.imageIcon,
    required this.consoleId,
    required this.consoleName,
    required this.numAchievements,
    required this.points,
    required this.dateModified,
  });

  final int gameId;
  final String title;
  final String imageIcon;
  final int consoleId;
  final String consoleName;
  final int numAchievements;
  final int points;

  /// When the set last changed — the only "how new is this" signal the list
  /// endpoint gives.
  final DateTime? dateModified;

  String get iconUrl => mediaUrl(imageIcon);

  factory GameListEntry.fromJson(Map<String, dynamic> j) => GameListEntry(
        gameId: asInt(j['ID'] ?? j['id']),
        title: asStr(j['Title'] ?? j['title']),
        imageIcon: asStr(j['ImageIcon'] ?? j['imageIcon']),
        consoleId: asInt(j['ConsoleID'] ?? j['consoleId']),
        consoleName: asStr(j['ConsoleName'] ?? j['consoleName']),
        numAchievements: asInt(j['NumAchievements'] ?? j['numAchievements']),
        points: asInt(j['Points'] ?? j['points']),
        dateModified: asDate(j['DateModified'] ?? j['dateModified']),
      );

  Map<String, dynamic> toJson() => {
        'ID': gameId,
        'Title': title,
        'ImageIcon': imageIcon,
        'ConsoleID': consoleId,
        'ConsoleName': consoleName,
        'NumAchievements': numAchievements,
        'Points': points,
        'DateModified': dateModified?.toIso8601String(),
      };
}
