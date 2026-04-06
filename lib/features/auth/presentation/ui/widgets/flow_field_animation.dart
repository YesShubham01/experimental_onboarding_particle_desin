import 'package:flutter/material.dart';
import 'dart:math' as math;

class FlowFieldScreen extends StatefulWidget {
  const FlowFieldScreen({super.key});

  @override
  State<FlowFieldScreen> createState() => _FlowFieldScreenState();
}

class _FlowFieldScreenState extends State<FlowFieldScreen> {
  /// 0 = organized (attractor wins); 1 = scattered, uncontrolled.
  double chaos = 0.35;

  static const int particleCount = 150;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final orderPct = (100 - chaos * 100).round();
    final chaosPct = (chaos * 100).round();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: FlowFieldWidget(
              particles: particleCount,
              chaos: chaos,
              adaptiveDensity: true,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Order $orderPct% · Chaos $chaosPct%',
            style: TextStyle(color: colors.onSurface),
          ),

          SizedBox(
            width: 300,
            child: Slider(
              min: 0,
              max: 1,
              divisions: 100,
              value: chaos.clamp(0.0, 1.0),
              activeColor: colors.primary,
              onChanged: (val) {
                setState(() => chaos = val);
              },
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class FlowFieldWidget extends StatefulWidget {
  final int particles;
  final double chaos;

  /// When true, fills parent constraints (e.g. full-screen background).
  final bool expandToParent;

  /// Multiplier for trail / shader opacity (e.g. 0.6 for soft onboarding).
  final double? lineAlphaScale;

  /// Halve particle count on narrow layouts to protect frame time.
  final bool adaptiveDensity;

  const FlowFieldWidget({
    super.key,
    this.particles = 250,
    this.chaos = 0.35,
    this.expandToParent = false,
    this.lineAlphaScale,
    this.adaptiveDensity = false,
  });

  @override
  State<FlowFieldWidget> createState() => _FlowFieldWidgetState();
}

class _FlowFieldWidgetState extends State<FlowFieldWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final math.Random _rand = math.Random();

  int _targetParticleCount(BuildContext context) {
    var n = widget.particles;
    if (widget.adaptiveDensity) {
      final shortest = MediaQuery.sizeOf(context).shortestSide;
      if (shortest < 360) {
        n = (n / 2).round().clamp(48, n);
      }
    }
    return n;
  }

  void _tick() {
    final c = widget.chaos;
    final noiseScale = _noiseScale(c);
    final angleJitter = _angleJitter(c);
    final randomDrift = _randomDrift(c);
    final speedBoost = 1 + c * 2;
    for (final p in _particles) {
      p.update(
        noiseScale: noiseScale,
        angleJitter: angleJitter,
        randomDrift: randomDrift,
        speedBoost: speedBoost,
        chaos: c,
        rand: _rand,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.particles, (_) => Particle.random());

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 160),
    )..addListener(_tick)
     ..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final target = _targetParticleCount(context);
    if (target != _particles.length) {
      setState(() {
        _particles = List.generate(target, (_) => Particle.random());
      });
    }
  }

  @override
  void didUpdateWidget(FlowFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.particles != widget.particles) {
      final target = _targetParticleCount(context);
      setState(() {
        _particles = List.generate(target, (_) => Particle.random());
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static double _noiseScale(double chaos) => 0.8 + chaos * 12.0;

  static double _angleJitter(double chaos) => chaos * math.pi;

  static double _randomDrift(double chaos) => chaos * 0.003;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mult = widget.lineAlphaScale ?? 1.0;

    final painter = FlowFieldPainter(
      particles: _particles,
      repaint: _controller,
      lineAlphaScale: mult,
      flowColor: scheme.primary,
      accentColor: scheme.tertiary,
    );

    if (!widget.expandToParent) {
      return CustomPaint(
        painter: painter,
        size: const Size(600, 600),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: painter,
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}

class Particle {
  static const int maxTrailLength = 8;

  double x;
  double y;
  double speed;
  final List<Offset> trail = [];

  Particle(this.x, this.y, this.speed);

  factory Particle.random() {
    final rand = math.Random();
    return Particle(
      rand.nextDouble(),
      rand.nextDouble(),
      rand.nextDouble() * 0.002 + 0.001,
    );
  }

  void update({
    required double noiseScale,
    required double angleJitter,
    required double randomDrift,
    required double speedBoost,
    required double chaos,
    required math.Random rand,
  }) {
    final baseAngle = _noise(x * noiseScale, y * noiseScale) * math.pi * 2;
    final jitter = (rand.nextDouble() * 2 - 1) * angleJitter;
    final angle = baseAngle + jitter;

    double dx = math.cos(angle) * speed * speedBoost;
    double dy = math.sin(angle) * speed * speedBoost;

    const cx = 0.5;
    const cy = 0.5;
    final attractStrength = (1 - chaos) * 0.01;
    dx += (cx - x) * attractStrength;
    dy += (cy - y) * attractStrength;

    dx += (rand.nextDouble() * 2 - 1) * randomDrift;
    dy += (rand.nextDouble() * 2 - 1) * randomDrift;

    x += dx;
    y += dy;

    if (x > 1) x = 0;
    if (x < 0) x = 1;
    if (y > 1) y = 0;
    if (y < 0) y = 1;

    trail.add(Offset(x, y));
    if (trail.length > maxTrailLength) trail.removeAt(0);
  }

  double _noise(double x, double y) {
    return ((math.sin(x * 1.5 + y * 1.2) +
                math.cos(x * 0.7 - y * 1.3)) *
            0.5 +
        0.5);
  }
}

/// Batched path + [repaint] Listenable — no widget rebuild per simulation step.
class FlowFieldPainter extends CustomPainter {
  FlowFieldPainter({
    required this.particles,
    required Listenable repaint,
    required this.lineAlphaScale,
    required this.flowColor,
    required this.accentColor,
  }) : super(repaint: repaint);

  final List<Particle> particles;
  final double lineAlphaScale;
  final Color flowColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty || size.isEmpty) return;

    final rect = Offset.zero & size;
    final path = Path();
    var hasSegments = false;

    for (final p in particles) {
      final trail = p.trail;
      if (trail.length < 2) continue;

      for (var i = 0; i < trail.length - 1; i++) {
        final p1 = trail[i];
        final p2 = trail[i + 1];
        path.moveTo(p1.dx * size.width, p1.dy * size.height);
        path.lineTo(p2.dx * size.width, p2.dy * size.height);
        hasSegments = true;
      }
    }

    if (!hasSegments) return;

    final m = lineAlphaScale.clamp(0.0, 1.0);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          flowColor.withValues(alpha: 0.12 * m),
          accentColor.withValues(alpha: 0.32 * m),
        ],
      ).createShader(rect);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          flowColor.withValues(alpha: 0.0),
          accentColor.withValues(alpha: 0.78 * m),
        ],
      ).createShader(rect);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant FlowFieldPainter oldDelegate) {
    return oldDelegate.lineAlphaScale != lineAlphaScale ||
        oldDelegate.flowColor != flowColor ||
        oldDelegate.accentColor != accentColor ||
        !identical(oldDelegate.particles, particles);
  }
}
