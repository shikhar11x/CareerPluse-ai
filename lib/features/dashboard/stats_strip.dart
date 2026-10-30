import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_text.dart';
import '../../core/widgets/skeleton.dart';

class StatItem {
  const StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

/// One glass card with several stats separated by thin dividers.
class StatsStrip extends StatelessWidget {
  const StatsStrip({super.key, required this.items, this.loading = false});

  final List<StatItem> items;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        cells.add(Container(
          width: 1,
          height: 58,
          color: Colors.white.withValues(alpha: 0.08),
        ));
      }
      cells.add(Expanded(child: _Stat(item: items[i], loading: loading)));
    }
    return GlassCard(
      blur: 0,
      radius: 24,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
      child: Row(children: cells),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.item, required this.loading});

  final StatItem item;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: item.color.withValues(alpha: 0.16),
          ),
          child: Icon(item.icon, size: 18, color: item.color),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 30,
          child: loading
              ? const Center(child: Skeleton(height: 22, width: 36, radius: 8))
              : GradientText(item.value, style: AppText.display(26)),
        ),
        const SizedBox(height: 2),
        Text(
          item.label,
          style: const TextStyle(color: AppColors.textLo, fontSize: 12),
        ),
      ],
    );
  }
}