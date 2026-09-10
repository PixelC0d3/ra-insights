/// The 365-cell grid, painted by hand — 365 widgets would not hold 60fps on a
/// low-end device.
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../domain/insights/heatmap.dart';

const double kCellSize = 13;
const double kCellGap = 3;
const double kLabelColumn = 26;
const double kMonthRow = 16;

Color heatmapColor(HeatmapMode? mode, int level) {
  if (level <= 0) return const Color(0xFF1B1B22);
  final base = switch (mode) {
    HeatmapMode.mastered => RaColors.mastered,
    HeatmapMode.beaten => RaColors.beaten,
    _ => RaColors.achievements,
  };
  final alpha = switch (level) {
    1 => 0.28,
    2 => 0.5,
    3 => 0.75,
    _ => 1.0,
  };
  return base.withValues(alpha: alpha);
}

class HeatmapPainter extends CustomPainter {
  HeatmapPainter({required this.grid, required this.selectedDay});

  final HeatmapGrid grid;
  final String? selectedDay;

  static const _months = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];
  static const _weekdays = ['', 'seg', '', 'qua', '', 'sex', ''];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final step = kCellSize + kCellGap;

    for (var i = 0; i < _weekdays.length; i++) {
      if (_weekdays[i].isEmpty) continue;
      _text(canvas, _weekdays[i], Offset(0, kMonthRow + i * step + 1), 8.5);
    }

    for (final label in grid.monthLabels) {
      _text(canvas, _months[label.month - 1],
          Offset(kLabelColumn + label.week * step, 0), 9);
    }

    for (final cell in grid.cells) {
      final rect = Rect.fromLTWH(
        kLabelColumn + cell.week * step,
        kMonthRow + cell.weekday * step,
        kCellSize,
        kCellSize,
      );
      paint.color = heatmapColor(cell.source, cell.level);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2.5)), paint);

      if (cell.dayKey == selectedDay) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(1.5), const Radius.circular(3.5)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.white,
        );
      }
    }
  }

  void _text(Canvas canvas, String value, Offset at, double size) {
    TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(fontSize: size, color: RaColors.muted),
      ),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas, at);
  }

  static Size sizeFor(HeatmapGrid grid) => Size(
        kLabelColumn + grid.weeks * (kCellSize + kCellGap),
        kMonthRow + 7 * (kCellSize + kCellGap),
      );

  /// Maps a tap to a cell, or null when it lands on a gap.
  static HeatmapCell? cellAt(HeatmapGrid grid, Offset local) {
    final step = kCellSize + kCellGap;
    final week = ((local.dx - kLabelColumn) / step).floor();
    final dow = ((local.dy - kMonthRow) / step).floor();
    if (week < 0 || dow < 0 || dow > 6) return null;
    for (final c in grid.cells) {
      if (c.week == week && c.weekday == dow) return c;
    }
    return null;
  }

  @override
  bool shouldRepaint(HeatmapPainter old) =>
      old.grid != grid || old.selectedDay != selectedDay;
}
