import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Particle that eases onto a stroke sample.
class StrokeParticle {
  StrokeParticle({required this.position, required this.target});

  Offset position;
  final Offset target;

  void update(double easedT) {
    final toTarget = target - position;
    final k = 0.06 + 0.2 * easedT;
    position += toTarget * k;
  }
}

/// Distributes [totalSamples] along all path contours by segment length.
List<Offset> samplePath(Path path, int totalSamples) {
  final metrics = path.computeMetrics().toList();
  if (metrics.isEmpty || totalSamples <= 0) return [];

  var totalLength = 0.0;
  for (final m in metrics) {
    totalLength += m.length;
  }
  if (totalLength <= 0) return [];

  final out = <Offset>[];

  for (final m in metrics) {
    if (m.length <= 0) continue;
    final n = math.max(2, (totalSamples * m.length / totalLength).round());
    for (var i = 0; i < n; i++) {
      final t = n <= 1 ? 0.0 : i / (n - 1);
      final tangent = m.getTangentForOffset(m.length * t);
      if (tangent != null) out.add(tangent.position);
    }
  }

  if (out.length <= totalSamples) return out;

  final stride = out.length / totalSamples;
  final trimmed = <Offset>[];
  for (var i = 0; i < totalSamples; i++) {
    trimmed.add(out[(i * stride).floor().clamp(0, out.length - 1)]);
  }
  return trimmed;
}
