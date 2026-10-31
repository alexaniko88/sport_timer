import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/settings/settings_repository.dart';
import 'package:sport_timer/features/templates/built_in_templates.dart';
import 'package:sport_timer/features/templates/workout_template.dart';

void main() {
  group('WorkoutTemplate.totalTime', () {
    test('matches the total for each built-in template', () {
      expect(builtInTemplates.map((template) => template.totalTime), [
        const Duration(minutes: 7, seconds: 20),
        const Duration(minutes: 13, seconds: 30),
        const Duration(minutes: 35, seconds: 50),
        const Duration(minutes: 9, seconds: 55),
        const Duration(minutes: 11, seconds: 40),
      ]);
    });

    test('does not add rest after a single round', () {
      const template = WorkoutTemplate(
        id: TemplateId.standard,
        settings: TimerSettings(
          preparationTime: Duration(seconds: 5),
          roundTime: Duration(seconds: 10),
          restTime: Duration(seconds: 4),
          rounds: 1,
        ),
      );

      expect(template.totalTime, const Duration(seconds: 15));
    });

    test('handles zero rest', () {
      const template = WorkoutTemplate(
        id: TemplateId.standard,
        settings: TimerSettings(
          preparationTime: Duration(seconds: 5),
          roundTime: Duration(seconds: 10),
          restTime: Duration.zero,
          rounds: 3,
        ),
      );

      expect(template.totalTime, const Duration(seconds: 35));
    });

    test('handles zero preparation', () {
      const template = WorkoutTemplate(
        id: TemplateId.standard,
        settings: TimerSettings(
          preparationTime: Duration.zero,
          roundTime: Duration(seconds: 10),
          restTime: Duration(seconds: 4),
          rounds: 3,
        ),
      );

      expect(template.totalTime, const Duration(seconds: 38));
    });
  });
}
