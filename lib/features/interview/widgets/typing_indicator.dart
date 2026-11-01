import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'chat_bubble.dart';

/// Three bouncing dots inside an interviewer bubble.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _dot(int i) {
    final t = (_c.value - i * 0.18) % 1.0;
    final amp = math.sin(t * math.pi);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Opacity(
        opacity: 0.35 + 0.65 * amp,
        child: Transform.translate(
          offset: Offset(0, -4 * amp),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const InterviewerAvatar(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: interviewerBubbleDecoration(),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [_dot(0), _dot(1), _dot(2)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}