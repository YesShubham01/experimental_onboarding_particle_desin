import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'rupee_outline_points.dart';

/// Alive particle field: scatters and slowly organizes into ₹, then eases back — loops.
class RupeeBackground extends StatefulWidget {
  const RupeeBackground({super.key});

  @override
  State<RupeeBackground> createState() => _RupeeBackgroundState();
}

class _RupeeBackgroundState extends State<RupeeBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<Particle> _particles = [];
  final math.Random _rand = math.Random();
  int _simFrame = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    var targets = await _generateRupeePoints();
    if (!mounted) return;

    if (targets.isEmpty) {
      setState(() {});
      return;
    }

    if (targets.length > 600) {
      targets = _subsample(targets, 600);
    }

    _particles = List.generate(targets.length, (i) {
      final scatter = Offset(_rand.nextDouble(), _rand.nextDouble());
      return Particle(
        scatter: scatter,
        position: scatter,
        target: targets[i],
        delay: _rand.nextDouble() * 0.4,
        initialVelocity: Offset(
          (_rand.nextDouble() - 0.5) * 0.02,
          (_rand.nextDouble() - 0.5) * 0.02,
        ),
      );
    });

    _controller
      ..addListener(_tick)
      ..repeat(reverse: true);

    setState(() {});
  }

  void _tick() {
    _simFrame++;
    if (_simFrame % 2 != 0) return;

    final t = _controller.value;
    for (final p in _particles) {
      p.update(t);
    }
  }

  static List<Offset> _subsample(List<Offset> points, int maxCount) {
    if (points.length <= maxCount) return points;
    final r = math.Random(42);
    final copy = List<Offset>.from(points)..shuffle(r);
    return copy.sublist(0, maxCount);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty) {
      return const SizedBox.expand();
    }

    return CustomPaint(
      painter: RupeePainter(
        particles: _particles,
        repaint: _controller,
        color: Theme.of(context).colorScheme.primary,
      ),
      size: Size.infinite,
    );
  }

  Future<List<Offset>> _generateRupeePoints() async {
    return generateRupeeOutlinePoints(
      fontSize: 220,
      fontWeight: FontWeight.bold,
      sampleStep: 6,
    );
  }
}

class Particle {
  Particle({
    required this.scatter,
    required this.position,
    required this.target,
    required this.delay,
    Offset initialVelocity = Offset.zero,
  }) : velocity = initialVelocity;

  final Offset scatter;
  Offset position;
  final Offset target;
  final double delay;
  Offset velocity;

  static const Offset _center = Offset(0.5, 0.5);

  void update(double phase) {
    final progress = (phase - delay).clamp(0.0, 1.0);

    if (progress <= 0) {
      velocity *= 0.99;
      position += velocity;
      return;
    }

    final toCenter = _center - position;

    if (progress < 0.5) {
      final swirl = Offset(-toCenter.dy, toCenter.dx) * 0.003;
      velocity += toCenter * 0.01;
      velocity += swirl;
    } else {
      final toTarget = target - position;
      velocity += toTarget * 0.04;
    }

    velocity *= 0.82;
    position += velocity;

    position += Offset(
      math.sin(phase * math.pi * 2 * 3) * 0.0003,
      math.cos(phase * math.pi * 2 * 3) * 0.0003,
    );
  }
}

class RupeePainter extends CustomPainter {
  RupeePainter({
    required this.particles,
    required Listenable repaint,
    required this.color,
  }) : super(repaint: repaint);

  final List<Particle> particles;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty || size.isEmpty) return;

    final glow = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round;

    for (final p in particles) {
      final offset = Offset(
        p.position.dx * size.width,
        p.position.dy * size.height,
      );

      canvas.drawCircle(offset, 1.8, glow);
      canvas.drawCircle(offset, 0.9, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RupeePainter oldDelegate) {
    // Animation repaints via [repaint]; only theme / new particle list here.
    return oldDelegate.color != color ||
        !identical(oldDelegate.particles, particles);
  }
}
