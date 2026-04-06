import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'rupee_particles.dart';
import 'rupee_path.dart';

/// Particles only: scatter → settle on the ₹ path; stops repainting when done (no breath loop).
class RupeePremiumWidget extends StatefulWidget {
  const RupeePremiumWidget({super.key});

  @override
  State<RupeePremiumWidget> createState() => _RupeePremiumWidgetState();
}

class _RupeePremiumWidgetState extends State<RupeePremiumWidget>
    with SingleTickerProviderStateMixin {
  static const int _particleCount = 160;

  late final AnimationController _particleController;

  List<StrokeParticle>? _particles;
  Size? _lastSize;
  int _simFrame = 0;

  @override
  void initState() {
    super.initState();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _particleController.addStatusListener(_onParticleStatus);
    _particleController.addListener(_tickParticles);

    _particleController.forward(from: 0);
  }

  void _onParticleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _particleController.stop();
    }
  }

  void _tickParticles() {
    if (_particles == null) return;
    _simFrame++;
    if (_simFrame % 2 != 0) return;

    final eased = Curves.easeOutCubic.transform(_particleController.value);
    for (final p in _particles!) {
      p.update(eased);
    }
  }

  void _ensureParticles(Size size) {
    if (_particles != null &&
        _lastSize != null &&
        (size.width - _lastSize!.width).abs() < 1 &&
        (size.height - _lastSize!.height).abs() < 1) {
      return;
    }

    _lastSize = size;
    final path = buildRupeePath(size);
    final targets = samplePath(path, _particleCount);
    final rnd = math.Random(42);
    final cx = size.width / 2;
    final cy = size.height / 2;

    _particles = targets
        .map(
          (tg) => StrokeParticle(
            position: Offset(
              cx + (rnd.nextDouble() - 0.5) * size.width * 0.95,
              cy + (rnd.nextDouble() - 0.5) * size.height * 0.95,
            ),
            target: tg,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _particleController
      ..removeStatusListener(_onParticleStatus)
      ..removeListener(_tickParticles)
      ..dispose();
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

        _ensureParticles(size);

        return Center(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  size: size,
                  painter: _RupeePremiumPainter(
                    size: size,
                    particleProgress: _particleController.value,
                    particles: _particles ?? const [],
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

class _RupeePremiumPainter extends CustomPainter {
  _RupeePremiumPainter({
    required this.size,
    required this.particleProgress,
    required this.particles,
    required this.color,
  });

  /// Static “breath” phase — avoids a second always-on controller.
  static const double _breath = 0.5;

  final Size size;
  final double particleProgress;
  final List<StrokeParticle> particles;
  final Color color;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final w = size.width;
    final h = size.height;
    final ox = (canvasSize.width - w) / 2;
    final oy = (canvasSize.height - h) / 2;
    canvas.save();
    canvas.translate(ox, oy);

    if (particleProgress > 0 && particles.isNotEmpty) {
      final glowPaint = Paint()
        ..color = color.withValues(
          alpha: 0.24 + 0.04 * math.sin(_breath * math.pi * 2),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      final corePaint = Paint()..color = color;

      for (final p in particles) {
        canvas.drawCircle(p.position, 1.8, glowPaint);
        canvas.drawCircle(p.position, 0.9, corePaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RupeePremiumPainter oldDelegate) {
    return oldDelegate.particleProgress != particleProgress ||
        oldDelegate.color != color ||
        !identical(oldDelegate.particles, particles) ||
        oldDelegate.size != size;
  }
}
