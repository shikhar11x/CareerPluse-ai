import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/tilt_card.dart';

class _TypeData {
  const _TypeData(this.id, this.title, this.subtitle, this.icon, this.a, this.b);

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color a;
  final Color b;
}

const _types = <_TypeData>[
  _TypeData('technical', 'Technical', 'Concepts & problem solving',
      Icons.code_rounded, AppColors.cyan, Color(0xFF3B82F6)),
  _TypeData('hr', 'HR', 'Motivation & culture fit',
      Icons.groups_rounded, AppColors.violet, Color(0xFFB794FF)),
  _TypeData('behavioral', 'Behavioral', 'Real past situations',
      Icons.forum_rounded, AppColors.pink, Color(0xFFFF8A4C)),
  _TypeData('mixed', 'Mixed', 'A bit of everything',
      Icons.auto_awesome_rounded, AppColors.warning, Color(0xFFFF8A4C)),
];

/// 2x2 grid of interview types. [onPick] receives the type id.
class PracticeGrid extends StatelessWidget {
  const PracticeGrid({super.key, required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    Widget tile(_TypeData t) => Expanded(
          child: _TypeTile(data: t, onTap: () => onPick(t.id)),
        );
    return Column(
      spacing: 12,
      children: [
        Row(spacing: 12, children: [tile(_types[0]), tile(_types[1])]),
        Row(spacing: 12, children: [tile(_types[2]), tile(_types[3])]),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.data, required this.onTap});

  final _TypeData data;
  final VoidCallback onTap;

  static const _radius = 24.0;

  @override
  Widget build(BuildContext context) {
    final d = data;
    return TiltCard(
      radius: _radius,
      maxTilt: 0.12,
      onTap: onTap,
      child: Container(
        height: 128,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              d.a.withValues(alpha: 0.24),
              d.b.withValues(alpha: 0.06),
            ],
          ),
          border: Border.all(color: d.a.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: d.a.withValues(alpha: 0.16),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: Stack(
            children: [
              // Big faint icon as a watermark.
              Positioned(
                right: -14,
                bottom: -18,
                child: Icon(d.icon, size: 96, color: d.a.withValues(alpha: 0.12)),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            gradient: LinearGradient(colors: [d.a, d.b]),
                            boxShadow: [
                              BoxShadow(
                                color: d.a.withValues(alpha: 0.5),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: Icon(d.icon, size: 22, color: Colors.white),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.north_east_rounded,
                          size: 18,
                          color: AppColors.textLo,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      d.title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      d.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.muted.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}