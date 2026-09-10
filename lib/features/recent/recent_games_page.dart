/// Port of the site's "Last N Games Played" block: one row per game with its
/// progress, and an expandable badge grid loaded on demand.
///
/// [RecentGamesBody] is the content only (no Scaffold/AppBar) — it is one of
/// the two segments of the merged "Jogos" tab; see GamesPage.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/insights/rarity.dart';
import '../../domain/models/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/ui.dart';
import '../game/achievement_sheet.dart';
import '../game/game_page.dart';

const _pageSizes = [5, 10, 25, 50];

class RecentGamesBody extends ConsumerWidget {
  const RecentGamesBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final query = ref.watch(recentGamesQueryProvider);
    final async = ref.watch(recentGamesPageProvider);

    return RefreshIndicator(
      onRefresh: () => refreshRecentGames(ref),
      child: async.when(
        loading: () => const Padding(
            padding: EdgeInsets.all(16), child: SkeletonList(rows: 5)),
        error: (e, _) => ListView(children: [
          const SizedBox(height: 60),
          ErrorView(
              error: e, onRetry: () => ref.invalidate(recentGamesPageProvider)),
        ]),
        data: (cached) {
          final games = cached.value;
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
            children: [
              _ShowSelector(query: query),
              const SizedBox(height: 8),
              if (games.isEmpty)
                NotFoundCard(message: l.recentEmptyPage)
              else
                for (final g in games)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RecentGameCard(game: g),
                  ),
              const SizedBox(height: 4),
              _Pager(query: query, hasNext: games.length >= query.pageSize),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  cached.stale
                      ? '${relativeTime(context, cached.fetchedAt)} · '
                          '${l.cachedData}'
                      : relativeTime(context, cached.fetchedAt),
                  style: const TextStyle(fontSize: 11, color: RaColors.muted),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShowSelector extends ConsumerWidget {
  const _ShowSelector({required this.query});
  final RecentGamesQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Text(l.recentShow,
            style: const TextStyle(fontSize: 13, color: RaColors.muted)),
        const SizedBox(width: 10),
        DropdownButton<int>(
          value: query.pageSize,
          isDense: true,
          underline: const SizedBox.shrink(),
          items: [
            for (final n in _pageSizes)
              DropdownMenuItem(value: n, child: Text('$n')),
          ],
          // Changing the page size restarts at the first page, like the site.
          onChanged: (n) => ref.read(recentGamesQueryProvider.notifier).state =
              query.copyWith(pageSize: n, page: 0),
        ),
        const Spacer(),
        Text(l.recentPage(query.page + 1),
            style: const TextStyle(fontSize: 12, color: RaColors.muted)),
      ],
    );
  }
}

class _Pager extends ConsumerWidget {
  const _Pager({required this.query, required this.hasNext});
  final RecentGamesQuery query;
  final bool hasNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    void go(int page) =>
        ref.read(recentGamesQueryProvider.notifier).state = query.copyWith(page: page);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: l.pagerFirst,
          icon: const Icon(Icons.first_page),
          onPressed: query.page == 0 ? null : () => go(0),
        ),
        IconButton(
          tooltip: l.pagerPrevious,
          icon: const Icon(Icons.chevron_left),
          onPressed: query.page == 0 ? null : () => go(query.page - 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('${query.page + 1}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        IconButton(
          tooltip: l.pagerNext,
          icon: const Icon(Icons.chevron_right),
          onPressed: hasNext ? () => go(query.page + 1) : null,
        ),
      ],
    );
  }
}

class _RecentGameCard extends StatefulWidget {
  const _RecentGameCard({required this.game});
  final RecentGame game;

  @override
  State<_RecentGameCard> createState() => _RecentGameCardState();
}

class _RecentGameCardState extends State<_RecentGameCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final g = widget.game;

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 6, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GameIcon(g.iconUrl, size: 48, radius: 8),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                GamePage(gameId: g.gameId, fallbackTitle: g.title),
                          ),
                        ),
                        child: Text(
                          g.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: RaColors.achievements,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (g.hasAchievements) ...[
                        _Stat(l.recentAchievementsOf(g.earned, g.numPossible)),
                        _Stat(l.recentPointsOf(g.pointsEarned, g.possibleScore)),
                      ] else
                        _Stat(l.recentNoAchievements),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _ConsoleChip(g.consoleName),
                          const SizedBox(width: 8),
                          if (g.lastPlayed != null)
                            Expanded(
                              child: Text(
                                l.recentPlayedOn(
                                    formatLongDate(context, g.lastPlayed!)),
                                style: const TextStyle(
                                    fontSize: 11, color: RaColors.muted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                      if (g.hasAchievements) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: ProgressBar(value: g.progress)),
                            const SizedBox(width: 8),
                            Text('${g.percent}%',
                                style: const TextStyle(
                                    fontSize: 11, color: RaColors.muted)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: _expanded ? l.actionCollapse : l.actionExpand,
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: g.hasAchievements
                      ? () => setState(() => _expanded = !_expanded)
                      : null,
                ),
              ],
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _BadgeGrid(gameId: g.gameId, title: g.title),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 12, color: RaColors.muted),
      );
}

class _ConsoleChip extends StatelessWidget {
  const _ConsoleChip(this.name);
  final String name;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: RaColors.surfaceAlt,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: RaColors.border),
        ),
        child: Text(name,
            style: const TextStyle(fontSize: 10, color: RaColors.muted)),
      );
}

/// The badge wall. Loaded only when the row is expanded — one extra API call
/// per game, never on the list itself.
class _BadgeGrid extends ConsumerWidget {
  const _BadgeGrid({required this.gameId, required this.title});

  final int gameId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(gameProgressProvider(gameId));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (e, _) => ErrorView(
        error: e,
        onRetry: () => ref.invalidate(gameProgressProvider(gameId)),
      ),
      data: (game) {
        if (game.achievements.isEmpty) {
          return NotFoundCard(message: l.badgeNoAchievements);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final a in game.achievements)
                  _Badge(
                    achievement: a,
                    tier: rarityOf(game, a),
                    onTap: () => showAchievementSheet(context, game, a),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.list, size: 16),
                label: Text(l.seeFullList),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GamePage(gameId: gameId, fallbackTitle: title),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.achievement,
    required this.tier,
    required this.onTap,
  });

  final GameAchievement achievement;
  final RarityTier? tier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final earned = achievement.isEarned;
    return Tooltip(
      message: achievement.title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Opacity(
          // Locked badges are already served greyscale; the fade separates
          // them further on a small screen.
          opacity: earned ? 1 : 0.55,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              // The border carries rarity; earned vs locked is already told by
              // the greyscale badge and the opacity above.
              border: Border.all(
                color: tier == null
                    ? RaColors.border
                    : rarityColor(tier!).withValues(alpha: earned ? 1 : 0.5),
                width: earned ? 1.5 : 1,
              ),
            ),
            child: GameIcon(
              earned ? achievement.badgeUrl : achievement.lockedBadgeUrl,
              size: 38,
              radius: 5,
            ),
          ),
        ),
      ),
    );
  }
}
