import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_progress_bar.dart';

class QuestionProgress extends StatelessWidget {
  const QuestionProgress({super.key, required this.answered, required this.total});

  final int answered;
  final int total;

  @override
  Widget build(BuildContext context) {
    final current = total == 0 ? 0 : math.min(answered + 1, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Question $current of $total',
              style: const TextStyle(
                color: AppColors.textMid,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
            const Spacer(),
            Text(
              '$answered answered',
              style: const TextStyle(color: AppColors.textLo, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GradientProgressBar(value: total == 0 ? 0 : answered / total),
      ],
    );
  }
}