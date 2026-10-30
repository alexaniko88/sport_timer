import 'package:flutter/material.dart';
import 'package:sport_timer/theme/app_palette.dart';
import 'package:sport_timer/theme/app_spacing.dart';
import 'package:sport_timer/theme/timer_colors.dart';

abstract final class SportTheme {
  static const double _cardElevation = 4;
  // Larger than the Material 3 default of 56 on purpose, because the start button is the main action.
  static const double _extendedFabHeight = 80;

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
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        extendedSizeConstraints: const BoxConstraints.tightFor(height: _extendedFabHeight),
        extendedTextStyle: base.textTheme.titleMedium,
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
