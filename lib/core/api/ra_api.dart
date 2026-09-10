/// Typed wrappers over the endpoints listed in §5 of the plan.
library;

import '../result.dart';
import '../../domain/models/models.dart';
import 'ra_client.dart';

class RaApi {
  RaApi(this.client);
  final RaClient client;

  Future<Result<UserProfile>> getUserProfile({RaCredentials? credentials}) async {
    final res = await client.get('API_GetUserProfile',
        overrideCredentials: credentials);
    return _mapObject(res, UserProfile.fromJson);
  }

  Future<Result<UserSummary>> getUserSummary() async {
    final res = await client.get('API_GetUserSummary', params: {'g': 0, 'a': 0});
    return _mapObject(res, UserSummary.fromJson);
  }

  Future<Result<List<RecentGame>>> getRecentlyPlayedGames(
      {int count = 50, int offset = 0}) async {
    final res = await client.get('API_GetUserRecentlyPlayedGames',
        params: {'c': count, 'o': offset});
    return _mapList(res, RecentGame.fromJson);
  }

  /// [minutes] defaults to 30 days, like the userscript.
  Future<Result<List<EarnedAchievement>>> getRecentAchievements(
      {int minutes = 43200}) async {
    final res =
        await client.get('API_GetUserRecentAchievements', params: {'m': minutes});
    return _mapList(res, EarnedAchievement.fromJson);
  }

  Future<Result<List<EarnedAchievement>>> getAchievementsEarnedBetween(
      DateTime from, DateTime to) async {
    final res = await client.get('API_GetAchievementsEarnedBetween', params: {
      'f': from.millisecondsSinceEpoch ~/ 1000,
      't': to.millisecondsSinceEpoch ~/ 1000,
    });
    return _mapList(res, EarnedAchievement.fromJson);
  }

  Future<Result<List<EarnedAchievement>>> getAchievementsEarnedOnDay(
      String dayKey) async {
    final res = await client
        .get('API_GetAchievementsEarnedOnDay', params: {'d': dayKey});
    return _mapList(res, EarnedAchievement.fromJson);
  }

  Future<Result<List<UserAward>>> getUserAwards() async {
    final res = await client.get('API_GetUserAwards');
    return res.fold(
      (data) {
        if (data is Map && data['VisibleUserAwards'] is List) {
          final list = (data['VisibleUserAwards'] as List)
              .whereType<Map<String, dynamic>>()
              .map(UserAward.fromJson)
              .toList();
          return Ok(list);
        }
        return const Ok<List<UserAward>>([]);
      },
      (e) => Err<List<UserAward>>(e),
    );
  }

  /// Paginated; the caller loops until `Results` runs out.
  Future<Result<CompletionPage>> getUserCompletionProgress(
      {int count = 500, int offset = 0}) async {
    final res = await client.get('API_GetUserCompletionProgress',
        params: {'c': count, 'o': offset});
    return res.fold(
      (data) {
        if (data is! Map<String, dynamic>) {
          return const Err<CompletionPage>(
              AppError(AppErrorKind.parse, 'completion progress: not an object'));
        }
        final results = (data['Results'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CompletionEntry.fromJson)
            .toList();
        return Ok(CompletionPage(
          results: results,
          total: (data['Total'] is num) ? (data['Total'] as num).toInt() : results.length,
        ));
      },
      (e) => Err<CompletionPage>(e),
    );
  }

  /// Full achievement list of a game plus this user's progress in it.
  /// [user] lets the screen target another player (comparison view).
  Future<Result<GameProgress>> getGameInfoAndUserProgress(int gameId,
      {String? user}) async {
    final res = await client.get('API_GetGameInfoAndUserProgress', params: {
      'g': gameId,
      'a': 1,
      if (user != null && user.isNotEmpty) 'u': user,
    });
    return _mapObject(res, GameProgress.fromJson);
  }

  /// Every system on the site. [gamingOnly] drops Hubs and Events, so it stays
  /// false here — Events is exactly the system the challenges screen needs.
  Future<Result<List<ConsoleInfo>>> getConsoleIds(
      {bool gamingOnly = false}) async {
    final res = await client
        .get('API_GetConsoleIDs', params: {'g': gamingOnly ? 1 : 0});
    return _mapList(res, ConsoleInfo.fromJson);
  }

  /// Every game of a system. There is no events endpoint: an event is a game
  /// on the Events system, so this is how the catalogue is read.
  Future<Result<List<GameListEntry>>> getGameList(
    int consoleId, {
    bool onlyWithAchievements = true,
  }) async {
    final res = await client.get('API_GetGameList', params: {
      'i': consoleId,
      'f': onlyWithAchievements ? 1 : 0,
    });
    return _mapList(res, GameListEntry.fromJson);
  }

  /// Profile of any user, not just the signed-in one.
  Future<Result<UserProfile>> getProfileOf(String user) async {
    final res = await client.get('API_GetUserProfile', params: {'u': user});
    return _mapObject(res, UserProfile.fromJson);
  }

  Future<Result<UserSummary>> getSummaryOf(String user) async {
    final res = await client
        .get('API_GetUserSummary', params: {'u': user, 'g': 0, 'a': 0});
    return _mapObject(res, UserSummary.fromJson);
  }

  /// Comments left on a user's wall. The API is read-only: there is no
  /// endpoint to post one, so composing happens on the site.
  Future<Result<List<UserComment>>> getUserComments(String user,
      {int count = 50}) async {
    final res = await client.get('API_GetComments',
        params: {'i': user, 't': 3, 'c': count, 'o': 0});
    return res.fold(
      (data) {
        final results = data is Map<String, dynamic>
            ? (data['Results'] as List? ?? const [])
            : (data as List? ?? const []);
        return Ok(results
            .whereType<Map<String, dynamic>>()
            .map(UserComment.fromJson)
            .toList());
      },
      (e) => Err<List<UserComment>>(e),
    );
  }

  Future<Result<List<RecentGame>>> getWantToPlayList({int count = 100}) async {
    final res = await client
        .get('API_GetUserWantToPlayList', params: {'c': count, 'o': 0});
    return res.fold(
      (data) {
        final list = (data is Map ? (data['Results'] as List? ?? const []) : (data as List? ?? const []))
            .whereType<Map<String, dynamic>>()
            .map(RecentGame.fromJson)
            .toList();
        return Ok(list);
      },
      (e) => Err<List<RecentGame>>(e),
    );
  }

  Result<T> _mapObject<T>(
      Result<dynamic> res, T Function(Map<String, dynamic>) build) {
    return res.fold(
      (data) {
        if (data is Map<String, dynamic>) {
          try {
            return Ok(build(data));
          } catch (e) {
            return Err<T>(AppError(AppErrorKind.parse, e.toString(), cause: e));
          }
        }
        return const Err(AppError(AppErrorKind.parse, 'esperado objeto JSON'));
      },
      (e) => Err<T>(e),
    );
  }

  Result<List<T>> _mapList<T>(
      Result<dynamic> res, T Function(Map<String, dynamic>) build) {
    return res.fold(
      (data) {
        if (data is List) {
          try {
            final list = data.whereType<Map<String, dynamic>>().map(build).toList();
            return Ok(list);
          } catch (e) {
            return Err<List<T>>(AppError(AppErrorKind.parse, e.toString(), cause: e));
          }
        }
        // Some endpoints answer `[]` as `{}` when there is nothing to return.
        if (data is Map<String, dynamic> && data.isEmpty) return Ok(<T>[]);
        return Err<List<T>>(
            const AppError(AppErrorKind.parse, 'esperado array JSON'));
      },
      (e) => Err<List<T>>(e),
    );
  }
}

class CompletionPage {
  const CompletionPage({required this.results, required this.total});
  final List<CompletionEntry> results;
  final int total;
}
