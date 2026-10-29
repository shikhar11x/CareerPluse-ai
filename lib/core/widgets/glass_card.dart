import 'dart:ui';

import 'package:flutter/material.dart';

/// Frosted-glass surface. Set [blur] to 0 for cards inside scrolling lists
/// (backdrop blur is expensive); use blur for the nav bar and overlays.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.blur = 18,
    this.radius = 24,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final double blur;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: shape,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: child,
    );
    if (blur <= 0) return box;
    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: box,
      ),
    );
  }
}