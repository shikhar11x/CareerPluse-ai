import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Light static avatar. A long chat would be slow with an animated orb per bubble.
class InterviewerAvatar extends StatelessWidget {
  const InterviewerAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.brand,
        boxShadow: [
          BoxShadow(color: AppColors.violet.withValues(alpha: 0.45), blurRadius: 12),
        ],
      ),
      child: const Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
    );
  }
}

BoxDecoration interviewerBubbleDecoration() => BoxDecoration(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(6),
        bottomRight: Radius.circular(20),
      ),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    );

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.text, required this.isInterviewer});

  final String text;
  final bool isInterviewer;

  @override
  Widget build(BuildContext context) {
    final maxWidth = math.min(MediaQuery.sizeOf(context).width * 0.78, 520.0);

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: isInterviewer
            ? interviewerBubbleDecoration()
            : BoxDecoration(
                gradient: AppColors.brand,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.violet.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
        child: SelectableText(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isInterviewer ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isInterviewer) ...[const InterviewerAvatar(), const SizedBox(width: 10)],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}