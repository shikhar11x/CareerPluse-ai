import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// Honest "not built yet" screen for tabs whose phase hasn't started.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.phase,
  });

  final String title;
  final IconData icon;
  final String phase;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: GlassCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 44, color: AppColors.cyan),
                const SizedBox(height: 16),
                Text(title, style: AppText.display(24)),
                const SizedBox(height: 8),
                Text(
                  'Arrives in $phase.',
                  textAlign: TextAlign.center,
                  style: AppText.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}