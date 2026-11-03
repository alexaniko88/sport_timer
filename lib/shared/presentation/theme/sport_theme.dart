import 'package:flutter/material.dart';
import 'package:sport_timer/shared/presentation/theme/app_palette.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';
import 'package:sport_timer/shared/presentation/theme/timer_colors.dart';

abstract final class SportTheme {
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

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.r12),
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[timerColors],
      appBarTheme: AppBarTheme(backgroundColor: barColor),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: barColor,
        unselectedItemColor: colorScheme.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: buttonShape)),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: buttonShape)),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: buttonShape)),
      drawerTheme: const DrawerThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.horizontal(end: Radius.circular(AppRadius.r20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r20),
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
