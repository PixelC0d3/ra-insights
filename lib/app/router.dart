/// go_router with a StatefulShellRoute for the bottom nav; deep links land on
/// the tab that owns them.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/challenges/challenges_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/games/games_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/profile/profile_page.dart';
import '../features/shell/app_shell.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      if (session.isLoading) return null;
      final signedIn = session.valueOrNull != null;
      final onboarding = state.matchedLocation == '/onboarding';
      if (!signedIn) return onboarding ? null : '/onboarding';
      if (onboarding) return '/dashboard';
      return null;
    },
    refreshListenable: _SessionListenable(ref),
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(
          index: shell.currentIndex,
          onSelect: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          child: shell,
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
          ]),
          // Recent games and per-console progression merged into one tab —
          // they were two answers to the same question ("find one of my
          // games"). See GamesPage.
          StatefulShellBranch(routes: [
            GoRoute(path: '/games', builder: (_, __) => const GamesPage()),
          ]),
          // Promoted from a dashboard card: it has more surface (search, sort,
          // four filters, a detail page and a plan generator) than either tab
          // it replaces here ever had.
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/challenges', builder: (_, __) => const ChallengesPage()),
          ]),
          // Search and settings are pushed over the shell; activity (the
          // heatmap) is reachable from a section inside the profile instead of
          // owning a tab — it describes the player, it isn't a place to act.
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
          ]),
        ],
      ),
    ],
  );
});

/// Bridges the session provider to go_router's refresh mechanism.
class _SessionListenable extends ChangeNotifier {
  _SessionListenable(Ref ref) {
    ref.listen(sessionProvider, (_, __) => notifyListeners());
  }
}
