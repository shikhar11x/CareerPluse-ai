import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';
import 'tilt_card.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.icon,
    this.value = '–',
    this.accent = AppColors.cyan,
  });

  final String label;
  final IconData icon;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return TiltCard(
      maxTilt: 0.22,
      radius: 20,
      child: GlassCard(
        blur: 0,
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 22),
            const SizedBox(height: 12),
            Text(value, style: AppText.display(26)),
            const SizedBox(height: 2),
            Text(label, style: AppText.muted.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}