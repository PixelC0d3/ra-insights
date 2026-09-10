/// The events of RetroAchievements, listed as things to finish.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/insights/challenges.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';
import 'challenge_detail_page.dart';

class ChallengesPage extends ConsumerStatefulWidget {
  const ChallengesPage({super.key});

  @override
  ConsumerState<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends ConsumerState<ChallengesPage> {
  late final TextEditingController _search =
      TextEditingController(text: ref.read(challengeQueryProvider));

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final filter = ref.watch(challengeFilterProvider);
    final sort = ref.watch(challengeSortProvider);
    final query = ref.watch(challengeQueryProvider);
    final catalog = ref.watch(challengeCatalogProvider);
    final all = catalog.valueOrNull ?? const <Challenge>[];
    final shown = ref.watch(challengeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.challengesTitle),
        actions: [
          IconButton(
            tooltip: l.actionRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshAll(ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // Header lives outside the async switch: a keystroke must never take
          // the field the user is typing in out of the tree.
          TextField(
            controller: _search,
            autocorrect: false,
            textInputAction: TextInputAction.search,
            onChanged: (v) =>
                ref.read(challengeQueryProvider.notifier).state = v,
            decoration: InputDecoration(
              hintText: l.challengeSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        ref.read(challengeQueryProvider.notifier).state = '';
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          _Sorts(sort: sort),
          const SizedBox(height: 10),
          _Filters(filter: filter, all: all),
          const SizedBox(height: 14),
          if (catalog.isLoading)
            const SkeletonList(rows: 8)
          else if (catalog.hasError)
            ErrorView(
                error: catalog.error!,
                onRetry: () => ref.invalidate(challengeCatalogProvider))
          else if (shown.isEmpty)
            NotFoundCard(message: l.challengeEmpty)
          else
            for (final c in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ChallengeRow(challenge: c),
              ),
          const SizedBox(height: 8),
          Text(l.challengeRulesNote,
              style: const TextStyle(
                  fontSize: 11, color: RaColors.muted, height: 1.4)),
        ],
      ),
    );
  }
}

class _Sorts extends ConsumerWidget {
  const _Sorts({required this.sort});
  final ChallengeSort sort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);

    Widget chip(ChallengeSort value, String label, IconData icon) => ChoiceChip(
          selected: sort == value,
          avatar: Icon(icon,
              size: 15,
              color: sort == value ? RaColors.achievements : RaColors.muted),
          label: Text(label, style: const TextStyle(fontSize: 12)),
          showCheckmark: false,
          backgroundColor: RaColors.surface,
          selectedColor: RaColors.achievements.withValues(alpha: 0.18),
          side: BorderSide(
              color: sort == value ? RaColors.achievements : RaColors.border),
          onSelected: (_) =>
              ref.read(challengeSortProvider.notifier).state = value,
        );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(ChallengeSort.closest, l.challengeSortClosest, Icons.flag_outlined),
        chip(ChallengeSort.recent, l.challengeSortRecent, Icons.schedule),
        chip(ChallengeSort.biggest, l.challengeSortBiggest, Icons.layers_outlined),
      ],
    );
  }
}

class _Filters extends ConsumerWidget {
  const _Filters({required this.filter, required this.all});

  final ChallengeFilter filter;
  final List<Challenge> all;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);

    Widget chip(ChallengeFilter value, String label) {
      // The count is the size of that bucket, so the tabs are self-explaining.
      final count = filterChallenges(all, value).length;
      return ChoiceChip(
        selected: filter == value,
        label: Text('$label $count', style: const TextStyle(fontSize: 12)),
        showCheckmark: false,
        backgroundColor: RaColors.surface,
        selectedColor: RaColors.achievements.withValues(alpha: 0.18),
        side: BorderSide(
            color: filter == value ? RaColors.achievements : RaColors.border),
        onSelected: (_) =>
            ref.read(challengeFilterProvider.notifier).state = value,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(ChallengeFilter.all, l.challengeFilterAll),
        chip(ChallengeFilter.inProgress, l.challengeFilterInProgress),
        chip(ChallengeFilter.notStarted, l.challengeFilterNotStarted),
        chip(ChallengeFilter.completed, l.challengeFilterCompleted),
      ],
    );
  }
}

/// Shared with the dashboard card so both read identically.
class ChallengeRow extends StatelessWidget {
  const ChallengeRow({super.key, required this.challenge, this.dense = false});

  final Challenge challenge;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = challenge;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChallengeDetailPage(challenge: c),
        ),
      ),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: dense ? 6 : 8),
        child: Row(
          children: [
            GameIcon(c.iconUrl, size: dense ? 34 : 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(
                    c.started
                        ? l.challengeProgress(c.earned, c.totalAchievements)
                        : '${l.challengeNotStarted} · '
                            '${l.challengeProgress(0, c.totalAchievements)}',
                    style: const TextStyle(
                        fontSize: 11.5, color: RaColors.muted),
                  ),
                  const SizedBox(height: 6),
                  ProgressBar(
                    value: c.progress,
                    color: c.completed ? RaColors.mastered : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (c.completed)
                  const Text('👑', style: TextStyle(fontSize: 14))
                else
                  Text('${c.percent}%',
                      style: const TextStyle(
                          fontSize: 11, color: RaColors.muted)),
                // Rarity of what the user unlocked here. The catalogue carries
                // none, so untouched events simply have nothing to show.
                if (c.rarityTier != null) ...[
                  const SizedBox(height: 4),
                  RarityChip(
                    tier: c.rarityTier!,
                    text: 'x${c.earnedRarity!.toStringAsFixed(1)}',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
