/// Per-console progression — list and bars, never a treemap on a phone.
///
/// [ProgressionBody] is the content only (no Scaffold/AppBar) — it is the
/// other segment of the merged "Jogos" tab; see GamesPage.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/insights/progression.dart';
import '../../domain/models/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';
import '../game/game_page.dart';

class ProgressionBody extends ConsumerWidget {
  const ProgressionBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(progressionProvider);
    final filter = ref.watch(progressionFilterProvider);

    return RefreshIndicator(
      onRefresh: () => refreshAll(ref),
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonList(rows: 6),
        ),
        error: (e, _) => ListView(children: [
          const SizedBox(height: 80),
          ErrorView(error: e, onRetry: () => ref.invalidate(progressionProvider)),
        ]),
        data: (entries) {
          final breakdown = computeProgression(entries);
          final consoles = applyProgressionFilter(breakdown.consoles, filter);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _Totals(breakdown: breakdown),
              const SizedBox(height: 12),
              _Filters(filter: filter),
              const SizedBox(height: 12),
              if (consoles.isEmpty)
                NotFoundCard(message: l.emptyConsoles)
              else
                for (final c in consoles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ConsoleRow(
                      console: c,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ConsoleGamesPage(
                            consoleId: c.consoleId,
                            consoleName: c.consoleName,
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.breakdown});
  final ProgressionBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Metric('${breakdown.totalGames}', l.metricGames, Colors.white),
            _Metric('${breakdown.totalMastered}', l.metricMastered,
                RaColors.mastered),
            _Metric('${breakdown.totalBeaten}', l.metricBeaten, RaColors.beaten),
            _Metric('${breakdown.masteryRatePercent}%', l.metricRate,
                RaColors.achievements),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: RaColors.muted)),
        ],
      );
}

class _Filters extends ConsumerWidget {
  const _Filters({required this.filter});
  final ProgressionFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget chip(ProgressionFilter value, String label) => ChoiceChip(
          selected: filter == value,
          label: Text(label, style: const TextStyle(fontSize: 12)),
          showCheckmark: false,
          backgroundColor: RaColors.surface,
          selectedColor: RaColors.achievements.withValues(alpha: 0.18),
          side: BorderSide(
              color: filter == value ? RaColors.achievements : RaColors.border),
          onSelected: (_) =>
              ref.read(progressionFilterProvider.notifier).state = value,
        );

    final l = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      children: [
        chip(ProgressionFilter.all, l.filterAll),
        chip(ProgressionFilter.withProgress, l.filterWithProgress),
        chip(ProgressionFilter.mastered, l.filterMastered),
      ],
    );
  }
}

class _ConsoleRow extends StatelessWidget {
  const _ConsoleRow({required this.console, required this.onTap});
  final ConsoleProgress console;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final total = console.total;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(console.consoleName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600)),
                  ),
                  Text(l.consoleGameCount(total),
                      style: const TextStyle(
                          fontSize: 11.5, color: RaColors.muted)),
                  const Icon(Icons.chevron_right,
                      size: 18, color: RaColors.muted),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 7,
                  child: Row(
                    children: [
                      if (console.mastered > 0)
                        Expanded(
                            flex: console.mastered,
                            child: Container(color: RaColors.mastered)),
                      if (console.beaten > 0)
                        Expanded(
                            flex: console.beaten,
                            child: Container(color: RaColors.beaten)),
                      if (console.unfinished > 0)
                        Expanded(
                            flex: console.unfinished,
                            child: Container(color: RaColors.surfaceAlt)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.consoleBreakdown(
                    console.mastered, console.beaten, console.unfinished),
                style: const TextStyle(fontSize: 11, color: RaColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Drill-down: console → games of that console.
class ConsoleGamesPage extends ConsumerWidget {
  const ConsoleGamesPage({
    super.key,
    required this.consoleId,
    required this.consoleName,
  });

  final int consoleId;
  final String consoleName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(progressionProvider);
    final filter = ref.watch(progressionFilterProvider);

    return Scaffold(
      appBar: AppBar(title: Text(consoleName)),
      body: async.when(
        loading: () =>
            const Padding(padding: EdgeInsets.all(16), child: SkeletonList(rows: 6)),
        error: (e, _) => ErrorView(error: e),
        data: (entries) {
          final games = filterConsoleGames(
            entries.where((e) => e.consoleId == consoleId).toList(),
            filter,
          )..sort((a, b) => b.progress.compareTo(a.progress));

          if (games.isEmpty) {
            return Center(
                child: NotFoundCard(
                    message: AppLocalizations.of(context).emptyConsoleGames));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: games.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _GameRow(entry: games[i]),
          );
        },
      ),
    );
  }
}

class _GameRow extends StatelessWidget {
  const _GameRow({required this.entry});
  final CompletionEntry entry;

  @override
  Widget build(BuildContext context) {
    final kind = entry.highestAwardKind;
    final color = kind == null
        ? RaColors.achievements
        : kind.isMastery
            ? RaColors.mastered
            : RaColors.beaten;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              GamePage(gameId: entry.gameId, fallbackTitle: entry.title),
        ),
      ),
      borderRadius: BorderRadius.circular(10),
      child: Row(
      children: [
        GameIcon(entry.iconUrl),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(
                '${entry.earned}/${entry.maxPossible}'
                '${kind != null ? ' · ${kind.label}' : ''}',
                style: const TextStyle(fontSize: 11.5, color: RaColors.muted),
              ),
              const SizedBox(height: 6),
              ProgressBar(value: entry.progress, color: color),
            ],
          ),
        ),
        ],
      ),
    );
  }
}
