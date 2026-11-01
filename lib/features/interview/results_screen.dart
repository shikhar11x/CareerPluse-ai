import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/entrance.dart';
import '../../core/widgets/error_state_card.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/info_chip.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/score_ring.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/tilt_card.dart';
import 'interview_models.dart';
import 'interview_providers.dart';
import 'widgets/chat_bubble.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key, required this.interviewId});

  final String interviewId;

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  InterviewDetail? _detail;
  bool _loading = true;
  bool _deleting = false;
  String? _error;

  String get _id => widget.interviewId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await ref.read(interviewRepositoryProvider).detail(_id);
      if (mounted) setState(() => _detail = d);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete this interview?'),
        content: const Text('The transcript and your scores will be removed for good.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _deleting = true);
    try {
      await ref.read(interviewRepositoryProvider).delete(_id);
      ref.invalidate(interviewHistoryProvider);
      ref.invalidate(progressProvider);
      if (!mounted) return;
      context.go(Routes.interview);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: _content()));
  }

  Widget _content() {
    if (_loading) {
      return const StaggeredList(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 40),
        gap: 18,
        children: [
          Skeleton(height: 56, radius: 16),
          Skeleton(height: 320, radius: 28),
          Skeleton(height: 120, radius: 24),
        ],
      );
    }
    final d = _detail;
    if (_error != null || d == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ErrorStateCard(message: _error ?? 'Not found', onRetry: _load),
        ),
      );
    }
    final f = d.feedback;
    if (f == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            blur: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                const Icon(Icons.hourglass_empty_rounded, size: 38, color: AppColors.warning),
                const Text(
                  'This interview is not finished yet',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                NeonButton(
                  label: 'Continue interview',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => context.pushReplacement('${Routes.room}/$_id'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return StaggeredList(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      gap: 18,
      children: [
        _Header(interview: d.interview, onBack: _back),
        TiltCard(radius: 28, maxTilt: 0.08, child: _ScoreHero(feedback: f)),
        const InfoChip(
          label: 'AI-generated estimate, not a verified fact or a hiring prediction. '
              'Overall = 30% communication + 40% technical + 30% relevance.',
          icon: Icons.info_outline_rounded,
          color: AppColors.warning,
          maxLines: 5,
        ),
        if (f.strengths.isNotEmpty)
          _BulletCard(
            title: 'Strong points',
            icon: Icons.thumb_up_alt_rounded,
            color: AppColors.success,
            bullet: Icons.check_circle_rounded,
            items: f.strengths,
          ),
        if (f.weaknesses.isNotEmpty)
          _BulletCard(
            title: 'Weak areas',
            icon: Icons.trending_down_rounded,
            color: AppColors.danger,
            bullet: Icons.remove_circle_outline_rounded,
            items: f.weaknesses,
          ),
        if (f.missedConcepts.isNotEmpty) _MissedConcepts(items: f.missedConcepts),
        if (f.improvedAnswers.isNotEmpty) _ImprovedAnswers(items: f.improvedAnswers),
        if (f.nextSteps.isNotEmpty)
          _BulletCard(
            title: 'Next steps',
            icon: Icons.flag_rounded,
            color: AppColors.cyan,
            bullet: Icons.arrow_circle_right_rounded,
            items: f.nextSteps,
          ),
        _TranscriptCard(messages: d.messages),
        Column(
          spacing: 8,
          children: [
            NeonButton(
              label: 'Practise again',
              icon: Icons.replay_rounded,
              expand: true,
              onPressed: () => context.go(Routes.interview),
            ),
            TextButton.icon(
              onPressed: _deleting ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
              label: const Text(
                'Delete this interview',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

(String, Color) _band(int score) {
  if (score >= 85) return ('Excellent', AppColors.success);
  if (score >= 70) return ('Strong performance', AppColors.cyan);
  if (score >= 50) return ('Good start', AppColors.warning);
  return ('Needs more practice', AppColors.danger);
}

class _Header extends StatelessWidget {
  const _Header({required this.interview, required this.onBack});

  final InterviewSummary interview;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textHi),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your results', style: AppText.display(28)),
              const SizedBox(height: 4),
              Text(
                '${interview.targetRole} · ${interview.typeLabel} · '
                '${formatShortDate(interview.completedAt ?? interview.startedAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.muted.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.feedback});

  final InterviewFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final f = feedback;
    final (label, color) = _band(f.overallScore);
    return GlassCard(
      blur: 0,
      radius: 28,
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          ScoreRing(
            value: f.overallScore / 100,
            size: 160,
            stroke: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${f.overallScore}', style: AppText.display(48)),
                Text('out of 100', style: AppText.muted.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(label, style: AppText.display(22).copyWith(color: color)),
          const SizedBox(height: 22),
          Row(
            spacing: 8,
            children: [
              Expanded(child: _MiniScore('Communication', f.communicationScore)),
              Expanded(child: _MiniScore('Technical', f.technicalScore)),
              Expanded(child: _MiniScore('Relevance', f.relevanceScore)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  const _MiniScore(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScoreRing(
          value: value / 100,
          size: 66,
          stroke: 6,
          child: Text('$value', style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppText.muted.copyWith(fontSize: 11.5),
        ),
      ],
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.title, this.icon, this.color);

  final String title;
  final IconData icon;
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
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 12),
        Text(title, style: AppText.display(19)),
      ],
    );
  }
}

class _BulletCard extends StatelessWidget {
  const _BulletCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.bullet,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final IconData bullet;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          _CardTitle(title, icon, color),
          for (final item in items)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(bullet, size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(item, style: const TextStyle(height: 1.4))),
              ],
            ),
        ],
      ),
    );
  }
}

class _MissedConcepts extends StatelessWidget {
  const _MissedConcepts({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          const _CardTitle('Missed concepts', Icons.lightbulb_outline_rounded, AppColors.violet),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in items) InfoChip(label: c, color: AppColors.violet, maxLines: 2),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImprovedAnswers extends StatelessWidget {
  const _ImprovedAnswers({required this.items});

  final List<ImprovedAnswer> items;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          const _CardTitle('Suggested improved answers', Icons.auto_fix_high_rounded, AppColors.pink),
          for (final a in items)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    a.question,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMid,
                    ),
                  ),
                  Text(a.suggestion, style: const TextStyle(height: 1.45)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TranscriptCard extends StatefulWidget {
  const _TranscriptCard({required this.messages});

  final List<ChatMessage> messages;

  @override
  State<_TranscriptCard> createState() => _TranscriptCardState();
}

class _TranscriptCardState extends State<_TranscriptCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _open = !_open),
            child: Row(
              children: [
                const Expanded(
                  child: _CardTitle('Transcript', Icons.chat_rounded, AppColors.textMid),
                ),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(Icons.expand_more_rounded, color: AppColors.textLo),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        for (final m in widget.messages)
                          ChatBubble(text: m.content, isInterviewer: m.isInterviewer),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}