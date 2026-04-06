import 'dart:math' show min;

import 'package:flutter/material.dart';

import 'rupee_path.dart';

/// Paints ₹ stroke up to [progress] (0–1) along total path length, optional soft glow.
void paintRupeeStrokeProgress(
  Canvas canvas,
  Size size,
  double progress, {
  required Color color,
  double strokeWidth = 3,
  bool drawGlow = true,
}) {
  final path = buildRupeePath(size);
  final metrics = path.computeMetrics().toList();

  var total = 0.0;
  for (final m in metrics) {
    total += m.length;
  }
  if (total <= 0) return;

  final glowPaint = drawGlow
      ? (Paint()
          ..color = color.withValues(alpha: 0.2)
          ..strokeWidth = strokeWidth + 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3))
      : null;

  final mainPaint = Paint()
    ..color = color
    ..strokeWidth = strokeWidth
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  var budget = progress.clamp(0.0, 1.0) * total;
  for (final m in metrics) {
    if (budget <= 0) break;
    final len = m.length;
    final drawLen = len > 0 ? min(len, budget) : 0.0;
    if (drawLen > 0) {
      final extract = m.extractPath(0, drawLen);
      if (glowPaint != null) {
        canvas.drawPath(extract, glowPaint);
      }
      canvas.drawPath(extract, mainPaint);
    }
    budget -= len;
  }
}

/// Stroke-only painter (e.g. previews).
class RupeeStrokePainter extends CustomPainter {
  RupeeStrokePainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 3,
    this.drawGlow = true,
  });

  final double progress;
  final Color color;
  final double strokeWidth;
  final bool drawGlow;

  @override
  void paint(Canvas canvas, Size size) {
    paintRupeeStrokeProgress(
      canvas,
      size,
      progress,
      color: color,
      strokeWidth: strokeWidth,
      drawGlow: drawGlow,
    );
  }

  @override
  bool shouldRepaint(covariant RupeeStrokePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.drawGlow != drawGlow;
  }
}
