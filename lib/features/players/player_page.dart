/// Another player: stats side by side with yours, their wall, and messaging.
///
/// The Web API is read-only for social features — there is no endpoint to send
/// a message or post a comment — so composing opens the RetroAchievements site.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/ui.dart';
import '../profile/wall_section.dart';

class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key, required this.username});
  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(playerProvider(username));
    final me = ref.watch(dashboardProvider).valueOrNull?.summary;

    return Scaffold(
      appBar: AppBar(title: Text(username)),
      body: async.when(
        loading: () => const Padding(
            padding: EdgeInsets.all(16), child: SkeletonList(rows: 6)),
        error: (e, _) => ErrorView(
            error: e, onRetry: () => ref.invalidate(playerProvider(username))),
        data: (player) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _PlayerHeader(player: player),
            const SizedBox(height: 14),
            _MessageActions(username: player.profile.user),
            const SizedBox(height: 14),
            _Comparison(player: player, me: me),
            const SizedBox(height: 14),
            SectionCard(
              title: AppLocalizations.of(context).sectionWall,
              icon: '📝',
              child: WallComments(comments: player.comments),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader({required this.player});
  final PlayerView player;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = player.profile;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GameIcon(p.avatarUrl, size: 56, radius: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.user,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    l.playerPointsRank(p.totalPoints) +
                        (p.rank != null ? l.playerRankSuffix(p.rank!) : ''),
                    style: const TextStyle(fontSize: 12, color: RaColors.muted),
                  ),
                  if (p.memberSince != null)
                    Text(l.playerMemberSinceYear(p.memberSince!.year),
                        style: const TextStyle(
                            fontSize: 11.5, color: RaColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageActions extends StatelessWidget {
  const _MessageActions({required this.username});
  final String username;

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      title: l.sectionMessage,
      icon: '💬',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.messageHelp,
            style: const TextStyle(
                fontSize: 12, color: RaColors.muted, height: 1.4),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _open(
                'https://retroachievements.org/messages/create?to=$username'),
            icon: const Icon(Icons.send, size: 18),
            label: Text(l.sendMessage),
          ),
          const SizedBox(height: 8),
          // The Web API has no follow endpoint (verified against every
          // API_* call this app makes — there is none for it), so this opens
          // the profile page on the site, where the real follow button lives.
          OutlinedButton.icon(
            onPressed: () => _open('https://retroachievements.org/user/$username'),
            icon: const Icon(Icons.person_add_alt, size: 18),
            label: Text(l.followPlayer),
          ),
          const SizedBox(height: 6),
          Text(
            l.followHelp,
            style: const TextStyle(fontSize: 11, color: RaColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Comparison extends StatelessWidget {
  const _Comparison({required this.player, required this.me});
  final PlayerView player;
  final UserSummary? me;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (me == null) {
      return SectionCard(
        title: l.sectionComparison,
        icon: '⚖️',
        child: EmptyView(l.comparisonNeedsDashboard),
      );
    }

    final them = player.summary;
    final myPoints = me!.totalPoints;
    final theirPoints = them?.totalPoints ?? player.profile.totalPoints;
    final diff = myPoints - theirPoints;

    return SectionCard(
      title: l.sectionComparison,
      icon: '⚖️',
      child: Column(
        children: [
          _Row(
            label: l.comparePoints,
            mine: formatThousands(context, myPoints),
            theirs: formatThousands(context, theirPoints),
            mineWins: myPoints >= theirPoints,
          ),
          const SizedBox(height: 10),
          _Row(
            label: l.compareRank,
            mine: me!.rank == null ? '—' : formatThousands(context, me!.rank!),
            theirs: switch (them?.rank ?? player.profile.rank) {
              final int rank => formatThousands(context, rank),
              null => '—',
            },
            // Lower rank is better.
            mineWins: (me!.rank ?? 1 << 30) <=
                ((them?.rank ?? player.profile.rank) ?? 1 << 30),
          ),
          const SizedBox(height: 12),
          Text(
            diff == 0
                ? l.compareTie
                : diff > 0
                    ? l.compareAhead(diff)
                    : l.compareBehind(-diff),
            style: const TextStyle(fontSize: 12, color: RaColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.mine,
    required this.theirs,
    required this.mineWins,
  });

  final String label;
  final String mine;
  final String theirs;
  final bool mineWins;

  @override
  Widget build(BuildContext context) {
    const win = TextStyle(
        fontSize: 14, fontWeight: FontWeight.w700, color: RaColors.mastered);
    const lose = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

    return Row(
      children: [
        Expanded(
          child: Text(mine,
              textAlign: TextAlign.start, style: mineWins ? win : lose),
        ),
        Text(label,
            style: const TextStyle(fontSize: 11.5, color: RaColors.muted)),
        Expanded(
          child: Text(theirs,
              textAlign: TextAlign.end, style: mineWins ? lose : win),
        ),
      ],
    );
  }
}

