/// First frame after launch: the logo, while the profile warms up behind it.
///
/// It stays up for a minimum beat so the app never flashes, and no longer than
/// [_maxWait] so a dead connection cannot trap the user here — the screens
/// behind it all render from cache anyway.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/gen/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: RaColors.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // A slow sweep of colour behind the shield, so the dark screen is not
          // dead while the network is working.
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) => CustomPaint(
              size: MediaQuery.sizeOf(context),
              painter: _GlowPainter(_c.value),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (_, child) {
                  // One gentle breath per cycle: 1.0 → 1.06 → 1.0.
                  final t = math.sin(_c.value * 2 * math.pi);
                  return Transform.scale(scale: 1 + t * 0.03, child: child);
                },
                child: Image.asset('assets/branding/logo.png',
                    width: 132, height: 132, filterQuality: FilterQuality.medium),
              ),
              const SizedBox(height: 22),
              const Text('RA Insights',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Text(l.splashTagline,
                  style:
                      const TextStyle(fontSize: 12.5, color: RaColors.muted)),
              const SizedBox(height: 26),
              SizedBox(
                width: 132,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: const LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor: RaColors.surfaceAlt,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Two soft radial washes drifting in opposite directions.
class _GlowPainter extends CustomPainter {
  const _GlowPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final angle = t * 2 * math.pi;
    final radius = size.shortestSide * 0.62;

    void wash(Color color, Offset centre) {
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: 0.20), Colors.transparent],
          ).createShader(Rect.fromCircle(center: centre, radius: radius)),
      );
    }

    final middle = size.center(Offset.zero);
    wash(RaColors.achievements,
        middle + Offset(math.cos(angle) * 70, math.sin(angle) * 90 - 60));
    wash(RaColors.points,
        middle - Offset(math.cos(angle) * 80, math.sin(angle) * 70 - 40));
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.t != t;
}
