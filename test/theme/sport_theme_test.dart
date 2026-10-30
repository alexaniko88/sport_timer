import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/theme/sport_theme.dart';
import 'package:sport_timer/theme/timer_colors.dart';

void main() {
  group('SportTheme', () {
    test('light theme has a light brightness and the TimerColors extension', () {
      final theme = SportTheme.light;

      expect(theme.brightness, Brightness.light);
      expect(theme.extension<TimerColors>(), TimerColors.light);
    });

    test('dark theme has a dark brightness and the TimerColors extension', () {
      final theme = SportTheme.dark;

      expect(theme.brightness, Brightness.dark);
      expect(theme.extension<TimerColors>(), TimerColors.dark);
    });
  });

  group('TimerColors.lerp', () {
    test('returns the first colors at 0', () {
      final result = TimerColors.light.lerp(TimerColors.dark, 0);

      expect(result.preparation, TimerColors.light.preparation);
      expect(result.onAccent, TimerColors.light.onAccent);
      expect(result.onFinished, TimerColors.light.onFinished);
      expect(result.progressEnd, TimerColors.light.progressEnd);
    });

    test('returns the second colors at 1', () {
      final result = TimerColors.light.lerp(TimerColors.dark, 1);

      expect(result.preparation, TimerColors.dark.preparation);
      expect(result.onAccent, TimerColors.dark.onAccent);
      expect(result.onFinished, TimerColors.dark.onFinished);
      expect(result.progressEnd, TimerColors.dark.progressEnd);
    });

    test('returns itself when the other is not TimerColors', () {
      expect(TimerColors.light.lerp(null, 0.5), TimerColors.light);
    });
  });
}
