/// Activity: the 365-day grid plus everything behind it.
///
/// Mode chips and the selected day are one filter, applied to the grid and to
/// both lists below it. Tapping the selected day again unpins it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/insights/activity.dart';
import '../../domain/insights/heatmap.dart';
import '../../domain/insights/rarity.dart';
import '../../domain/models/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/ui.dart';
import '../game/game_page.dart';
import 'heatmap_painter.dart';

class HeatmapPage extends ConsumerStatefulWidget {
  const HeatmapPage({super.key});

  @override
  ConsumerState<HeatmapPage> createState() => _HeatmapPageState();
}

class _HeatmapPageState extends ConsumerState<HeatmapPage>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  late final TabController _tabs = TabController(length: 2, vsync: this)
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    _scroll.dispose();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(activityProvider);
    final modes = ref.watch(heatmapModesProvider);
    final selectedDay = ref.watch(selectedDayProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.navActivity)),
      body: RefreshIndicator(
        onRefresh: () => refreshAll(ref),
        child: async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Column(children: [Skeleton(height: 130, radius: 16)]),
          ),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 80),
            ErrorView(error: e, onRetry: () => ref.invalidate(activityProvider)),
          ]),
          data: (events) {
            final filtered = filterActivity(events, modes: modes, dayKey: selectedDay);
            // The grid always shows the whole year for the selected modes; the
            // day only narrows the lists below. Shared with the Profile tab's
            // preview via heatmapGridProvider, so both draw the same picture.
            final grid = ref.watch(heatmapGridProvider).valueOrNull ??
                buildHeatmap(heatmapDataFrom(const []), modes: modes);
            final games = gamesFromActivity(filtered);
            final achievements = achievementsFromActivity(filtered);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _ModeToggles(modes: modes, events: events),
                const SizedBox(height: 14),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.activityEvents(grid.total),
                            style: const TextStyle(
                                fontSize: 12.5, color: RaColors.muted)),
                        const SizedBox(height: 10),
                        _Grid(
                          grid: grid,
                          scroll: _scroll,
                          selected: selectedDay,
                          onTapDay: (day) {
                            final notifier =
                                ref.read(selectedDayProvider.notifier);
                            // Tapping the pinned day again clears it.
                            notifier.state = notifier.state == day ? null : day;
                          },
                        ),
                        const SizedBox(height: 10),
                        const _Legend(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _FilterSummary(
                  selectedDay: selectedDay,
                  games: games.length,
                  achievements: achievements.length,
                ),
                const SizedBox(height: 8),
                TabBar(
                  controller: _tabs,
                  labelStyle:
                      const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(text: l.tabGamesCount(games.length)),
                    Tab(text: l.tabAchievementsCount(achievements.length)),
                  ],
                ),
                const SizedBox(height: 14),
                if (_tabs.index == 0)
                  _GamesList(games: games)
                else
                  _AchievementsList(achievements: achievements),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.grid,
    required this.scroll,
    required this.selected,
    required this.onTapDay,
  });

  final HeatmapGrid grid;
  final ScrollController scroll;
  final String? selected;
  final ValueChanged<String> onTapDay;

  @override
  Widget build(BuildContext context) {
    final size = HeatmapPainter.sizeFor(grid);
    // Newest weeks on the right, so the view opens on the current month.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients && scroll.offset == 0) {
        scroll.jumpTo(scroll.position.maxScrollExtent);
      }
    });

    return SizedBox(
      height: size.height,
      child: SingleChildScrollView(
        controller: scroll,
        scrollDirection: Axis.horizontal,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final cell = HeatmapPainter.cellAt(grid, details.localPosition);
            if (cell != null && cell.count > 0) onTapDay(cell.dayKey);
          },
          child: CustomPaint(
            size: size,
            painter: HeatmapPainter(grid: grid, selectedDay: selected),
          ),
        ),
      ),
    );
  }
}

class _ModeToggles extends ConsumerWidget {
  const _ModeToggles({required this.modes, required this.events});
  final Set<HeatmapMode> modes;
  final List<ActivityEvent> events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget chip(HeatmapMode mode, String label, Color color) {
      final on = modes.contains(mode);
      // The count next to the label is the year total for that mode.
      final total = events.where((e) => e.mode == mode).length;
      return FilterChip(
        selected: on,
        label: Text('$label $total', style: const TextStyle(fontSize: 12)),
        showCheckmark: false,
        backgroundColor: RaColors.surface,
        selectedColor: color.withValues(alpha: 0.18),
        side: BorderSide(color: on ? color : RaColors.border),
        onSelected: (_) {
          final next = {...modes};
          if (on) {
            // Never let the last mode be turned off — an empty grid says nothing.
            if (next.length == 1) return;
            next.remove(mode);
          } else {
            next.add(mode);
          }
          ref.read(heatmapModesProvider.notifier).state = next;
        },
      );
    }

    final l = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      children: [
        chip(HeatmapMode.achievements, '🏆 ${l.chipAchievements}',
            RaColors.achievements),
        chip(HeatmapMode.mastered, '👑 ${l.chipMastered}', RaColors.mastered),
        chip(HeatmapMode.beaten, '✅ ${l.chipBeaten}', RaColors.beaten),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(l.legendLess,
            style: const TextStyle(fontSize: 10, color: RaColors.muted)),
        const SizedBox(width: 6),
        for (var level = 0; level <= 4; level++)
          Container(
            width: 11,
            height: 11,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: heatmapColor(HeatmapMode.achievements, level),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        const SizedBox(width: 6),
        Text(l.legendMore,
            style: const TextStyle(fontSize: 10, color: RaColors.muted)),
      ],
    );
  }
}

/// What the lists below are currently showing, and how to undo it.
class _FilterSummary extends ConsumerWidget {
  const _FilterSummary({
    required this.selectedDay,
    required this.games,
    required this.achievements,
  });

  final String? selectedDay;
  final int games;
  final int achievements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (selectedDay == null) {
      return Text(
        l.activityDayHint,
        style: const TextStyle(fontSize: 11.5, color: RaColors.muted),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            l.activityShowingDay(formatDayKey(context, selectedDay!)),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
        TextButton.icon(
          onPressed: () => ref.read(selectedDayProvider.notifier).state = null,
          icon: const Icon(Icons.close, size: 16),
          label: Text(l.activityClearDay,
              style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

class _GamesList extends StatelessWidget {
  const _GamesList({required this.games});
  final List<GameActivity> games;

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return NotFoundCard(
          message: AppLocalizations.of(context).emptyActivityGames);
    }
    return Column(
      children: [
        for (final g in games)
          _GameActivityRow(
            game: g,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    GamePage(gameId: g.gameId, fallbackTitle: g.title),
              ),
            ),
          ),
      ],
    );
  }
}

class _GameActivityRow extends StatelessWidget {
  const _GameActivityRow({required this.game, required this.onTap});

  final GameActivity game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final parts = [
      if (game.unlocks > 0) l.achievementCount(game.unlocks),
      if (game.points > 0) l.pointsShort(game.points),
      if (game.lastActivity != null)
        formatDayMonth(context, game.lastActivity!),
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            GameIcon(game.iconUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(game.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      if (game.mastered)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Text('👑', style: TextStyle(fontSize: 12)),
                        ),
                      if (game.beaten)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text('✅', style: TextStyle(fontSize: 11)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    parts.isEmpty ? game.consoleName : parts.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 11.5, color: RaColors.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: RaColors.muted),
          ],
        ),
      ),
    );
  }
}

class _AchievementsList extends ConsumerWidget {
  const _AchievementsList({required this.achievements});
  final List<EarnedAchievement> achievements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (achievements.isEmpty) {
      return NotFoundCard(message: l.emptyActivityAchievements);
    }
    return Column(
      children: [
        for (final a in achievements)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              // Opens the achievement sheet directly when its game is already
              // cached; otherwise falls back to the game list.
              onTap: () => openAchievement(context, ref,
                  gameId: a.gameId,
                  gameTitle: a.gameTitle,
                  achievementId: a.achievementId),
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  GameIcon(a.badgeImageUrl, size: 36, radius: 7),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('${a.gameTitle} · ${l.pointsShort(a.points)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11.5, color: RaColors.muted)),
                      ],
                    ),
                  ),
                  if (a.rarityMultiplier != null) ...[
                    RarityChip(
                      tier: rarityFromMultiplier(a.rarityMultiplier!),
                      text: 'x${a.rarityMultiplier!.toStringAsFixed(1)}',
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (a.dateTime != null)
                    Text(formatDayMonth(context, a.dateTime!),
                        style: const TextStyle(
                            fontSize: 11, color: RaColors.muted)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
