/// The signed-in player: points, rank and the totals that used to crowd the
/// dashboard cards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/ui.dart';
import '../heatmap/heatmap_page.dart';
import '../heatmap/heatmap_painter.dart';
import '../settings/settings_page.dart';
import 'wall_section.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final profileAsync = ref.watch(myProfileProvider);
    final dashboard = ref.watch(dashboardProvider).valueOrNull;
    final summary = dashboard?.summary;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.profileTitle),
        actions: [
          IconButton(
            tooltip: l.actionRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshAll(ref),
          ),
          IconButton(
            tooltip: l.actionSettings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Padding(
            padding: EdgeInsets.all(16), child: SkeletonList(rows: 5)),
        error: (e, _) => ErrorView(
            error: e, onRetry: () => ref.invalidate(myProfileProvider)),
        data: (profile) {
          final rank = summary?.rank ?? profile.rank;
          final totalRanked = summary?.totalRanked;
          final progression = dashboard?.progression;
          final streaks = dashboard?.streaks;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GameIcon(profile.avatarUrl, size: 64, radius: 32),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.user,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            if (profile.memberSince != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                l.profileMemberSince(formatMonthYear(
                                    context, profile.memberSince!)),
                                style: const TextStyle(
                                    fontSize: 12, color: RaColors.muted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: l.sectionScore,
                icon: '🏅',
                child: Column(
                  children: [
                    _StatLine(
                      label: l.profileRankPosition,
                      value: rank == null
                          ? '—'
                          : totalRanked != null
                              ? l.profileRankValue(rank, totalRanked)
                              : l.profileRankValueShort(rank),
                      color: RaColors.achievements,
                      big: true,
                    ),
                    const SizedBox(height: 12),
                    _StatLine(
                      label: l.profilePoints,
                      value: formatThousands(context,
                          summary?.totalPoints ?? profile.totalPoints),
                      color: RaColors.points,
                    ),
                    const SizedBox(height: 10),
                    _StatLine(
                      label: l.profileWeightedPoints,
                      value: formatThousands(context,
                          summary?.totalTruePoints ?? profile.totalTruePoints),
                      color: RaColors.muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: l.sectionCollection,
                icon: '🎮',
                child: Column(
                  children: [
                    _StatLine(
                      label: l.statGamesPlayed,
                      value: '${progression?.totalGames ?? 0}',
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    _StatLine(
                      label: l.statMasteries,
                      value: '${progression?.totalMastered ?? 0}',
                      color: RaColors.mastered,
                    ),
                    const SizedBox(height: 10),
                    _StatLine(
                      label: l.profileBeaten,
                      value: '${progression?.totalBeaten ?? 0}',
                      color: RaColors.beaten,
                    ),
                    const SizedBox(height: 10),
                    _StatLine(
                      label: l.statMasteryRate,
                      value: '${progression?.masteryRatePercent ?? 0}%',
                      color: RaColors.achievements,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: l.sectionActivity,
                icon: '🔥',
                child: Column(
                  children: [
                    _StatLine(
                      label: l.profileCurrentStreak,
                      value: l.profileDays(streaks?.current ?? 0),
                      color: RaColors.streak,
                    ),
                    const SizedBox(height: 10),
                    _StatLine(
                      label: l.profileBestStreak,
                      value: l.profileDays(streaks?.best ?? 0),
                      color: RaColors.muted,
                    ),
                    const SizedBox(height: 10),
                    _StatLine(
                      label: l.profileActiveDays,
                      value: '${streaks?.activeDays ?? 0}',
                      color: RaColors.muted,
                    ),
                    const SizedBox(height: 10),
                    _StatLine(
                      label: l.profileAchievements365,
                      value: '${streaks?.totalAchievements ?? 0}',
                      color: RaColors.muted,
                    ),
                    const SizedBox(height: 14),
                    const _HeatmapPreview(),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.calendar_month, size: 16),
                        label: Text(l.activitySeeFull),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const HeatmapPage()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const _AwardsSection(),
              const SizedBox(height: 14),
              SectionCard(
                title: l.sectionWall,
                icon: '📝',
                child: const _MyWall(),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse('https://retroachievements.org/user/${profile.user}'),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(l.profileOpenOnSite),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.label,
    required this.value,
    required this.color,
    this.big = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool big;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 12.5, color: RaColors.muted)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: big ? 22 : 15,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      );
}

/// A read-only glance at the year grid — the interactive one (mode toggles,
/// tap-a-day, game/achievement lists) stays on [HeatmapPage]; tapping this
/// preview opens it. Draws from [heatmapGridProvider] so both places always
/// show the same grid instead of two independent computations.
class _HeatmapPreview extends ConsumerWidget {
  const _HeatmapPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(heatmapGridProvider);
    return async.when(
      loading: () => const Skeleton(height: 90, radius: 10),
      error: (_, __) => const SizedBox.shrink(),
      data: (grid) {
        final size = HeatmapPainter.sizeFor(grid);
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const HeatmapPage()),
          ),
          child: SizedBox(
            height: size.height,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: IgnorePointer(
                // The preview only opens the full page; day taps live there.
                child: CustomPaint(
                  size: size,
                  painter: HeatmapPainter(grid: grid, selectedDay: null),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Trophies and masteries — the vitrine RetroAchievements gives every player
/// and this app never showed until now, even though [myAwardsProvider]
/// (`GetUserAwards`) has been fetched all along to build the heatmap.
class _AwardsSection extends ConsumerWidget {
  const _AwardsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(myAwardsProvider);
    final filter = ref.watch(awardFilterProvider);

    return SectionCard(
      title: l.sectionAwards,
      icon: '🏆',
      child: async.when(
        loading: () => const SkeletonList(rows: 3),
        error: (e, _) =>
            ErrorView(error: e, onRetry: () => ref.invalidate(myAwardsProvider)),
        data: (awards) {
          if (awards.isEmpty) return EmptyView(l.emptyAwards);
          final sorted = [...awards]..sort((a, b) {
              final da = a.awardedAt, db = b.awardedAt;
              if (da == null || db == null) return 0;
              return db.compareTo(da);
            });
          final visible = switch (filter) {
            AwardFilter.all => sorted,
            AwardFilter.mastered =>
              sorted.where((a) => a.kind?.isMastery ?? false).toList(),
            AwardFilter.beaten =>
              sorted.where((a) => a.kind?.isBeaten ?? false).toList(),
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AwardFilters(filter: filter),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                EmptyView(l.emptyAwards)
              else
                for (final a in visible.take(20))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AwardRow(award: a),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _AwardFilters extends ConsumerWidget {
  const _AwardFilters({required this.filter});
  final AwardFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);

    Widget chip(AwardFilter value, String label) => ChoiceChip(
          selected: filter == value,
          label: Text(label, style: const TextStyle(fontSize: 12)),
          showCheckmark: false,
          backgroundColor: RaColors.surface,
          selectedColor: RaColors.achievements.withValues(alpha: 0.18),
          side: BorderSide(
              color: filter == value ? RaColors.achievements : RaColors.border),
          onSelected: (_) => ref.read(awardFilterProvider.notifier).state = value,
        );

    return Wrap(
      spacing: 8,
      children: [
        chip(AwardFilter.all, l.filterAll),
        chip(AwardFilter.mastered, l.filterMastered),
        chip(AwardFilter.beaten, l.profileBeaten),
      ],
    );
  }
}

class _AwardRow extends StatelessWidget {
  const _AwardRow({required this.award});
  final UserAward award;

  @override
  Widget build(BuildContext context) {
    final kind = award.kind;
    final color = kind == null
        ? RaColors.muted
        : kind.isMastery
            ? RaColors.mastered
            : RaColors.beaten;
    final emoji = kind == null ? '🎖️' : (kind.isMastery ? '👑' : '✅');

    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: color, width: 1.5),
          ),
          child: GameIcon(award.iconUrl, size: 36, radius: 6),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(award.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                [
                  '$emoji ${kind?.label ?? award.consoleName}',
                  if (kind != null) award.consoleName,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: RaColors.muted),
              ),
            ],
          ),
        ),
        if (award.awardedAt != null)
          Text(formatDayMonth(context, award.awardedAt!),
              style: const TextStyle(fontSize: 11, color: RaColors.muted)),
      ],
    );
  }
}

/// The wall other players saw and you couldn't, until now — same widget and
/// endpoint as another player's wall, just pointed at your own username.
class _MyWall extends ConsumerWidget {
  const _MyWall();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myWallProvider);
    return async.when(
      loading: () => const SkeletonList(rows: 3),
      error: (e, _) =>
          ErrorView(error: e, onRetry: () => ref.invalidate(myWallProvider)),
      data: (comments) => WallComments(comments: comments),
    );
  }
}
