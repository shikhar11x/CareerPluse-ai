import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/action_card.dart';
import '../../core/widgets/ai_orb.dart';
import '../../core/widgets/avatar_badge.dart';
import '../../core/widgets/checklist_tile.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/error_state_card.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/info_chip.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/score_ring.dart';
import '../../core/widgets/section.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/stat_tile.dart';
import '../../core/widgets/tilt_card.dart';
import '../profile/profile_controller.dart';
import '../profile/profile_model.dart';

/// Every number here is an honest empty state until the interview (Phase 3)
/// and progress (Phase 5) features exist.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileProvider);
    return SafeArea(
      bottom: false,
      child: state.when(
        loading: () => const _DashboardSkeleton(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorStateCard(
              message: errorMessage(e),
              onRetry: () => ref.invalidate(profileProvider),
            ),
          ),
        ),
        data: (profile) => _DashboardBody(profile: profile),
      ),
    );
  }
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.profile});

  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    void toInterview() => context.go(Routes.interview);

    // Completed profile is the only step we can verify today.
    const done = [true, false, false];

    return StaggeredList(
      children: [
        _Header(
          greeting: _greeting(),
          name: p?.firstName ?? 'there',
          initials: p?.initials ?? '?',
          onAvatar: () => context.go(Routes.profile),
        ),
        TiltCard(
          onTap: toInterview,
          child: _HeroCard(role: p?.targetRole ?? '', onStart: toInterview),
        ),
        Section(
          title: 'Practise by type',
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: _PracticeTile(
                  icon: Icons.code_rounded,
                  label: 'Technical',
                  color: AppColors.cyan,
                  onTap: toInterview,
                ),
              ),
              Expanded(
                child: _PracticeTile(
                  icon: Icons.groups_rounded,
                  label: 'HR',
                  color: AppColors.violet,
                  onTap: toInterview,
                ),
              ),
              Expanded(
                child: _PracticeTile(
                  icon: Icons.forum_rounded,
                  label: 'Behavioral',
                  color: AppColors.pink,
                  onTap: toInterview,
                ),
              ),
            ],
          ),
        ),
        const Row(
          spacing: 12,
          children: [
            Expanded(child: StatTile(label: 'Interviews', icon: Icons.mic_rounded)),
            Expanded(child: StatTile(label: 'Avg. score', icon: Icons.bolt_rounded)),
            Expanded(
              child: StatTile(
                label: 'Streak',
                icon: Icons.local_fire_department_rounded,
                accent: AppColors.warning,
              ),
            ),
          ],
        ),
        ActionCard(
          icon: Icons.description_rounded,
          title: 'Resume analysis',
          subtitle: 'Match your resume to a job description.',
          onTap: () => context.go(Routes.resume),
        ),
        _JourneyCard(done: done),
        const Section(
          title: 'Skill progress',
          child: EmptyStateCard(
            icon: Icons.radar_rounded,
            title: 'Your skill radar is empty',
            body: 'Finish your first mock interview and your strengths and gaps appear here.',
          ),
        ),
        const Section(
          title: 'Recent interviews',
          child: EmptyStateCard(
            icon: Icons.history_rounded,
            title: 'No interviews yet',
            body: 'Your scores and transcripts will be listed here.',
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.name,
    required this.initials,
    required this.onAvatar,
  });

  final String greeting;
  final String name;
  final String initials;
  final VoidCallback onAvatar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: AppText.muted.copyWith(fontSize: 15)),
              const SizedBox(height: 4),
              Text(
                'Hi, $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.display(34),
              ),
            ],
          ),
        ),
        AvatarBadge(initials: initials, onTap: onAvatar),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.role, required this.onStart});

  final String role;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1B6B), Color(0xFF0E2A4D)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.35),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (role.isNotEmpty) ...[
                  InfoChip(label: role, icon: Icons.track_changes_rounded),
                  const SizedBox(height: 12),
                ],
                Text('Ready for your\nnext interview?', style: AppText.display(24)),
                const SizedBox(height: 10),
                const Text(
                  'Practise with an AI interviewer and get structured feedback.',
                  style: AppText.muted,
                ),
                const SizedBox(height: 18),
                NeonButton(
                  label: 'Start mock interview',
                  icon: Icons.mic_rounded,
                  onPressed: onStart,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const AiOrb(size: 104),
        ],
      ),
    );
  }
}

class _PracticeTile extends StatelessWidget {
  const _PracticeTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TiltCard(
      maxTilt: 0.22,
      radius: 20,
      onTap: onTap,
      child: GlassCard(
        blur: 0,
        radius: 20,
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.16),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.done});

  /// [profile, first interview, resume]
  final List<bool> done;

  @override
  Widget build(BuildContext context) {
    final count = done.where((d) => d).length;
    return GlassCard(
      blur: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ScoreRing(
                value: count / done.length,
                size: 72,
                stroke: 8,
                child: Text(
                  '$count/${done.length}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your journey', style: AppText.display(20)),
                    const SizedBox(height: 4),
                    const Text('Recommended next steps', style: AppText.muted),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ChecklistTile(
            label: 'Complete your profile',
            icon: Icons.badge_rounded,
            done: done[0],
          ),
          ChecklistTile(
            label: 'Run your first mock interview',
            icon: Icons.mic_rounded,
            done: done[1],
          ),
          ChecklistTile(
            label: 'Upload your resume',
            icon: Icons.upload_file_rounded,
            done: done[2],
          ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const StaggeredList(
      gap: 18,
      children: [
        Skeleton(height: 56, radius: 16),
        Skeleton(height: 190, radius: 28),
        Skeleton(height: 96, radius: 20),
        Skeleton(height: 110, radius: 20),
        Skeleton(height: 220, radius: 24),
      ],
    );
  }
}