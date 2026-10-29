import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ai_orb.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/glass_card.dart';
import '../auth/auth_providers.dart';
import 'profile_form.dart';

/// Shown right after sign-up until the profile is complete.
/// The router sends the user to Home as soon as the profile is saved.
class ProfileSetupScreen extends ConsumerWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: StaggeredList(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          gap: 20,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                const AiOrb(size: 72),
                Text("Let's set up your profile", style: AppText.display(30)),
                const Text(
                  'Four quick answers so your interviews match the role you want.',
                  style: AppText.muted,
                ),
              ],
            ),
            const GlassCard(
              padding: EdgeInsets.all(22),
              child: ProfileForm(submitLabel: 'Continue'),
            ),
            Center(
              child: TextButton.icon(
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
                icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.textLo),
                label: const Text(
                  'Use a different account',
                  style: TextStyle(color: AppColors.textLo),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}