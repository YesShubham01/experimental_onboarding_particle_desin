import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../rupee_outline_points.dart';

/// Samples normalized (0–1) points on the ₹ glyph outline.
Future<List<Offset>> generateRupeePoints() async {
  return generateRupeeOutlinePoints(
    fontSize: 200,
    fontWeight: FontWeight.bold,
    sampleStep: 6,
  );
}

class RupeeParticle {
  RupeeParticle({
    required this.position,
    required this.target,
    required this.delay,
  }) : velocity = Offset.zero;

  Offset position;
  Offset velocity;
  final Offset target;
  final double delay;

  void update(double progress) {
    final t = (progress - delay).clamp(0.0, 1.0);
    if (t <= 0) return;

    final toTarget = target - position;
    final strength = 0.02 + 0.03 * t;
    velocity += toTarget * strength;
    velocity *= 0.82;
    position += velocity;
  }
}

class RupeeFormationPainter extends CustomPainter {
  RupeeFormationPainter({
    required this.particles,
    required this.formation,
    required this.breath,
    required this.dotColor,
  }) : super(repaint: Listenable.merge([formation, breath]));

  final Animation<double> formation;
  final Animation<double> breath;
  final List<RupeeParticle> particles;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty || size.isEmpty) return;

    final b = breath.value;
    final blurSigma =
        (1.4 + 0.9 * (0.5 + 0.5 * math.sin(b * math.pi * 2))).clamp(1.5, 3.0);
    final glowPaint = Paint()
      ..color = dotColor.withValues(
        alpha: 0.24 + 0.08 * math.sin(b * math.pi * 2),
      )
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);

    final corePaint = Paint()
      ..color = dotColor
      ..strokeCap = StrokeCap.round;

    for (final p in particles) {
      final offset = Offset(
        p.position.dx * size.width,
        p.position.dy * size.height,
      );
      canvas.drawCircle(offset, 1.8, glowPaint);
      canvas.drawCircle(offset, 0.9, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant RupeeFormationPainter oldDelegate) {
    return oldDelegate.dotColor != dotColor ||
        !identical(oldDelegate.particles, particles);
  }
}

/// Full-bleed chaos → ₹ formation with staggered attraction, glow, and breathing.
class RupeeParticleFormation extends StatefulWidget {
  const RupeeParticleFormation({super.key});

  @override
  State<RupeeParticleFormation> createState() => _RupeeParticleFormationState();
}

class _RupeeParticleFormationState extends State<RupeeParticleFormation>
    with TickerProviderStateMixin {
  late final AnimationController _formationController;
  late final AnimationController _breathController;
  final math.Random _rand = math.Random();

  List<RupeeParticle> _particles = [];
  bool _loading = true;
  int _simFrame = 0;

  @override
  void initState() {
    super.initState();
    _formationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..addListener(_onFormationTick);

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    var targets = await generateRupeePoints();
    if (!mounted) return;

    if (targets.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    var n = targets.length;
    if (n > 600) {
      final copy = List<Offset>.from(targets)..shuffle(_rand);
      targets = copy.sublist(0, 600);
      n = 600;
    }

    _particles = List.generate(n, (i) {
      final tgt = targets[i];
      final delay = (tgt.dy * 0.7 + tgt.dx * 0.3).clamp(0.0, 1.0);
      return RupeeParticle(
        position: Offset(_rand.nextDouble(), _rand.nextDouble()),
        target: tgt,
        delay: delay,
      );
    });

    setState(() => _loading = false);
    _formationController.forward(from: 0);
  }

  void _onFormationTick() {
    _simFrame++;
    if (_simFrame % 2 != 0) return;

    final progress = _formationController.value;
    for (final p in _particles) {
      p.update(progress);
    }
    if (progress >= 1.0 &&
        _breathController.status == AnimationStatus.dismissed) {
      _breathController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _formationController
      ..removeListener(_onFormationTick)
      ..dispose();
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _particles.isEmpty) {
      return const SizedBox.expand();
    }

    final scheme = Theme.of(context).colorScheme;
    final accent = Color.lerp(scheme.primary, scheme.tertiary, 0.35)!;

    return CustomPaint(
      painter: RupeeFormationPainter(
        particles: _particles,
        formation: _formationController,
        breath: _breathController,
        dotColor: accent,
      ),
      size: Size.infinite,
    );
  }
}
