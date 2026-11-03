import 'package:flutter/material.dart';

extension AppTextThemeExtension on TextTheme {
  TextStyle get tileTitle => (titleMedium ?? const TextStyle()).copyWith(fontWeight: FontWeight.bold);

  TextStyle get tileSecondary => bodySmall ?? const TextStyle();

  TextStyle get tileValue => (headlineSmall ?? const TextStyle()).copyWith(fontWeight: FontWeight.w700);

  TextStyle get emphasizedLabel => (titleMedium ?? const TextStyle()).copyWith(fontWeight: FontWeight.w500);
}
