import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_parsing/path_parsing.dart';

/// Vector-accurate ₹ from SVG `d` (≈24×24 artboard).
///
/// Parsed with [path_parsing] (same SVG path grammar used by `flutter_svg`).
const String kRupeeSymbolSvgPathData =
    'M12.9494914,6 C13.4853936,6.52514205 13.8531598,7.2212202 13.9645556,8 L17.5,8 '
    'C17.7761424,8 18,8.22385763 18,8.5 C18,8.77614237 17.7761424,9 17.5,9 L13.9645556,9 '
    'C13.7219407,10.6961471 12.263236,12 10.5,12 L7.70710678,12 L13.8535534,18.1464466 '
    'C14.0488155,18.3417088 14.0488155,18.6582912 13.8535534,18.8535534 C13.6582912,19.0488155 '
    '13.3417088,19.0488155 13.1464466,18.8535534 L6.14644661,11.8535534 C5.83146418,11.538571 '
    '6.05454757,11 6.5,11 L10.5,11 C11.709479,11 12.7183558,10.1411202 12.9499909,9 L6.5,9 '
    'C6.22385763,9 6,8.77614237 6,8.5 C6,8.22385763 6.22385763,8 6.5,8 L12.9499909,8 '
    'C12.7183558,6.85887984 11.709479,6 10.5,6 L6.5,6 C6.22385763,6 6,5.77614237 6,5.5 '
    'C6,5.22385763 6.22385763,5 6.5,5 L10.5,5 L17.5,5 C17.7761424,5 18,5.22385763 18,5.5 '
    'C18,5.77614237 17.7761424,6 17.5,6 L12.9494914,6 L12.9494914,6 Z';

class _SvgPathSink extends PathProxy {
  _SvgPathSink() : path = Path();
  final Path path;

  @override
  void close() => path.close();

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) =>
      path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);
}

Path? _rawRupeePath;
Size? _lastScaledFor;
Path? _scaledRupeePath;

/// Parses [kRupeeSymbolSvgPathData] into a [Path] in SVG coordinates.
Path parseRupeeSvgPath() {
  _rawRupeePath ??= () {
    final sink = _SvgPathSink();
    writeSvgPathDataToPath(kRupeeSymbolSvgPathData, sink);
    return sink.path;
  }();
  return _rawRupeePath!;
}

/// Uniform scale + center so the glyph fits [size] (with a small inset).
Path scalePathToSize(Path path, Size size, {double padding = 0.94}) {
  final bounds = path.getBounds();
  if (bounds.width <= 0 || bounds.height <= 0) return path;

  final scale = math.min(
        size.width / bounds.width,
        size.height / bounds.height,
      ) *
      padding;

  final matrix = Matrix4.identity()
    // ignore: deprecated_member_use
    ..translate(
      size.width / 2 - bounds.center.dx * scale,
      size.height / 2 - bounds.center.dy * scale,
    )
    // ignore: deprecated_member_use
    ..scale(scale, scale);

  return path.transform(matrix.storage);
}

/// ₹ path fitted to [size] — cached per dimensions (hot paint path).
Path buildRupeePath(Size size) {
  if (_scaledRupeePath != null &&
      _lastScaledFor != null &&
      (size.width - _lastScaledFor!.width).abs() < 0.5 &&
      (size.height - _lastScaledFor!.height).abs() < 0.5) {
    return _scaledRupeePath!;
  }
  _lastScaledFor = size;
  _scaledRupeePath = scalePathToSize(parseRupeeSvgPath(), size);
  return _scaledRupeePath!;
}
