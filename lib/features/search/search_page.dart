/// Search. Two indexes: the games the user has played (local, offline) and
/// players by exact username (the API has no user search either).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';
import '../game/game_page.dart';
import '../players/player_page.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.searchTitle),
        bottom: TabBar(
          controller: _tabs,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: l.searchTabGames),
            Tab(text: l.searchTabPlayers),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_GameSearchTab(), _PlayerSearchTab()],
      ),
    );
  }
}

class _GameSearchTab extends ConsumerStatefulWidget {
  const _GameSearchTab();

  @override
  ConsumerState<_GameSearchTab> createState() => _GameSearchTabState();
}

class _GameSearchTabState extends ConsumerState<_GameSearchTab> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(gameSearchQueryProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final query = ref.watch(gameSearchQueryProvider);
    final async = ref.watch(gameSearchProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _controller,
            autocorrect: false,
            textInputAction: TextInputAction.search,
            onChanged: (v) =>
                ref.read(gameSearchQueryProvider.notifier).state = v,
            decoration: InputDecoration(
              hintText: l.searchGameHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        ref.read(gameSearchQueryProvider.notifier).state = '';
                      },
                    ),
            ),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(16), child: SkeletonList(rows: 5)),
            error: (e, _) => ErrorView(error: e),
            data: (games) {
              if (query.trim().isEmpty) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    l.searchGameHelp,
                    style: const TextStyle(
                        fontSize: 12.5, color: RaColors.muted, height: 1.4),
                  ),
                );
              }
              if (games.isEmpty) {
                return SingleChildScrollView(
                    child: NotFoundCard(message: l.searchGameEmpty));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                itemCount: games.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _GameResult(entry: games[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GameResult extends StatelessWidget {
  const _GameResult({required this.entry});
  final CompletionEntry entry;

  @override
  Widget build(BuildContext context) {
    final kind = entry.highestAwardKind;
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
                  '${entry.consoleName} · ${entry.earned}/${entry.maxPossible}'
                  '${kind != null ? ' · ${kind.label}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: RaColors.muted),
                ),
                const SizedBox(height: 6),
                ProgressBar(
                  value: entry.progress,
                  color: kind != null && kind.isMastery
                      ? RaColors.mastered
                      : RaColors.achievements,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerSearchTab extends ConsumerStatefulWidget {
  const _PlayerSearchTab();

  @override
  ConsumerState<_PlayerSearchTab> createState() => _PlayerSearchTabState();
}

class _PlayerSearchTabState extends ConsumerState<_PlayerSearchTab> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(String user) {
    final name = user.trim();
    if (name.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlayerPage(username: name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        TextField(
          controller: _controller,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.search,
          onSubmitted: _open,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).searchPlayerHint,
            prefixIcon: const Icon(Icons.person_search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => _open(_controller.text),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context).searchPlayerHelp,
          style: const TextStyle(
              fontSize: 12.5, color: RaColors.muted, height: 1.4),
        ),
      ],
    );
  }
}
