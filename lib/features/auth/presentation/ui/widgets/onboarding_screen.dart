import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../auth_screen.dart';
import 'flow_background.dart';
import 'onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final ValueNotifier<double> _pageNotifier = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_syncPage);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPage());
  }

  void _syncPage() {
    if (!mounted) return;
    final page = _pageController.hasClients
        ? (_pageController.page ?? _pageController.initialPage.toDouble())
        : _pageController.initialPage.toDouble();
    if (_pageNotifier.value != page) {
      _pageNotifier.value = page;
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_syncPage);
    _pageController.dispose();
    _pageNotifier.dispose();
    super.dispose();
  }

  double _chaosForPage(double page) {
    if (page < 1) {
      return lerpDouble(1.0, 0.4, page.clamp(0.0, 1.0))!;
    }
    return lerpDouble(0.4, 0.0, (page - 1).clamp(0.0, 1.0))!;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ValueListenableBuilder<double>(
            valueListenable: _pageNotifier,
            builder: (context, page, _) {
              return RepaintBoundary(
                child: FlowBackground(chaos: _chaosForPage(page)),
              );
            },
          ),
          PageView(
            controller: _pageController,
            onPageChanged: (_) => _syncPage(),
            children: const [
              OnboardingPage(
                title: 'Money feels messy',
                subtitle: 'Scattered expenses, no clarity',
              ),
              OnboardingPage(
                title: 'We bring flow',
                subtitle: 'Everything connected beautifully',
              ),
              OnboardingPage(
                title: 'You are in control',
                subtitle: 'Clarity, balance, confidence',
              ),
            ],
          ),
          ValueListenableBuilder<double>(
            valueListenable: _pageNotifier,
            builder: (context, page, _) {
              final t = ((page - 1.8) / 0.2).clamp(0.0, 1.0);
              return IgnorePointer(
                ignoring: t <= 0,
                child: Opacity(
                  opacity: t,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, 40 + bottomInset),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => const AuthScreen(),
                              ),
                            );
                          },
                          child: const Text('Get Started'),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
