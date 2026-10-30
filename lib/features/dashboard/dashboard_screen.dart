import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/action_card.dart';
import '../../core/widgets/ai_orb.dart';
import '../../core/widgets/avatar_badge.dart';
import '../../core/widgets/checklist_tile.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/error_state_card.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_progress_bar.dart';
import '../../core/widgets/info_chip.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/score_ring.dart';
import '../../core/widgets/section.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/tilt_card.dart';
import '../interview/interview_models.dart';
import '../interview/interview_providers.dart';
import '../profile/profile_controller.dart';
import '../profile/profile_model.dart';
import 'practice_grid.dart';
import 'stats_strip.dart';

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

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.profile});

  final Profile? profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = profile;
    final progressState = ref.watch(progressProvider);
    final stats = progressState.asData?.value;
    final loadingStats = progressState.isLoading && stats == null;

    void openInterview([String? type]) {
      final query = type == null
          ? ''
          : '?type=$type&n=${DateTime.now().millisecondsSinceEpoch}';
      context.go('${Routes.interview}$query');
    }

    String show(int? v) => v == null ? '–' : '$v';

    // Profile is complete if we are here; the rest comes from real data.
    final done = [true, (stats?.completedCount ?? 0) > 0, false];

    return StaggeredList(
      children: [
        _Header(
          greeting: _greeting(),
          name: p?.firstName ?? 'there',
          initials: p?.initials ?? '?',
          onAvatar: () => context.go(Routes.profile),
        ),
        TiltCard(
          onTap: openInterview,
          child: _HeroCard(role: p?.targetRole ?? '', onStart: openInterview),
        ),
        Section(
          title: 'Practise by type',
          child: PracticeGrid(onPick: openInterview),
        ),
        TiltCard(
          maxTilt: 0.06,
          radius: 24,
          child: StatsStrip(
            loading: loadingStats,
            items: [
              StatItem(
                label: 'Interviews',
                value: show(stats?.interviewCount),
                icon: Icons.mic_rounded,
                color: AppColors.cyan,
              ),
              StatItem(
                label: 'Completed',
                value: show(stats?.completedCount),
                icon: Icons.task_alt_rounded,
                color: AppColors.success,
              ),
              StatItem(
                label: 'Avg. score',
                value: show(stats?.averageScore),
                icon: Icons.bolt_rounded,
                color: AppColors.warning,
              ),
            ],
          ),
        ),
        ActionCard(
          icon: Icons.description_rounded,
          title: 'Resume analysis',
          subtitle: 'Match your resume to a job description.',
          onTap: () => context.go(Routes.resume),
        ),
        _JourneyCard(done: done),
        Section(
          title: 'Skill progress',
          child: _SkillCard(averages: stats?.averages, loading: loadingStats),
        ),
        Section(
          title: 'Recent interviews',
          actionLabel: 'See all',
          onAction: openInterview,
          child: const _RecentList(),
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
            label: 'Finish your first mock interview',
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

class _SkillCard extends StatelessWidget {
  const _SkillCard({required this.averages, required this.loading});

  final ScoreAverages? averages;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final a = averages;
    if (loading) return const Skeleton(height: 150, radius: 24);
    if (a == null) {
      return const EmptyStateCard(
        icon: Icons.radar_rounded,
        title: 'Your skill radar is empty',
        body: 'Finish your first mock interview and your strengths and gaps appear here.',
      );
    }
    return GlassCard(
      blur: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          _SkillRow('Communication', Icons.chat_bubble_outline_rounded, a.communication, AppColors.cyan),
          _SkillRow('Technical', Icons.code_rounded, a.technical, AppColors.violet),
          _SkillRow('Relevance', Icons.track_changes_rounded, a.relevance, AppColors.pink),
          Text(
            'Average of your AI-estimated scores. Estimates, not verified facts.',
            style: AppText.muted.copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow(this.label, this.icon, this.value, this.color);

  final String label;
  final IconData icon;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            color: color.withValues(alpha: 0.15),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 7,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              GradientProgressBar(value: value / 100),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _RecentList extends ConsumerWidget {
  const _RecentList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(interviewHistoryProvider).when(
          loading: () => const Skeleton(height: 96, radius: 24),
          error: (e, _) => ErrorStateCard(
            message: errorMessage(e),
            onRetry: () => ref.invalidate(interviewHistoryProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyStateCard(
                icon: Icons.history_rounded,
                title: 'No interviews yet',
                body: 'Your scores and transcripts will be listed here.',
              );
            }
            return Column(
              spacing: 10,
              children: [
                for (final item in items.take(3))
                  _RecentRow(
                    item: item,
                    onTap: () => context.push(
                      item.isCompleted
                          ? '${Routes.results}/${item.id}'
                          : '${Routes.room}/${item.id}',
                    ),
                  ),
              ],
            );
          },
        );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.item, required this.onTap});

  final InterviewSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final score = item.overallScore;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: GlassCard(
        blur: 0,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (score != null)
              ScoreRing(
                value: score / 100,
                size: 50,
                stroke: 5,
                child: Text(
                  '$score',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              )
            else
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.warning.withValues(alpha: 0.14),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: AppColors.warning),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.targetRole,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.typeLabel} · ${formatShortDate(item.startedAt)}'
                    '${item.isCompleted ? '' : ' · In progress'}',
                    style: AppText.muted.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLo),
          ],
        ),
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
        Skeleton(height: 270, radius: 24),
        Skeleton(height: 110, radius: 24),
        Skeleton(height: 220, radius: 24),
      ],
    );
  }
}