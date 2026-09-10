/// The app opens here: insights, not a game list.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/insights/almost_there.dart';
import '../../domain/insights/rarity.dart';
import '../../domain/insights/recommendation.dart';
import '../../domain/models/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';
import '../challenges/challenges_page.dart';
import '../game/game_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RA Insights',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          // Search moved to the Jogos tab, where "find a game" belongs; this
          // bar keeps only the whole-app refresh.
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppLocalizations.of(context).actionRefresh,
            onPressed: () => refreshAll(ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => refreshAll(ref),
        child: async.when(
          loading: () => const _DashboardSkeleton(),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 80),
              ErrorView(error: e, onRetry: () => ref.invalidate(dashboardProvider)),
            ],
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // Stale plus no fetch time at all means nothing came back from
              // the network on this run — say so instead of showing old
              // numbers as if they were current.
              if (data.stale && data.fetchedAt != null) ...[
                _OfflineBanner(fetchedAt: data.fetchedAt),
                const SizedBox(height: 12),
              ],
              // The number grid and the streak card used to live here too —
              // both duplicated the Profile tab's Pontuação/Coleção/Atividade
              // sections number for number. This screen answers "what do I do
              // now"; identity numbers belong to the Profile tab, which
              // already rendered them.
              if (data.pick != null) ...[
                _PlayNowCard(pick: data.pick!),
                const SizedBox(height: 14),
              ],
              _AlmostThereCard(games: data.almostThere),
              const SizedBox(height: 14),
              const _ChallengesCard(),
              const SizedBox(height: 14),
              const _RarestCard(),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  data.stale
                      ? '${relativeTime(context, data.fetchedAt)} · '
                          '${AppLocalizations.of(context).cachedData}'
                      : relativeTime(context, data.fetchedAt),
                  style: const TextStyle(fontSize: 11, color: RaColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.fetchedAt});
  final DateTime? fetchedAt;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: RaColors.streak.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: RaColors.streak.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 15, color: RaColors.streak),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${l.offlineBanner} · ${relativeTime(context, fetchedAt)}',
              style: const TextStyle(fontSize: 11.5, color: RaColors.streak),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayNowCard extends StatelessWidget {
  const _PlayNowCard({required this.pick});
  final PlayNowPick pick;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final game = pick.game;
    return SectionCard(
      title: l.cardPlayNow,
      icon: '🎯',
      onTap: () => openGame(context, game.gameId, game.title),
      child: Row(
        children: [
          GameIcon(game.iconUrl, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(game.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(l.playNowReason(game.remaining, game.percent),
                    style: const TextStyle(
                        fontSize: 12, color: RaColors.achievements)),
                const SizedBox(height: 8),
                ProgressBar(value: game.progress),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlmostThereCard extends StatelessWidget {
  const _AlmostThereCard({required this.games});
  final List<AlmostThereGame> games;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      title: l.cardAlmostThere,
      icon: '🏁',
      child: games.isEmpty
          ? EmptyView(l.emptyAlmostThere)
          : Column(
              children: [
                for (final g in games)
                  InkWell(
                    onTap: () => openGame(context, g.gameId, g.title),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          GameIcon(g.iconUrl),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 3),
                                Text(
                                  l.remainingLine(g.remaining, g.percent),
                                  style: const TextStyle(
                                      fontSize: 11.5, color: RaColors.muted),
                                ),
                                const SizedBox(height: 6),
                                ProgressBar(value: g.progress),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              size: 18, color: RaColors.muted),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// The events the user is closest to finishing. Loads on its own so the
/// catalogue fetch never blocks the dashboard.
class _ChallengesCard extends ConsumerWidget {
  const _ChallengesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(challengePlanProvider);

    return SectionCard(
      title: l.cardChallenges,
      icon: '\u{1F3C6}',
      // Desafios is a tab of its own now — switch to it instead of pushing a
      // second copy of the page on top of the shell.
      onTap: () => context.go('/challenges'),
      child: async.when(
        loading: () => const SkeletonList(rows: 3),
        error: (e, _) => ErrorView(
            error: e, onRetry: () => ref.invalidate(challengeCatalogProvider)),
        data: (challenges) => challenges.isEmpty
            ? EmptyView(l.challengeEmpty)
            : Column(
                children: [
                  for (final c in challenges)
                    ChallengeRow(challenge: c, dense: true),
                ],
              ),
      ),
    );
  }
}

/// Rarest unlocks, over a window the user picks. The list loads on its own so
/// the all-time walk never blocks the rest of the dashboard.
class _RarestCard extends ConsumerWidget {
  const _RarestCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final window = ref.watch(rarestWindowProvider);
    final async = ref.watch(rarestProvider);

    Widget chip(RarestWindow value, String label) => ChoiceChip(
          selected: window == value,
          label: Text(label, style: const TextStyle(fontSize: 12)),
          showCheckmark: false,
          backgroundColor: RaColors.surface,
          selectedColor: RaColors.achievements.withValues(alpha: 0.18),
          side: BorderSide(
              color: window == value ? RaColors.achievements : RaColors.border),
          onSelected: (_) =>
              ref.read(rarestWindowProvider.notifier).state = value,
        );

    return SectionCard(
      title: l.cardRarest,
      icon: '💎',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: [
              chip(RarestWindow.all, l.rarestWindowAll),
              chip(RarestWindow.days90, l.rarestWindow90),
              chip(RarestWindow.days30, l.rarestWindow30),
            ],
          ),
          const SizedBox(height: 14),
          async.when(
            loading: () => const SkeletonList(rows: 4),
            error: (e, _) =>
                ErrorView(error: e, onRetry: () => ref.invalidate(rarestProvider)),
            data: (achievements) => achievements.isEmpty
                ? EmptyView(l.emptyRarest)
                : Column(
                    children: [
                      for (final a in achievements)
                        _RarestRow(achievement: a),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RarestRow extends ConsumerWidget {
  const _RarestRow({required this.achievement});
  final EarnedAchievement achievement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final a = achievement;
    return InkWell(
      // Opens the achievement sheet directly when its game is already
      // cached; otherwise falls back to the game list, scrolled to it.
      onTap: () => openAchievement(context, ref,
          gameId: a.gameId,
          gameTitle: a.gameTitle,
          achievementId: a.achievementId),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            GameIcon(a.badgeImageUrl, size: 34, radius: 6),
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
            const SizedBox(width: 8),
            if (a.rarityMultiplier != null)
              RarityChip(
                tier: rarityFromMultiplier(a.rarityMultiplier!),
                text: 'x${a.rarityMultiplier!.toStringAsFixed(1)}',
              )
            else
              const Text('—',
                  style: TextStyle(fontSize: 12, color: RaColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: const [
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SkeletonList(rows: 2),
          ),
        ),
        SizedBox(height: 14),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SkeletonList(rows: 3),
          ),
        ),
        SizedBox(height: 14),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: SkeletonList(rows: 4),
          ),
        ),
      ],
    );
  }
}
