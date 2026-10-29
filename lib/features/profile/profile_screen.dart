import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/avatar_badge.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/info_chip.dart';
import '../auth/auth_providers.dart';
import 'profile_controller.dart';
import 'profile_form.dart';
import 'profile_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Profile? profile = ref.watch(profileProvider).asData?.value;
    final email = ref.watch(authRepositoryProvider).currentSession?.user.email;

    return SafeArea(
      bottom: false,
      child: StaggeredList(
        children: [
          Column(
            spacing: 10,
            children: [
              AvatarBadge(initials: profile?.initials ?? '?', size: 88),
              Text(
                profile?.fullName.isNotEmpty == true ? profile!.fullName : 'Your profile',
                style: AppText.display(26),
                textAlign: TextAlign.center,
              ),
              if (email != null) Text(email, style: AppText.muted),
              if (profile != null)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (profile.targetRole.isNotEmpty)
                      InfoChip(label: profile.targetRole, icon: Icons.track_changes_rounded),
                    if (profile.experienceLabel.isNotEmpty)
                      InfoChip(
                        label: profile.experienceLabel,
                        icon: Icons.work_outline_rounded,
                        color: AppColors.violet,
                      ),
                  ],
                ),
            ],
          ),
          GlassCard(
            blur: 0,
            padding: const EdgeInsets.all(22),
            child: ProfileForm(initial: profile, submitLabel: 'Save changes'),
          ),
          Center(
            child: TextButton.icon(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.danger),
              label: const Text('Sign out', style: TextStyle(color: AppColors.danger)),
            ),
          ),
        ],
      ),
    );
  }
}