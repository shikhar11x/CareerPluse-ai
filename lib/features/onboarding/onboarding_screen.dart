import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/page_dots.dart';
import '../../core/widgets/tilt_card.dart';

class _SlideData {
  const _SlideData(this.icon, this.title, this.body, this.gradient);

  final IconData icon;
  final String title;
  final String body;
  final Gradient gradient;
}

const _slides = <_SlideData>[
  _SlideData(
    Icons.psychology_rounded,
    'Practise with an AI interviewer',
    'Role-specific questions that adapt to your answers, whenever you want to rehearse.',
    AppColors.brand,
  ),
  _SlideData(
    Icons.graphic_eq_rounded,
    'Talk it out, or type it',
    'Pick voice or text for each session, whichever fits your day.',
    AppColors.hot,
  ),
  _SlideData(
    Icons.insights_rounded,
    'Know exactly what to improve',
    'Scores, missed concepts and a learning roadmap built from your own results.',
    AppColors.aqua,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _pageValue() =>
      _controller.hasClients && _controller.position.haveDimensions
          ? (_controller.page ?? _index.toDouble())
          : _index.toDouble();

  void _next() {
    if (_isLast) {
      context.go(Routes.auth);
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                child: TextButton(
                  onPressed: () => context.go(Routes.auth),
                  child: const Text('Skip', style: TextStyle(color: AppColors.textMid)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final d = (_pageValue() - i).clamp(-1.0, 1.0).toDouble().abs();
                    return Opacity(
                      opacity: 1 - d * 0.7,
                      child: Transform.scale(
                        scale: 1 - d * 0.1,
                        child: _SlideView(data: _slides[i]),
                      ),
                    );
                  },
                ),
              ),
            ),
            PageDots(count: _slides.length, index: _index),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: NeonButton(
                label: _isLast ? 'Get started' : 'Next',
                icon: Icons.arrow_forward_rounded,
                expand: true,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.data});

  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TiltCard(
            radius: 44,
            maxTilt: 0.2,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(44),
                gradient: data.gradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.45),
                    blurRadius: 50,
                    offset: const Offset(0, 22),
                  ),
                ],
              ),
              child: Icon(data.icon, size: 96, color: Colors.white),
            ),
          ),
          const SizedBox(height: 40),
          Text(data.title, textAlign: TextAlign.center, style: AppText.display(28)),
          const SizedBox(height: 12),
          Text(data.body, textAlign: TextAlign.center, style: AppText.muted),
        ],
      ),
    );
  }
}