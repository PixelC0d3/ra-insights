/// The "Jogos" tab: recent games and per-console progression used to be two
/// separate tabs answering the same question — "find one of my games". A
/// segmented control switches between the two bodies instead.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../progression/progression_page.dart';
import '../recent/recent_games_page.dart';
import '../search/search_page.dart';

enum _GamesSegment { recent, byConsole }

class GamesPage extends ConsumerStatefulWidget {
  const GamesPage({super.key});

  @override
  ConsumerState<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends ConsumerState<GamesPage> {
  var _segment = _GamesSegment.recent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navGames),
        actions: [
          // "Find a game" belongs here, not on the Início tab.
          IconButton(
            tooltip: l.actionSearch,
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SearchPage()),
            ),
          ),
          IconButton(
            tooltip: l.actionRefresh,
            icon: const Icon(Icons.refresh),
            // Whole-app refresh: the two segments come from different
            // providers (recentGamesPageProvider vs progressionProvider) and
            // this button does not know which one is on screen.
            onPressed: () => refreshAll(ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: SegmentedButton<_GamesSegment>(
              segments: [
                ButtonSegment(
                  value: _GamesSegment.recent,
                  label: Text(l.gamesTabRecent),
                  icon: const Icon(Icons.history, size: 16),
                ),
                ButtonSegment(
                  value: _GamesSegment.byConsole,
                  label: Text(l.gamesTabByConsole),
                  icon: const Icon(Icons.donut_large, size: 16),
                ),
              ],
              selected: {_segment},
              onSelectionChanged: (s) => setState(() => _segment = s.first),
            ),
          ),
          Expanded(
            // IndexedStack keeps both bodies alive: switching segments does
            // not lose scroll position or re-trigger a load.
            child: IndexedStack(
              index: _segment.index,
              children: const [RecentGamesBody(), ProgressionBody()],
            ),
          ),
        ],
      ),
    );
  }
}
