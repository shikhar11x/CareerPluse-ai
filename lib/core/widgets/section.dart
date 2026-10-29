import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Titled block: header row (+ optional action) above [child].
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: AppText.display(20))),
            if (label != null)
              TextButton(
                onPressed: onAction,
                child: Text(label, style: const TextStyle(color: AppColors.cyan)),
              ),
          ],
        ),
        child,
      ],
    );
  }
}