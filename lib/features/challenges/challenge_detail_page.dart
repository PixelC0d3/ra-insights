/// One event, turned into a plan: what is left, easiest first, and which game
/// each remaining achievement seems to want you to play.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/insights/challenge_match.dart';
import '../../domain/insights/challenge_plan.dart';
import '../../domain/insights/challenges.dart';
import '../../domain/insights/rarity.dart';
import '../../domain/models/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/ui.dart';
import '../game/achievement_sheet.dart';
import '../game/game_page.dart';

class ChallengeDetailPage extends ConsumerWidget {
  const ChallengeDetailPage({super.key, required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final progressAsync = ref.watch(gameProgressProvider(challenge.gameId));
    final targetsAsync = ref.watch(challengeTargetsProvider(challenge.gameId));

    return Scaffold(
      appBar: AppBar(
        // Event titles run long ("Challenge League 7 Wonders of the RA World
        // Evergreen") and the name is the only context this screen gives —
        // two lines beat an ellipsis that hides which event this is.
        toolbarHeight: 64,
        title: Text(challenge.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, height: 1.2)),
        actions: [
          IconButton(
            tooltip: l.challengeOpenOnSite,
            icon: const Icon(Icons.open_in_new, size: 20),
            onPressed: () => launchUrl(
              Uri.parse(
                  'https://retroachievements.org/game/${challenge.gameId}'),
              mode: LaunchMode.externalApplication,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _Header(challenge: challenge, game: progressAsync.valueOrNull),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: progressAsync.valueOrNull == null
                ? null
                : () => _showPlan(context, ref, challenge.gameId),
            icon: const Icon(Icons.checklist, size: 18),
            label: Text(l.challengeBuildPlan),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: l.challengeNextUp,
            icon: '🎯',
            child: targetsAsync.when(
              loading: () => const SkeletonList(rows: 5),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref
                    .invalidate(challengeTargetsProvider(challenge.gameId)),
              ),
              data: (targets) {
                final game = progressAsync.valueOrNull;
                // Locked only, easiest first: a high unlock rate means most
                // players managed it.
                final locked = targets
                    .where((t) => !t.achievement.isEarned)
                    .toList()
                  ..sort((a, b) => _rate(game, b.achievement)
                      .compareTo(_rate(game, a.achievement)));

                if (locked.isEmpty) return EmptyView(l.challengeAllDone);

                // An event can have 290 locked achievements. Dumping all of
                // them is a wall, not a plan: show the easiest few and let the
                // full list live behind "see every achievement".
                const shown = 12;
                final todo =
                    locked.length > shown ? locked.sublist(0, shown) : locked;
                final hidden = locked.length - todo.length;

                // Plenty of events describe the task without naming the game.
                // The note only earns its space when there is a guess to explain.
                final guessed =
                    todo.any((t) => t.candidateTitle != null);

                return Column(
                  children: [
                    for (final t in todo)
                      _TargetRow(
                        target: t,
                        game: game,
                        // The next thing a tap here would do is show rarity,
                        // description and "abrir no site" — exactly what the
                        // sheet already offers. Jumping into the full game
                        // list first (todo/17..20 in the screenshots) added a
                        // detour with nothing of its own to add, so open the
                        // sheet directly whenever the data is already in
                        // hand; only fall back to the list while it loads.
                        onTap: () => game == null
                            ? openGame(
                                context,
                                challenge.gameId,
                                challenge.title,
                                highlightAchievementId: t.achievement.id,
                              )
                            : showAchievementSheet(context, game, t.achievement),
                      ),
                    if (hidden > 0) ...[
                      const SizedBox(height: 4),
                      Text(l.challengePlanMore(hidden),
                          style: const TextStyle(
                              fontSize: 11.5, color: RaColors.muted)),
                    ],
                    if (guessed) ...[
                      const SizedBox(height: 6),
                      Text(l.challengeGuessNote,
                          style: const TextStyle(
                              fontSize: 10.5,
                              color: RaColors.muted,
                              height: 1.4)),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () =>
                openGame(context, challenge.gameId, challenge.title),
            icon: const Icon(Icons.list, size: 18),
            label: Text(l.challengeSeeAll),
          ),
          const SizedBox(height: 14),
          Text(l.challengeRulesNote,
              style: const TextStyle(
                  fontSize: 11, color: RaColors.muted, height: 1.4)),
        ],
      ),
    );
  }
}

double _rate(GameProgress? game, GameAchievement a) =>
    game?.unlockRate(a) ?? 0;

/// A short, ordered checklist: the ten easiest that are left, and where they
/// take the event's completion.
void _showPlan(BuildContext context, WidgetRef ref, int eventId) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: RaColors.surface,
    isScrollControlled: true,
    useSafeArea: true,
    // Without a ceiling the sheet grows past the status bar and the title
    // collides with the clock.
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    builder: (sheetContext) {
      final l = AppLocalizations.of(sheetContext);
      return Consumer(
        builder: (_, sheetRef, __) {
          final async = sheetRef.watch(challengePlanProviderFamily(eventId));
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: async.when(
                loading: () => const SizedBox(
                    height: 140, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => ErrorView(error: e),
                data: (plan) {
                  if (plan.isEmpty) return EmptyView(l.challengePlanEmpty);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.challengePlanTitle,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(
                        l.challengePlanSummary(plan.steps.length,
                            plan.percentAfter, plan.pointsGained),
                        style: const TextStyle(
                            fontSize: 12.5, color: RaColors.muted),
                      ),
                      const SizedBox(height: 14),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: plan.steps.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) =>
                              _PlanStepRow(step: plan.steps[i], index: i + 1),
                        ),
                      ),
                      if (plan.remainingAfter > 0) ...[
                        const SizedBox(height: 12),
                        Text(l.challengePlanMore(plan.remainingAfter),
                            style: const TextStyle(
                                fontSize: 11.5, color: RaColors.muted)),
                      ],
                    ],
                  );
                },
              ),
            ),
          );
        },
      );
    },
  );
}

class _PlanStepRow extends StatelessWidget {
  const _PlanStepRow({required this.step, required this.index});

  final PlanStep step;
  final int index;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: RaColors.achievements.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text('$index',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: RaColors.achievements)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.achievement.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(step.achievement.description,
                  style: const TextStyle(
                      fontSize: 11.5, color: RaColors.muted, height: 1.3)),
              const SizedBox(height: 4),
              Text(
                [
                  l.pointsShort(step.achievement.points),
                  if (step.unlockRate != null)
                    formatPercent(context, step.unlockRate!),
                  '→ ${step.cumulativePercent}%',
                ].join(' · '),
                style: const TextStyle(fontSize: 11, color: RaColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.challenge, required this.game});

  final Challenge challenge;
  final GameProgress? game;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // The live payload is authoritative once it lands; the catalogue value
    // keeps the header populated while it loads.
    final earned = game?.earned ?? challenge.earned;
    final total = game?.numAchievements ?? challenge.totalAchievements;
    final progress = total > 0 ? earned / total : 0.0;
    final pointsLeft =
        game == null ? null : game!.pointsTotal - game!.pointsEarned;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GameIcon(challenge.iconUrl, size: 52, radius: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(challenge.title,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ProgressBar(value: progress),
            const SizedBox(height: 8),
            Text(
              '${l.challengeProgress(earned, total)} · '
              '${(progress * 100).round()}%',
              style: const TextStyle(fontSize: 12, color: RaColors.muted),
            ),
            if (pointsLeft != null && pointsLeft > 0) ...[
              const SizedBox(height: 4),
              Text(l.challengePointsLeft(pointsLeft),
                  style: const TextStyle(
                      fontSize: 11.5, color: RaColors.muted)),
            ],
          ],
        ),
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({
    required this.target,
    required this.game,
    required this.onTap,
  });

  final ChallengeTarget target;
  final GameProgress? game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = target.achievement;
    final rate = game?.unlockRate(a);
    final tier = game == null ? null : rarityOf(game!, a);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GameIcon(a.lockedBadgeUrl, size: 36, radius: 7),
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
                Text(a.description,
                    style: const TextStyle(
                        fontSize: 11.5, color: RaColors.muted, height: 1.3)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(l.pointsShort(a.points),
                        style: const TextStyle(
                            fontSize: 11, color: RaColors.muted)),
                    if (tier != null)
                      RarityChip(
                        tier: tier,
                        text: rate != null
                            ? formatPercent(context, rate)
                            : 'x${a.rarityMultiplier?.toStringAsFixed(1) ?? '?'}',
                      ),
                    if (target.candidateTitle != null)
                      _GameGuess(target: target),
                  ],
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

/// The inferred source game. Never presented as fact: uncertain matches carry
/// a question mark.
class _GameGuess extends StatelessWidget {
  const _GameGuess({required this.target});

  final ChallengeTarget target;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final owned = target.isInLibrary;
    final color = owned ? RaColors.rarityUncommon : RaColors.muted;
    final label = owned ? l.challengeInLibrary : l.challengeNewGame;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${target.candidateTitle} · $label',
              style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
          if (target.confidence == MatchConfidence.weak) ...[
            const SizedBox(width: 4),
            Icon(Icons.help_outline, size: 11, color: color),
          ],
        ],
      ),
    );
  }
}
