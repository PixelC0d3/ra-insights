/// Design system: cards, skeletons, empty and error states.
library;

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/result.dart';
import '../domain/insights/rarity.dart';
import '../l10n/gen/app_localizations.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
    this.onTap,
  });

  final String title;
  final Widget child;
  final String? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Text(icon!, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                  if (onTap != null)
                    const Icon(Icons.chevron_right,
                        size: 18, color: RaColors.muted),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.height = 14, this.width, this.radius = 6});

  final double height;
  final double? width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.75).animate(_c),
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: RaColors.surfaceAlt,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 3});
  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        rows,
        (i) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Skeleton(height: 34, width: 34, radius: 8),
              SizedBox(width: 10),
              Expanded(child: Skeleton()),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final kind = error is AppError ? (error as AppError).kind : null;

    // "Not found" is an empty result, not a failure — it gets the same card as
    // any other empty list.
    if (kind == AppErrorKind.notFound) {
      return NotFoundCard(message: l.errorNotFound, onRetry: onRetry);
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 32, color: RaColors.muted),
          const SizedBox(height: 12),
          Text(localizedError(l, error),
              textAlign: TextAlign.center,
              style: const TextStyle(color: RaColors.muted, fontSize: 13)),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l.actionRetry),
            ),
          ],
        ],
      ),
    );
  }
}

/// The single place that turns an [AppErrorKind] into user-facing copy.
String localizedError(AppLocalizations l, Object error) {
  if (error is! AppError) return error.toString();
  return switch (error.kind) {
    AppErrorKind.unauthorized => l.errorUnauthorized,
    AppErrorKind.notFound => l.errorNotFound,
    AppErrorKind.network => l.errorNetwork,
    AppErrorKind.rateLimited => l.errorRateLimited,
    AppErrorKind.parse => l.errorParse,
    AppErrorKind.unknown => error.message,
  };
}

/// Shown wherever a tap led somewhere with no results. Standalone card, so it
/// reads as an answer rather than as a blank screen.
class NotFoundCard extends StatelessWidget {
  const NotFoundCard({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 34, color: RaColors.muted),
              const SizedBox(height: 12),
              Text(l.notFoundTitle,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(message,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 12.5, color: RaColors.muted)),
              if (onRetry != null) ...[
                const SizedBox(height: 14),
                FilledButton.tonalIcon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l.actionRetry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.search_off, size: 15, color: RaColors.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: RaColors.muted, fontSize: 12.5, height: 1.35)),
            ),
          ],
        ),
      );
}

/// "updated X ago" — the offline-first receipt.
String relativeTime(BuildContext context, DateTime? when) {
  final l = AppLocalizations.of(context);
  if (when == null) return l.updatedNever;
  final diff = DateTime.now().difference(when);
  if (diff.inSeconds < 60) return l.updatedNow;
  if (diff.inMinutes < 60) return l.updatedMinutes(diff.inMinutes);
  if (diff.inHours < 24) return l.updatedHours(diff.inHours);
  return l.updatedDays(diff.inDays);
}

String rarityLabel(AppLocalizations l, RarityTier tier) => switch (tier) {
      RarityTier.common => l.rarityCommon,
      RarityTier.uncommon => l.rarityUncommon,
      RarityTier.rare => l.rarityRare,
      RarityTier.veryRare => l.rarityVeryRare,
      RarityTier.ultraRare => l.rarityUltraRare,
    };

/// The one rarity pill, used everywhere an achievement is listed. [text] is
/// the unlock rate where it is known and the TrueRatio multiplier where it is
/// not, so the colour always means the same thing even when the number does not.
class RarityChip extends StatelessWidget {
  const RarityChip({super.key, required this.tier, required this.text});

  final RarityTier tier;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = rarityColor(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.color});

  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          minHeight: 6,
          backgroundColor: RaColors.surfaceAlt,
          valueColor:
              AlwaysStoppedAnimation(color ?? RaColors.achievements),
        ),
      );
}

class GameIcon extends StatelessWidget {
  const GameIcon(this.url, {super.key, this.size = 38, this.radius = 8});

  final String url;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url.isEmpty
          ? Container(width: size, height: size, color: RaColors.surfaceAlt)
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: size,
                height: size,
                color: RaColors.surfaceAlt,
                child: const Icon(Icons.videogame_asset,
                    size: 18, color: RaColors.muted),
              ),
            ),
    );
  }
}
