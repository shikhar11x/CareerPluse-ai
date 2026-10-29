import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Animated AI "core": pulsing glow, rotating energy ring, glossy sphere.
class AiOrb extends StatefulWidget {
  const AiOrb({super.key, this.size = 120});

  final double size;

  @override
  State<AiOrb> createState() => _AiOrbState();
}

class _AiOrbState extends State<AiOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value * 2 * math.pi;
          final pulse = 1 + 0.05 * math.sin(t);
          return SizedBox(
            width: s,
            height: s,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: s * 0.9,
                    height: s * 0.9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.violet.withValues(alpha: 0.55),
                          blurRadius: s * 0.35,
                        ),
                        BoxShadow(
                          color: AppColors.cyan.withValues(alpha: 0.30),
                          blurRadius: s * 0.5,
                        ),
                      ],
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: t,
                  child: Container(
                    width: s,
                    height: s,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          AppColors.cyan,
                          AppColors.violet,
                          AppColors.pink,
                          AppColors.violet,
                          AppColors.cyan,
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: s * 0.86,
                  height: s * 0.86,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(-0.35, -0.4),
                      radius: 0.95,
                      colors: [
                        Color(0xFFB9A8FF),
                        AppColors.violet,
                        Color(0xFF1B1250),
                      ],
                      stops: [0, 0.5, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: s * 0.2,
                  left: s * 0.26,
                  child: Container(
                    width: s * 0.22,
                    height: s * 0.12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(s),
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}