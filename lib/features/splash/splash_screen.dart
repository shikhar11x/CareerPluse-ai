import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ai_orb.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/gradient_text.dart';
import '../auth/auth_providers.dart';
import '../profile/profile_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final minimumShow = Future<void>.delayed(const Duration(milliseconds: 2200));
    final signedIn = ref.read(authRepositoryProvider).currentSession != null;
    if (signedIn) {
      // Warm the profile so Home opens with data. Errors are shown on Home.
      try {
        await ref.read(profileProvider.future).timeout(const Duration(seconds: 8));
      } catch (_) {}
    }
    await minimumShow;
    if (!mounted) return;
    // The router redirect sends signed-in users with an incomplete profile
    // to profile setup.
    context.go(signedIn ? Routes.home : Routes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Entrance(child: AiOrb(size: 220)),
            const SizedBox(height: 28),
            Entrance(
              delay: const Duration(milliseconds: 350),
              child: GradientText('CareerPulse AI', style: AppText.display(38)),
            ),
            const SizedBox(height: 10),
            const Entrance(
              delay: Duration(milliseconds: 650),
              child: Text('Interview better. Land the role.', style: AppText.muted),
            ),
            const SizedBox(height: 36),
            const Entrance(
              delay: Duration(milliseconds: 900),
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.cyan,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}