import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/error_state_card.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_field.dart';
import '../../core/widgets/info_chip.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/score_ring.dart';
import '../../core/widgets/section.dart';
import '../../core/widgets/select_chips.dart';
import '../../core/widgets/skeleton.dart';
import '../profile/profile_controller.dart';
import 'interview_models.dart';
import 'interview_providers.dart';

class InterviewScreen extends ConsumerStatefulWidget {
  const InterviewScreen({super.key});

  @override
  ConsumerState<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends ConsumerState<InterviewScreen> {
  late final TextEditingController _role;
  String _type = 'technical';
  String _difficulty = 'intermediate';
  int _minutes = 15;
  bool _starting = false;
  String? _error;
  String? _lastQuery;

  @override
  void initState() {
    super.initState();
    _role = TextEditingController(
      text: ref.read(profileProvider).asData?.value?.targetRole ?? '',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Dashboard tiles open this tab as /interview?type=hr&n=<timestamp>.
    final uri = GoRouterState.of(context).uri;
    final type = uri.queryParameters['type'];
    if (type != null &&
        uri.query != _lastQuery &&
        kInterviewTypes.containsKey(type)) {
      _lastQuery = uri.query;
      _type = type;
    }
  }

  @override
  void dispose() {
    _role.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final role = _role.text.trim();
    if (role.isEmpty) {
      setState(() => _error = 'Enter the role you are interviewing for');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final detail = await ref.read(interviewRepositoryProvider).create(
            targetRole: role,
            interviewType: _type,
            difficulty: _difficulty,
            durationMinutes: _minutes,
          );
      ref.invalidate(interviewHistoryProvider);
      if (!mounted) return;
      context.push('${Routes.room}/${detail.interview.id}');
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: StaggeredList(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Text('Mock interview', style: AppText.display(32)),
              const Text(
                'Set it up your way. The AI interviewer adapts to your answers.',
                style: AppText.muted,
              ),
            ],
          ),
          GlassCard(
            blur: 0,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 14,
              children: [
                GlassField(
                  controller: _role,
                  label: 'Target role',
                  icon: Icons.work_outline_rounded,
                  textInputAction: TextInputAction.done,
                ),
                const _Label('Interview type'),
                SelectChips<String>(
                  options: kInterviewTypes,
                  value: _type,
                  onChanged: (v) => setState(() => _type = v),
                ),
                const _Label('Difficulty'),
                SelectChips<String>(
                  options: kDifficulties,
                  value: _difficulty,
                  onChanged: (v) => setState(() => _difficulty = v),
                ),
                _Label('Duration  ·  about ${questionCount(_minutes)} questions'),
                SelectChips<int>(
                  options: kDurations,
                  value: _minutes,
                  onChanged: (v) => setState(() => _minutes = v),
                ),
                const InfoChip(
                  label: 'Text mode. Live voice interviews arrive in Phase 4.',
                  icon: Icons.keyboard_alt_outlined,
                  color: AppColors.violet,
                  maxLines: 2,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  alignment: Alignment.topCenter,
                  child: _error != null
                      ? InfoChip(
                          label: _error!,
                          icon: Icons.error_outline_rounded,
                          color: AppColors.danger,
                          maxLines: 4,
                        )
                      : const SizedBox(width: double.infinity),
                ),
                NeonButton(
                  label: 'Start interview',
                  icon: Icons.play_arrow_rounded,
                  expand: true,
                  isLoading: _starting,
                  onPressed: _start,
                ),
              ],
            ),
          ),
          const Section(title: 'Past interviews', child: _HistoryList()),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(color: AppColors.textMid, fontWeight: FontWeight.w600),
      );
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(interviewHistoryProvider).when(
          loading: () => const Column(
            spacing: 10,
            children: [Skeleton(height: 72), Skeleton(height: 72)],
          ),
          error: (e, _) => ErrorStateCard(
            message: errorMessage(e),
            onRetry: () => ref.invalidate(interviewHistoryProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyStateCard(
                icon: Icons.history_rounded,
                title: 'No interviews yet',
                body: 'Start your first one above. Scores and transcripts will be listed here.',
              );
            }
            return Column(
              spacing: 10,
              children: [
                for (final item in items)
                  _HistoryTile(
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item, required this.onTap});

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
                    '${item.typeLabel} · ${item.difficultyLabel} · ${formatShortDate(item.startedAt)}'
                    '${item.isCompleted ? '' : ' · In progress'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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