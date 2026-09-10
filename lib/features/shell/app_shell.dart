import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.index, required this.onSelect});

  final Widget child;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onSelect,
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: const Icon(Icons.insights),
              label: l.navInsights),
          NavigationDestination(
              icon: const Icon(Icons.videogame_asset_outlined),
              selectedIcon: const Icon(Icons.videogame_asset),
              label: l.navGames),
          NavigationDestination(
              icon: const Icon(Icons.emoji_events_outlined),
              selectedIcon: const Icon(Icons.emoji_events),
              label: l.navChallenges),
          NavigationDestination(
              icon: const Icon(Icons.account_circle_outlined),
              selectedIcon: const Icon(Icons.account_circle),
              label: l.navProfile),
        ],
      ),
    );
  }
}
