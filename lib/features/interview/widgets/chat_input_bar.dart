import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  static OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(26),
        borderSide: BorderSide(color: c, width: w),
      );

  @override
  Widget build(BuildContext context) {
    final idle = Colors.white.withValues(alpha: 0.12);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 5,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              cursorColor: AppColors.cyan,
              style: const TextStyle(color: AppColors.textHi, height: 1.35),
              decoration: InputDecoration(
                counterText: '',
                hintText: enabled ? 'Type your answer...' : 'Waiting for the interviewer...',
                hintStyle: const TextStyle(color: AppColors.textLo),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                border: _border(idle),
                enabledBorder: _border(idle),
                disabledBorder: _border(idle),
                focusedBorder: _border(AppColors.cyan, 1.4),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final canSend = enabled && value.text.trim().isNotEmpty;
              return AnimatedOpacity(
                opacity: canSend ? 1 : 0.4,
                duration: const Duration(milliseconds: 180),
                child: GestureDetector(
                  onTap: canSend ? onSend : null,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.brand,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyan.withValues(alpha: 0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}