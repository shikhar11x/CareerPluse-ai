import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import 'neon_button.dart';

class ErrorStateCard extends StatelessWidget {
  const ErrorStateCard({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 0,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 38, color: AppColors.danger),
          const SizedBox(height: 12),
          const Text("Couldn't load your data",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: AppText.muted),
          const SizedBox(height: 18),
          NeonButton(label: 'Try again', icon: Icons.refresh_rounded, onPressed: onRetry),
        ],
      ),
    );
  }
}