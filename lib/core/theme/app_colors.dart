import 'package:flutter/material.dart';

abstract final class AppColors {
  static const bg = Color(0xFF070A14);
  static const surface = Color(0xFF0E1324);

  static const violet = Color(0xFF7C5CFF);
  static const cyan = Color(0xFF22D3EE);
  static const pink = Color(0xFFFF4D8D);

  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFFBBF24);
  static const danger = Color(0xFFFF5C7A);

  static const textHi = Color(0xFFF4F6FF);
  static const textMid = Color(0xFFB6BCD6);
  static const textLo = Color(0xFF7A829E);

  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, cyan],
  );

  static const hot = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink, Color(0xFFFF8A4C)],
  );

  static const aqua = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, pink],
  );
}