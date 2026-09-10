/// The activity index behind the Atividade tab.
///
/// A year of unlocks and a year of awards become one flat list of events, each
/// tagged with its heatmap mode, day and game. Every view on that screen — the
/// grid, the game list, the achievement list — is a filter over this list, so
/// filtering by mode or by day never touches the network.
library;

import '../models/models.dart';
import '../../core/parsing.dart';
import 'heatmap.dart';

class ActivityEvent {
  const ActivityEvent({
    required this.mode,
    required this.dayKey,
    required this.gameId,
    required this.title,
    required this.consoleName,
    required this.iconUrl,
    required this.points,
    required this.date,
    this.achievement,
  });

  final HeatmapMode mode;
  final String dayKey;
  final int gameId;
  final String title;
  final String consoleName;
  final String iconUrl;

  /// Points of the unlock; zero for awards, which carry no points of their own.
  final int points;
  final DateTime? date;

  /// Present only for [HeatmapMode.achievements] events.
  final EarnedAchievement? achievement;
}

class GameActivity {
  const GameActivity({
    required this.gameId,
    required this.title,
    required this.consoleName,
    required this.iconUrl,
    required this.unlocks,
    required this.points,
    required this.lastActivity,
    required this.rarest,
    required this.mastered,
    required this.beaten,
  });

  final int gameId;
  final String title;
  final String consoleName;
  final String iconUrl;
  final int unlocks;
  final int points;
  final DateTime? lastActivity;

  /// Highest TrueRatio unlocked in this game during the period.
  final int rarest;
  final bool mastered;
  final bool beaten;
}

/// Flattens both payloads into events. [icons] maps game id → icon path, since
/// unlocks carry the achievement badge but not the game icon.
List<ActivityEvent> buildActivityEvents(
  List<EarnedAchievement> yearly,
  List<UserAward> awards, {
  Map<int, String> icons = const {},
  DateTime? today,
}) {
  final events = <ActivityEvent>[];

  for (final a in yearly) {
    final day = a.dayKey;
    if (day == null || a.gameId == 0) continue;
    events.add(ActivityEvent(
      mode: HeatmapMode.achievements,
      dayKey: day,
      gameId: a.gameId,
      title: a.gameTitle,
      consoleName: a.consoleName,
      iconUrl: icons[a.gameId] ?? '',
      points: a.points,
      date: a.dateTime,
      achievement: a,
    ));
  }

  final now = today ?? DateTime.now().toUtc();
  final cutoff = DateTime.utc(now.year, now.month, now.day)
      .subtract(const Duration(days: 365));

  for (final award in awards) {
    final at = award.awardedAt;
    final gameId = award.gameId;
    final kind = award.kind;
    if (at == null || gameId == null || kind == null) continue;
    final atUtc = at.isUtc ? at : at.toUtc();
    if (atUtc.isBefore(cutoff)) continue;

    final mode = kind.isMastery
        ? HeatmapMode.mastered
        : kind.isBeaten
            ? HeatmapMode.beaten
            : null;
    if (mode == null) continue;

    events.add(ActivityEvent(
      mode: mode,
      dayKey: dayKeyOfDate(atUtc),
      gameId: gameId,
      title: award.title,
      consoleName: award.consoleName,
      iconUrl: icons[gameId] ?? mediaUrl(award.imageIcon),
      points: 0,
      date: atUtc,
    ));
  }

  return events;
}

/// Narrows the index by the toggled modes and, when a grid cell is selected,
/// by that single day.
List<ActivityEvent> filterActivity(
  List<ActivityEvent> events, {
  Set<HeatmapMode> modes = const {
    HeatmapMode.achievements,
    HeatmapMode.mastered,
    HeatmapMode.beaten,
  },
  String? dayKey,
}) =>
    events
        .where((e) => modes.contains(e.mode))
        .where((e) => dayKey == null || e.dayKey == dayKey)
        .toList();

/// Day counts per mode, for the grid.
HeatmapData heatmapDataFrom(List<ActivityEvent> events) {
  final achievements = <String, int>{};
  final mastered = <String, int>{};
  final beaten = <String, int>{};

  for (final e in events) {
    final map = switch (e.mode) {
      HeatmapMode.achievements => achievements,
      HeatmapMode.mastered => mastered,
      HeatmapMode.beaten => beaten,
    };
    map[e.dayKey] = (map[e.dayKey] ?? 0) + 1;
  }

  return HeatmapData(
    achievements: achievements,
    mastered: mastered,
    beaten: beaten,
  );
}

/// Groups events by game, most recent activity first.
List<GameActivity> gamesFromActivity(List<ActivityEvent> events, {int? limit}) {
  final byGame = <int, List<ActivityEvent>>{};
  for (final e in events) {
    byGame.putIfAbsent(e.gameId, () => []).add(e);
  }

  final out = <GameActivity>[];
  byGame.forEach((gameId, list) {
    var unlocks = 0;
    var points = 0;
    var rarest = 0;
    var mastered = false;
    var beaten = false;
    DateTime? last;
    String title = '';
    String console = '';
    String icon = '';

    for (final e in list) {
      switch (e.mode) {
        case HeatmapMode.achievements:
          unlocks++;
          points += e.points;
          final tr = e.achievement?.trueRatio ?? 0;
          if (tr > rarest) rarest = tr;
        case HeatmapMode.mastered:
          mastered = true;
        case HeatmapMode.beaten:
          beaten = true;
      }
      if (title.isEmpty && e.title.isNotEmpty) title = e.title;
      if (console.isEmpty && e.consoleName.isNotEmpty) console = e.consoleName;
      if (icon.isEmpty && e.iconUrl.isNotEmpty) icon = e.iconUrl;
      final when = e.date;
      final current = last;
      if (when != null && (current == null || when.isAfter(current))) {
        last = when;
      }
    }

    out.add(GameActivity(
      gameId: gameId,
      title: title,
      consoleName: console,
      iconUrl: icon,
      unlocks: unlocks,
      points: points,
      lastActivity: last,
      rarest: rarest,
      mastered: mastered,
      beaten: beaten,
    ));
  });

  out.sort((a, b) {
    final an = a.lastActivity, bn = b.lastActivity;
    if (an == null && bn == null) return b.unlocks.compareTo(a.unlocks);
    if (an == null) return 1;
    if (bn == null) return -1;
    final byDate = bn.compareTo(an);
    return byDate != 0 ? byDate : b.unlocks.compareTo(a.unlocks);
  });

  if (limit != null && out.length > limit) return out.sublist(0, limit);
  return out;
}

/// The unlocks behind the current filter, newest first.
List<EarnedAchievement> achievementsFromActivity(List<ActivityEvent> events) {
  final out = [
    for (final e in events)
      if (e.achievement != null) e.achievement!,
  ];
  out.sort((a, b) {
    final ad = a.dateTime, bd = b.dateTime;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    return bd.compareTo(ad);
  });
  return out;
}
