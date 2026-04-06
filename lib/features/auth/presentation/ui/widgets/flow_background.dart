import 'package:flutter/material.dart';

import 'flow_field_animation.dart';

/// Full-bleed flow field for onboarding and hero backgrounds.
class FlowBackground extends StatelessWidget {
  final double chaos;

  const FlowBackground({super.key, required this.chaos});

  @override
  Widget build(BuildContext context) {
    return FlowFieldWidget(
      particles: 140,
      chaos: chaos,
      expandToParent: true,
      lineAlphaScale: 0.6,
      adaptiveDensity: true,
    );
  }
}
