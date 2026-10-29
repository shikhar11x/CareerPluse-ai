import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ChecklistTile extends StatelessWidget {
  const ChecklistTile({
    super.key,
    required this.label,
    required this.icon,
    required this.done,
  });

  final String label;
  final IconData icon;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final accent = done ? AppColors.success : AppColors.cyan;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: accent.withValues(alpha: 0.14),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: done ? AppColors.textLo : AppColors.textHi,
                decoration: done ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.textLo,
              ),
            ),
          ),
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 22,
            color: done ? AppColors.success : AppColors.textLo,
          ),
        ],
      ),
    );
  }
}