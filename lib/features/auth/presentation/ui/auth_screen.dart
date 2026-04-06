import 'package:expense_tracker_app/features/auth/presentation/ui/widgets/flow_field_animation.dart';
import 'package:flutter/material.dart';

import 'widgets/dot_animation.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          Expanded(child: FlowFieldScreen()),
          Expanded(child: Sunflower()),
          Text('Auth Screen'),
        ],
      ),
    );
  }
}
