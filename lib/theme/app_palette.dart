import 'package:flutter/material.dart';

/// Raw colors. Widgets never read these directly: they go through the theme.
abstract final class AppPalette {
  static const Color brand = Color(0xFFFF5252);
  static const Color transparent = Color(0x00000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkOnAccent = Color(0xFF1B1B1B);

  // Light tints, the same hues the app used before the dark theme.
  static const Color yellow = Color(0xFFFFEB3B);
  static const Color redAccent = Color(0xFFFF5252);
  static const Color blueAccent = Color(0xFF448AFF);
  static const Color green = Color(0xFF4CAF50);
  static const Color orangeAccent = Color(0xFFFFAB40);
  static const Color orange = Color(0xFFFF9800);
  static const Color blue = Color(0xFF2196F3);
  static const Color red = Color(0xFFF44336);

  // Dark tints, lighter so they stay readable on a dark surface.
  static const Color yellowLight = Color(0xFFFFE082);
  static const Color redAccentLight = Color(0xFFFF8A80);
  static const Color blueAccentLight = Color(0xFF82B1FF);
  static const Color greenDark = Color(0xFF2E7D32);
  static const Color greenLight = Color(0xFF81C784);
  static const Color orangeAccentLight = Color(0xFFFFB74D);
  static const Color orangeLight = Color(0xFFFFA726);
  static const Color blueLight = Color(0xFF64B5F6);
  static const Color redLight = Color(0xFFE57373);
}
