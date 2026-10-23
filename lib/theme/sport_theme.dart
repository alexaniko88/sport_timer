import 'package:flutter/material.dart';
import 'package:sport_timer/theme/app_palette.dart';
import 'package:sport_timer/theme/app_spacing.dart';
import 'package:sport_timer/theme/timer_colors.dart';

abstract final class SportTheme {
  static const double _buttonHeight = 50;
  static const double _buttonMinWidth = 64;
  static const double _cardElevation = 4;

  static ThemeData get light => _build(
        brightness: Brightness.light,
        timerColors: TimerColors.light,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        timerColors: TimerColors.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required TimerColors timerColors,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppPalette.brand,
      brightness: brightness,
    );
    final base = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
    );
    final barColor = brightness == Brightness.light ? colorScheme.inversePrimary : colorScheme.surfaceContainer;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.r10),
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.r10),
    );
    final buttonTextStyle = base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    const buttonMinimumSize = Size(_buttonMinWidth, _buttonHeight);

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[timerColors],
      appBarTheme: AppBarTheme(backgroundColor: barColor),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: barColor,
        unselectedItemColor: colorScheme.onSurfaceVariant,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: buttonShape,
          minimumSize: buttonMinimumSize,
          textStyle: buttonTextStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: buttonShape,
          minimumSize: buttonMinimumSize,
          textStyle: buttonTextStyle,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: _cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        modalBarrierColor: colorScheme.scrim.withValues(alpha: 0.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r20)),
        ),
      ),
    );
  }
}
