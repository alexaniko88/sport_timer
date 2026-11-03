import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/shared/presentation/theme/sport_theme.dart';
import 'package:sport_timer/shared/presentation/theme/timer_colors.dart';

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

    testWidgets('drawer rounds the trailing edge in either text direction', (tester) async {
      for (final theme in [SportTheme.light, SportTheme.dark]) {
        for (final direction in TextDirection.values) {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Directionality(
                textDirection: direction,
                child: const Scaffold(body: NavigationDrawer(children: [])),
              ),
            ),
          );

          final drawerMaterial = tester.widget<Material>(
            find.descendant(of: find.byType(Drawer), matching: find.byType(Material)).first,
          );
          final shape = drawerMaterial.shape;
          expect(shape, isNotNull);
          if (shape == null) return;
          final path = shape.getOuterPath(const Rect.fromLTWH(0, 0, 300, 600), textDirection: direction);
          final leadingCorner = direction == TextDirection.ltr ? const Offset(1, 1) : const Offset(299, 1);
          final trailingCorner = direction == TextDirection.ltr ? const Offset(299, 1) : const Offset(1, 1);
          expect(path.contains(leadingCorner), isTrue);
          expect(path.contains(trailingCorner), isFalse);
        }
      }
    });
  });

  group('TimerColors.lerp', () {
    test('returns the first colors at 0', () {
      final result = TimerColors.light.lerp(TimerColors.dark, 0);

      expect(result.preparation, TimerColors.light.preparation);
      expect(result.onAccent, TimerColors.light.onAccent);
      expect(result.onFinished, TimerColors.light.onFinished);
      expect(result.round, TimerColors.light.round);
    });

    test('returns the second colors at 1', () {
      final result = TimerColors.light.lerp(TimerColors.dark, 1);

      expect(result.preparation, TimerColors.dark.preparation);
      expect(result.onAccent, TimerColors.dark.onAccent);
      expect(result.onFinished, TimerColors.dark.onFinished);
      expect(result.round, TimerColors.dark.round);
    });

    test('returns itself when the other is not TimerColors', () {
      expect(TimerColors.light.lerp(null, 0.5), TimerColors.light);
    });
  });
}
