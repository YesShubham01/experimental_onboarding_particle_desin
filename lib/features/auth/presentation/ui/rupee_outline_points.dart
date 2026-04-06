import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// True if pixel is opaque and touches transparent or out-of-bounds (outline).
bool isGlyphEdgePixel(int x, int y, Uint8List pixels, int w, int h) {
  int alphaAt(int cx, int cy) {
    if (cx < 0 || cy < 0 || cx >= w || cy >= h) return 0;
    final idx = (cy * w + cx) * 4;
    if (idx + 3 >= pixels.length) return 0;
    return pixels[idx + 3];
  }

  if (alphaAt(x, y) < 128) return false;

  for (var dy = -1; dy <= 1; dy++) {
    for (var dx = -1; dx <= 1; dx++) {
      if (dx == 0 && dy == 0) continue;
      if (alphaAt(x + dx, y + dy) < 128) return true;
    }
  }
  return false;
}

/// Rasterize ₹, keep only edge pixels, return normalized (0–1) points in image space.
Future<List<Offset>> generateRupeeOutlinePoints({
  double fontSize = 220,
  FontWeight fontWeight = FontWeight.bold,
  int sampleStep = 6,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final textPainter = TextPainter(
    text: TextSpan(
      text: '₹',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: const Color(0xFFFFFFFF),
      ),
    ),
    textDirection: TextDirection.ltr,
  );

  textPainter.layout();
  textPainter.paint(canvas, Offset.zero);

  final w = textPainter.width.ceil().clamp(1, 4096);
  final h = textPainter.height.ceil().clamp(1, 4096);
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  picture.dispose();

  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  if (byteData == null) return const [];

  final pixels = byteData.buffer.asUint8List();
  final raw = <Offset>[];

  for (var y = 0; y < h; y += sampleStep) {
    for (var x = 0; x < w; x += sampleStep) {
      if ((x + y).isOdd) continue;
      if (isGlyphEdgePixel(x, y, pixels, w, h)) {
        raw.add(Offset(x / w, y / h));
      }
    }
  }

  return normalizeRupeePoints(raw, margin: 0.4);
}

List<Offset> normalizeRupeePoints(List<Offset> raw, {double margin = 0.4}) {
  if (raw.isEmpty) return raw;

  var minX = double.infinity;
  var maxX = double.negativeInfinity;
  var minY = double.infinity;
  var maxY = double.negativeInfinity;
  for (final p in raw) {
    minX = math.min(minX, p.dx);
    maxX = math.max(maxX, p.dx);
    minY = math.min(minY, p.dy);
    maxY = math.max(maxY, p.dy);
  }

  final bw = (maxX - minX).clamp(1e-6, 1.0);
  final bh = (maxY - minY).clamp(1e-6, 1.0);
  final side = math.max(bw, bh);

  return raw
      .map(
        (p) => Offset(
          0.5 + ((p.dx - minX) - bw / 2) / side * margin,
          0.5 + ((p.dy - minY) - bh / 2) / side * margin,
        ),
      )
      .toList();
}
