import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AvatarBadge extends StatelessWidget {
  const AvatarBadge({super.key, required this.initials, this.size = 46, this.onTap});

  final String initials;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.brand,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withValues(alpha: 0.45),
              blurRadius: 16,
            ),
          ],
        ),
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.36,
          ),
        ),
      ),
    );
  }
}