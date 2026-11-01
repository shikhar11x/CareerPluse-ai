import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/ai_orb.dart';
import '../../core/widgets/error_state_card.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/info_chip.dart';
import '../../core/widgets/neon_button.dart';
import 'interview_models.dart';
import 'interview_providers.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/question_progress.dart';
import 'widgets/typing_indicator.dart';

class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen({super.key, required this.interviewId});

  final String interviewId;

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  // Only the timer chip listens to this, so the chat list is not rebuilt every second.
  final _remaining = ValueNotifier<Duration>(Duration.zero);
  Timer? _ticker;

  InterviewDetail? _detail;
  List<ChatMessage> _messages = [];
  int _answered = 0;
  int _total = 0;
  bool _done = false;
  bool _loading = true;
  String? _loadError;

  bool _sending = false;
  bool _finishing = false;
  String? _pending; // answer shown optimistically while the AI replies
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _remaining.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _id => widget.interviewId;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final d = await ref.read(interviewRepositoryProvider).detail(_id);
      if (!mounted) return;
      if (d.interview.isCompleted) {
        context.pushReplacement('${Routes.results}/$_id');
        return;
      }
      setState(() {
        _detail = d;
        _messages = [...d.messages];
        _total = d.totalQuestions;
        _answered = d.answeredCount;
        _done = d.totalQuestions > 0 && d.answeredCount >= d.totalQuestions;
        _loading = false;
      });
      _startTimer(d.interview);
      _scrollToEnd();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = errorMessage(e);
          _loading = false;
        });
      }
    }
  }

  void _startTimer(InterviewSummary i) {
    _ticker?.cancel();
    final end = i.startedAt.add(Duration(minutes: i.durationMinutes));
    void tick() => _remaining.value = end.difference(DateTime.now());
    tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending || _done) return;
    setState(() {
      _sending = true;
      _error = null;
      _pending = text;
    });
    _scrollToEnd();
    try {
      final r = await ref.read(interviewRepositoryProvider).answer(_id, text);
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, ...r.messages];
        _answered = r.answered;
        _total = r.totalQuestions;
        _done = r.done;
        _pending = null;
        _input.clear();
      });
    } catch (e) {
      // Nothing was saved on the server, so the text stays in the box to resend.
      if (mounted) {
        setState(() {
          _error = errorMessage(e);
          _pending = null;
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  Future<void> _finish({required bool confirm}) async {
    if (_finishing || _sending) return;
    if (_answered == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer at least one question first.')),
      );
      return;
    }
    if (confirm) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('End interview?'),
          content: Text(
            'You will get feedback on the $_answered answer${_answered == 1 ? '' : 's'} so far.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep going'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('End & get feedback'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() {
      _finishing = true;
      _error = null;
    });
    try {
      await ref.read(interviewRepositoryProvider).complete(_id);
      ref.invalidate(interviewHistoryProvider);
      ref.invalidate(progressProvider);
      if (!mounted) return;
      context.pushReplacement('${Routes.results}/$_id');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = errorMessage(e);
          _finishing = false;
        });
      }
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.interview);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _TopBar(
                  interview: _detail?.interview,
                  remaining: _remaining,
                  onBack: _back,
                  onEnd: () => _finish(confirm: true),
                ),
                Expanded(child: _content()),
              ],
            ),
            if (_finishing) const _AnalysingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.cyan));
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ErrorStateCard(message: _loadError!, onRetry: _load),
        ),
      );
    }

    final extra = (_pending != null ? 1 : 0) + (_sending ? 1 : 0);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
          child: QuestionProgress(answered: _answered, total: _total),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: _messages.length + extra,
            itemBuilder: (context, i) {
              if (i < _messages.length) {
                final m = _messages[i];
                return ChatBubble(
                  key: ValueKey(m.id),
                  text: m.content,
                  isInterviewer: m.isInterviewer,
                );
              }
              if (_pending != null && i == _messages.length) {
                return ChatBubble(
                  key: const ValueKey('pending'),
                  text: _pending!,
                  isInterviewer: false,
                );
              }
              return const TypingIndicator(key: ValueKey('typing'));
            },
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.topCenter,
          child: _error != null
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: InfoChip(
                    label: _error!,
                    icon: Icons.error_outline_rounded,
                    color: AppColors.danger,
                    maxLines: 4,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        if (_done)
          _FinishBar(loading: _finishing, onFinish: () => _finish(confirm: false))
        else
          ChatInputBar(
            controller: _input,
            enabled: !_sending && !_finishing,
            onSend: _send,
          ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.interview,
    required this.remaining,
    required this.onBack,
    required this.onEnd,
  });

  final InterviewSummary? interview;
  final ValueListenable<Duration> remaining;
  final VoidCallback onBack;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final i = interview;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textHi),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i?.targetRole ?? 'Interview',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                if (i != null)
                  Text(
                    '${i.typeLabel} · ${i.difficultyLabel}',
                    style: AppText.muted.copyWith(fontSize: 12),
                  ),
              ],
            ),
          ),
          if (i != null) ...[
            ValueListenableBuilder<Duration>(
              valueListenable: remaining,
              builder: (context, left, _) => _TimerChip(left: left),
            ),
            TextButton(
              onPressed: onEnd,
              child: const Text(
                'End',
                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.left});

  final Duration left;

  @override
  Widget build(BuildContext context) {
    final color = left <= Duration.zero
        ? AppColors.danger
        : left.inSeconds < 60
            ? AppColors.warning
            : AppColors.cyan;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            formatClock(left),
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _FinishBar extends StatelessWidget {
  const _FinishBar({required this.loading, required this.onFinish});

  final bool loading;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: GlassCard(
        blur: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            const Text(
              'That was the last question',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const Text(
              'Finish to see your scores, missed concepts and improved answers.',
              style: AppText.muted,
            ),
            const SizedBox(height: 4),
            NeonButton(
              label: 'Get my feedback',
              icon: Icons.insights_rounded,
              expand: true,
              isLoading: loading,
              onPressed: onFinish,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysingOverlay extends StatelessWidget {
  const _AnalysingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.6),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AiOrb(size: 96),
                SizedBox(height: 24),
                Text(
                  'Analysing your answers...',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                SizedBox(height: 6),
                Text('This usually takes a few seconds.', style: AppText.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}