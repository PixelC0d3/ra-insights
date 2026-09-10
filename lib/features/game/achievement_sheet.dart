/// One achievement, in detail. Shared by every list that shows achievements so
/// a tap always lands on the same thing.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../domain/insights/rarity.dart';
import '../../domain/models/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/ui.dart';

void showAchievementSheet(
  BuildContext context,
  GameProgress game,
  GameAchievement a,
) {
  final l = AppLocalizations.of(context);
  final rate = game.unlockRate(a);
  final tier = rarityOf(game, a);

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: RaColors.surface,
    useSafeArea: true,
    isScrollControlled: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.8,
    ),
    builder: (_) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GameIcon(a.isEarned ? a.badgeUrl : a.lockedBadgeUrl, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      l.badgePointsAndRatio(a.points, a.trueRatio),
                      style: const TextStyle(
                          fontSize: 12, color: RaColors.muted),
                    ),
                    if (tier != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          RarityChip(
                            tier: tier,
                            text: rate != null
                                ? formatPercent(context, rate)
                                : 'x${a.rarityMultiplier!.toStringAsFixed(1)}',
                          ),
                          Text(
                            rate != null
                                ? '${rarityLabel(l, tier)} · '
                                    '${l.rarityOfPlayers(formatPercent(context, rate))}'
                                : '${rarityLabel(l, tier)} · '
                                    '${l.rarityEstimated}',
                            style: const TextStyle(
                                fontSize: 11, color: RaColors.muted),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(a.description,
              style: const TextStyle(fontSize: 13, height: 1.35)),
          const SizedBox(height: 12),
          Text(
            a.isEarned
                ? l.badgeUnlockedOn(formatLongDate(context, a.earnedAt!)) +
                    (a.isHardcore ? l.badgeHardcoreSuffix : '')
                : l.badgeStillLocked,
            style: TextStyle(
              fontSize: 12,
              color: a.isEarned ? RaColors.mastered : RaColors.muted,
            ),
          ),
          // Flags the site shows as icons; spelled out here where there is room.
          if (a.type.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(a.type,
                style: const TextStyle(fontSize: 11, color: RaColors.muted)),
          ],
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => launchUrl(
              Uri.parse('https://retroachievements.org/achievement/${a.id}'),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(l.achievementOpenOnSite),
          ),
        ],
      ),
    ),
  );
}
