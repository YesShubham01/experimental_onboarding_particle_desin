import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'rupee_particles.dart';
import 'rupee_path.dart';

/// Golden-angle phyllotaxis in normalized [0–1]² (centered disk).
List<Offset> generateSunflowerPoints(int count) {
  if (count <= 0) return [];
  const phi = 137.5 * math.pi / 180;
  final points = <Offset>[];

  for (var i = 0; i < count; i++) {
    final r = math.sqrt(i / count);
    final theta = i * phi;
    final x = 0.5 + r * math.cos(theta) * 0.48;
    final y = 0.5 + r * math.sin(theta) * 0.48;
    points.add(Offset(x, y));
  }
  return points;
}

/// Greedy nearest-neighbor: each [source] point gets a unique closest [target]
/// (removes matches so paths stay short and crossings drop vs index pairing).
List<Offset> matchPoints(List<Offset> source, List<Offset> target) {
  if (source.isEmpty) return [];
  if (target.isEmpty) {
    return List<Offset>.filled(source.length, source.first);
  }

  final remaining = List<Offset>.from(target);
  final result = <Offset>[];

  for (final s in source) {
    if (remaining.isEmpty) break;

    var bestIdx = 0;
    var bestD = (remaining[0] - s).distanceSquared;
    for (var j = 1; j < remaining.length; j++) {
      final d = (remaining[j] - s).distanceSquared;
      if (d < bestD) {
        bestD = d;
        bestIdx = j;
      }
    }
    result.add(remaining.removeAt(bestIdx));
  }

  if (result.isEmpty) {
    return List<Offset>.filled(source.length, target.first);
  }
  while (result.length < source.length) {
    result.add(result.last);
  }
  return result;
}

/// Sunflower spiral ↔ ₹ outline via [Offset.lerp]; loops forward/reverse.
class SunflowerToRupee extends StatefulWidget {
  const SunflowerToRupee({
    super.key,
    this.pointCount = 180,
    this.duration = const Duration(milliseconds: 2800),
  });

  final int pointCount;
  final Duration duration;

  @override
  State<SunflowerToRupee> createState() => _SunflowerToRupeeState();
}

class _SunflowerToRupeeState extends State<SunflowerToRupee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Offset> _sunflower;
  List<Offset> _rupee = [];
  bool _ready = false;
  Size? _layoutSize;

  @override
  void initState() {
    super.initState();
    _sunflower = generateSunflowerPoints(widget.pointCount);
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener(_onAnimStatus);
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _controller.reverse();
      });
    } else if (status == AnimationStatus.dismissed) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _controller.forward();
      });
    }
  }

  /// Same ₹ geometry as [RupeePremiumWidget]: SVG path scaled to [size], then sampled.
  void _ensureRupeeForLayout(Size size) {
    if (_layoutSize != null &&
        (size.width - _layoutSize!.width).abs() < 1 &&
        (size.height - _layoutSize!.height).abs() < 1) {
      return;
    }
    _layoutSize = size;

    final path = buildRupeePath(size);
    final sampledPx = samplePath(path, widget.pointCount);
    if (sampledPx.isEmpty || size.width <= 0 || size.height <= 0) {
      _rupee = [];
      _ready = false;
      return;
    }

    final w = size.width;
    final h = size.height;
    final side = math.max(w, h);
    final sampled = sampledPx
        .map(
          (p) =>
              Offset(0.5 + (p.dx - w / 2) / side, 0.5 + (p.dy - h / 2) / side),
        )
        .toList();

    _rupee = matchPoints(_sunflower, sampled);
    _ready = _rupee.isNotEmpty;

    if (_ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.forward(from: 0);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side =
            (math.min(constraints.maxWidth, constraints.maxHeight) * 0.88)
                .clamp(220.0, 340.0);
        final size = Size(side, side);

        _ensureRupeeForLayout(size);

        if (!_ready) {
          return Center(
            child: RepaintBoundary(
              child: CustomPaint(
                size: size,
                painter: _SunflowerRupeeMorphPainter(
                  t: 0,
                  sunflower: _sunflower,
                  rupee: const [],
                  color: color,
                ),
              ),
            ),
          );
        }

        return Center(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = Curves.easeInOutCubic.transform(_controller.value);
                return CustomPaint(
                  size: size,
                  painter: _SunflowerRupeeMorphPainter(
                    t: t,
                    sunflower: _sunflower,
                    rupee: _rupee,
                    color: color,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _SunflowerRupeeMorphPainter extends CustomPainter {
  _SunflowerRupeeMorphPainter({
    required this.t,
    required this.sunflower,
    required this.rupee,
    required this.color,
  });

  final double t;
  final List<Offset> sunflower;
  final List<Offset> rupee;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (sunflower.isEmpty || size.isEmpty) return;

    final rupeePts = rupee.isEmpty ? sunflower : rupee;
    final n = math.min(sunflower.length, rupeePts.length);
    if (n == 0) return;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final clarity = (0.6 + 0.4 * t).clamp(0.0, 1.0);
    final baseColor = color.withValues(alpha: clarity);

    final pulse = 1 + 0.015 * math.sin(t * math.pi * 2);
    final rotation = (t < 0.5) ? (1 - t * 2) * 0.25 : 0.0;

    canvas.save();
    canvas.translate(cx, cy);
    if (t < 0.5) {
      canvas.scale(pulse);
    }
    canvas.rotate(rotation);
    canvas.translate(-cx, -cy);

    final glow = Paint()
      ..color = baseColor.withValues(alpha: baseColor.a * 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final core = Paint()..color = baseColor;

    for (var i = 0; i < n; i++) {
      // [t] is already easeInOutCubic from the builder; fade delay out → no hard cutoff.
      final delay = i * 0.0008 * (1 - t);
      final localT = (t - delay).clamp(0.0, 1.0);
      final pos = Offset.lerp(sunflower[i], rupeePts[i], localT)!;
      final o = Offset(pos.dx * size.width, pos.dy * size.height);
      canvas.drawCircle(o, 2.0, glow);
      canvas.drawCircle(o, 1.6, core);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SunflowerRupeeMorphPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.color != color ||
        !identical(oldDelegate.sunflower, sunflower) ||
        !identical(oldDelegate.rupee, rupee);
  }
}
