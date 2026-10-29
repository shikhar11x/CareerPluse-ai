import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppText {
  static const muted = TextStyle(
    color: AppColors.textMid,
    fontSize: 14,
    height: 1.4,
  );

  static TextStyle display(double size) => GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: AppColors.textHi,
        height: 1.1,
        letterSpacing: -0.5,
      );
}

abstract final class AppTheme {
  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.violet,
        brightness: Brightness.dark,
        surface: AppColors.surface,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textHi,
        displayColor: AppColors.textHi,
      ),
    );
  }
}