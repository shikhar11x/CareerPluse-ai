import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Slowly drifting colour blobs behind the whole app.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _blob(Color color, Offset center, double d) {
    return Positioned(
      left: center.dx - d / 2,
      top: center.dy - d / 2,
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final d = size.width * 1.1;
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AppColors.bg)),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final t = _c.value * 2 * math.pi;

                  return Stack(
                    fit: StackFit.expand,

                    children: [
                      _blob(
                        AppColors.violet,
                        Offset(
                          size.width * (0.15 + 0.10 * math.sin(t)),
                          size.height * (0.10 + 0.05 * math.cos(t)),
                        ),
                        d,
                      ),
                      _blob(
                        AppColors.cyan,
                        Offset(
                          size.width * (0.90 + 0.08 * math.cos(t)),
                          size.height * (0.45 + 0.08 * math.sin(t)),
                        ),
                        d * 0.8,
                      ),
                      _blob(
                        AppColors.pink,
                        Offset(
                          size.width * (0.25 + 0.10 * math.sin(t + 2)),
                          size.height * (0.95 + 0.04 * math.cos(t)),
                        ),
                        d * 0.9,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}
