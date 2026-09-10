/// One game: every achievement, earned and locked, and how much is left.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/insights/rarity.dart';
import '../../domain/insights/search.dart';
import '../../domain/models/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/ui.dart';
import 'achievement_sheet.dart';

enum AchievementFilter { all, earned, locked }

final achievementFilterProvider =
    StateProvider<AchievementFilter>((ref) => AchievementFilter.all);

/// Pushes the game screen, optionally scrolling straight to one achievement.
void openGame(
  BuildContext context,
  int gameId,
  String? title, {
  int? highlightAchievementId,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => GamePage(
        gameId: gameId,
        fallbackTitle: title,
        highlightAchievementId: highlightAchievementId,
      ),
    ),
  );
}

/// Rows outside a game's own list (Mais raras, Atividade→Conquistas) only
/// know the achievement's id, not its full [GameAchievement] — the sheet
/// needs both. If [gameId]'s progress is already cached from a prior visit,
/// skip straight to the sheet; otherwise fall back to the game list with the
/// achievement highlighted, same as before this existed.
void openAchievement(
  BuildContext context,
  WidgetRef ref, {
  required int gameId,
  required String? gameTitle,
  required int achievementId,
}) {
  final game = ref.read(gameProgressProvider(gameId)).valueOrNull;
  final match =
      game?.achievements.where((a) => a.id == achievementId) ?? const [];
  if (game != null && match.isNotEmpty) {
    showAchievementSheet(context, game, match.first);
    return;
  }
  openGame(context, gameId, gameTitle, highlightAchievementId: achievementId);
}

class GamePage extends ConsumerStatefulWidget {
  const GamePage({
    super.key,
    required this.gameId,
    this.fallbackTitle,
    this.highlightAchievementId,
  });

  final int gameId;
  final String? fallbackTitle;

  /// Arrived from a list that pointed at one achievement: scroll to it and
  /// mark it, so the user is not left hunting through eighty rows.
  final int? highlightAchievementId;

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> {
  final _highlightKey = GlobalKey();
  final _scroll = ScrollController();
  final _searchController = TextEditingController();
  bool _scrolled = false;
  String _query = '';

  /// Rough measurements used only to get the target row built; the exact
  /// position is corrected right after.
  static const _headerHeight = 210.0;
  static const _rowHeight = 116.0;

  @override
  void dispose() {
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Runs once. The list builds its rows lazily, so an off-screen target has
  /// no context to scroll to yet: jump to an estimate first to force it into
  /// existence, then let [Scrollable.ensureVisible] land it precisely.
  void _revealHighlight(int index) {
    if (_scrolled) return;
    _scrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo((_headerHeight + index * _rowHeight)
          .clamp(0.0, _scroll.position.maxScrollExtent));

      await WidgetsBinding.instance.endOfFrame;
      final target = _highlightKey.currentContext;
      // The row can be scrolled back out of the tree during the awaited frame.
      if (!mounted || target == null || !target.mounted) return;
      await Scrollable.ensureVisible(target,
          duration: const Duration(milliseconds: 350),
          alignment: 0.3,
          curve: Curves.easeOutCubic);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(gameProgressProvider(widget.gameId));
    final filter = ref.watch(achievementFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            async.valueOrNull?.title ??
                widget.fallbackTitle ??
                l.gameFallbackTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: l.gameOpenOnSite,
            icon: const Icon(Icons.open_in_new, size: 20),
            onPressed: () => launchUrl(
              Uri.parse('https://retroachievements.org/game/${widget.gameId}'),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonList(rows: 8),
        ),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(gameProgressProvider(widget.gameId)),
        ),
        data: (game) {
          var list = switch (filter) {
            AchievementFilter.all => game.achievements,
            AchievementFilter.earned =>
              game.achievements.where((a) => a.isEarned).toList(),
            AchievementFilter.locked =>
              game.achievements.where((a) => !a.isEarned).toList(),
          };

          // A jogo grande (a CL7W tem 291 conquistas) inviabiliza rolar tudo
          // para achar uma. Busca por título ou descrição, sem acento/caixa.
          final q = normalizeForSearch(_query);
          if (q.isNotEmpty) {
            list = list
                .where((a) =>
                    normalizeForSearch(a.title).contains(q) ||
                    normalizeForSearch(a.description).contains(q))
                .toList();
          }

          // Only reveal when the row is actually in the current filter.
          final highlightIndex =
              list.indexWhere((a) => a.id == widget.highlightAchievementId);
          if (highlightIndex >= 0) _revealHighlight(highlightIndex);

          return ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _GameHeader(game: game),
              const SizedBox(height: 14),
              if (game.achievements.length > 8) ...[
                TextField(
                  controller: _searchController,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: l.achievementSearchHint,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 12),
              ],
              _FilterChips(game: game, filter: filter),
              const SizedBox(height: 14),
              if (list.isEmpty)
                NotFoundCard(message: l.gameEmptyFilter)
              else
                for (final a in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _AchievementRow(
                      key: a.id == widget.highlightAchievementId
                          ? _highlightKey
                          : null,
                      game: game,
                      achievement: a,
                      highlighted: a.id == widget.highlightAchievementId,
                      onTap: () => showAchievementSheet(context, game, a),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({required this.game});
  final GameProgress game;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final kind = game.highestAwardKind;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GameIcon(game.iconUrl, size: 56, radius: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(game.title,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(
                        [
                          game.consoleName,
                          if (game.genre.isNotEmpty) game.genre,
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, color: RaColors.muted),
                      ),
                      if (kind != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (kind.isMastery
                                    ? RaColors.mastered
                                    : RaColors.beaten)
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(kind.label,
                              style: TextStyle(
                                  fontSize: 10.5,
                                  color: kind.isMastery
                                      ? RaColors.mastered
                                      : RaColors.beaten)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ProgressBar(value: game.progress),
            const SizedBox(height: 8),
            Text(
              l.gameProgressLine(
                      game.earned, game.numAchievements, game.percent) +
                  (game.remaining > 0
                      ? l.gameRemainingSuffix(game.remaining)
                      : ''),
              style: const TextStyle(fontSize: 12, color: RaColors.muted),
            ),
            const SizedBox(height: 4),
            Text(
              l.gamePointsLine(game.pointsEarned, game.pointsTotal) +
                  (game.remaining > 0
                      ? l.gameDifficultySuffix(
                          game.remainingDifficulty.round())
                      : ''),
              style: const TextStyle(fontSize: 11.5, color: RaColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.game, required this.filter});
  final GameProgress game;
  final AchievementFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final earned = game.achievements.where((a) => a.isEarned).length;
    final locked = game.achievements.length - earned;

    Widget chip(AchievementFilter value, String label, int count, Color color) =>
        ChoiceChip(
          selected: filter == value,
          showCheckmark: false,
          backgroundColor: RaColors.surface,
          selectedColor: color.withValues(alpha: 0.18),
          side: BorderSide(color: filter == value ? color : RaColors.border),
          label: Text('$label $count', style: const TextStyle(fontSize: 12)),
          onSelected: (_) =>
              ref.read(achievementFilterProvider.notifier).state = value,
        );

    return Wrap(
      spacing: 8,
      children: [
        chip(AchievementFilter.all, l.gameFilterAll, game.achievements.length,
            RaColors.achievements),
        chip(AchievementFilter.earned, l.gameFilterEarned, earned,
            RaColors.mastered),
        chip(AchievementFilter.locked, l.gameFilterLocked, locked,
            RaColors.beaten),
      ],
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({
    super.key,
    required this.game,
    required this.achievement,
    required this.onTap,
    this.highlighted = false,
  });

  final GameProgress game;
  final GameAchievement achievement;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = achievement;
    final earned = a.isEarned;
    final rate = game.unlockRate(a);
    final tier = rarityOf(game, a);

    return Opacity(
      opacity: earned ? 1 : 0.55,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
        padding: highlighted
            ? const EdgeInsets.fromLTRB(8, 8, 8, 8)
            : EdgeInsets.zero,
        decoration: highlighted
            ? BoxDecoration(
                color: RaColors.achievements.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: RaColors.achievements.withValues(alpha: 0.45)),
              )
            : null,
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GameIcon(earned ? a.badgeUrl : a.lockedBadgeUrl, size: 40, radius: 7),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(a.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    if (a.type == 'progression' || a.type == 'win_condition')
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.flag, size: 13, color: RaColors.muted),
                      ),
                    if (a.type == 'missable')
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.warning_amber,
                            size: 13, color: RaColors.streak),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(a.description,
                    style: const TextStyle(
                        fontSize: 11.5, color: RaColors.muted, height: 1.3)),
                const SizedBox(height: 4),
                Text(
                  [
                    l.pointsShort(a.points),
                    if (a.rarityMultiplier != null)
                      'x${a.rarityMultiplier!.toStringAsFixed(1)}',
                    if (earned) _earnedLabel(context, a),
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 11,
                    color: earned ? RaColors.mastered : RaColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (tier != null) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RarityChip(
                  tier: tier,
                  // The exact rate when the payload carried player counts,
                  // the TrueRatio multiplier when it did not.
                  text: rate != null
                      ? formatPercent(context, rate)
                      : 'x${a.rarityMultiplier!.toStringAsFixed(1)}',
                ),
                const SizedBox(height: 3),
                Text(rarityLabel(l, tier),
                    style: const TextStyle(
                        fontSize: 9.5, color: RaColors.muted)),
              ],
            ),
          ],
          ],
          ),
        ),
      ),
    );
  }
}

String _earnedLabel(BuildContext context, GameAchievement a) {
  final l = AppLocalizations.of(context);
  final when = a.earnedAt;
  if (when == null) return l.achievementEarned;
  final d = formatShortDate(context, when);
  return a.isHardcore
      ? l.achievementEarnedOn(d)
      : l.achievementEarnedOnCasual(d);
}
