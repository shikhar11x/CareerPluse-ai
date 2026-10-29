import 'package:flutter/material.dart';

/// 3D tilt-on-touch/hover card with a moving glare highlight.
/// Uses a raw [Listener] so it never fights the parent ListView's scrolling.
class TiltCard extends StatefulWidget {
  const TiltCard({
    super.key,
    required this.child,
    this.onTap,
    this.maxTilt = 0.15,
    this.radius = 28,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Maximum rotation in radians.
  final double maxTilt;
  final double radius;

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  Offset _t = Offset.zero; // normalized -1..1 from the card centre

  void _update(Offset local) {
    final size = context.size;
    if (size == null || size.isEmpty) return;
    final dx = (local.dx / size.width * 2 - 1).clamp(-1.0, 1.0);
    final dy = (local.dy / size.height * 2 - 1).clamp(-1.0, 1.0);
    setState(() => _t = Offset(dx, dy));
  }

  void _reset() => setState(() => _t = Offset.zero);

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) => _update(e.localPosition),
      onPointerMove: (e) => _update(e.localPosition),
      onPointerUp: (_) => _reset(),
      onPointerCancel: (_) => _reset(),
      child: MouseRegion(
        onHover: (e) => _update(e.localPosition),
        onExit: (_) => _reset(),
        child: GestureDetector(
          onTap: widget.onTap,
          child: TweenAnimationBuilder<Offset>(
            tween: Tween<Offset>(end: _t),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: widget.child,
            builder: (context, v, child) {
              final m = Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateX(-v.dy * widget.maxTilt)
                ..rotateY(v.dx * widget.maxTilt);
              return Transform(
                alignment: Alignment.center,
                transform: m,
                child: Stack(
                  children: [
                    child!,
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(widget.radius),
                            gradient: RadialGradient(
                              center: Alignment(v.dx, v.dy),
                              radius: 0.9,
                              colors: [
                                Colors.white.withValues(alpha: 0.09),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}