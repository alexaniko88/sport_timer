import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/settings/settings_repository.dart';
import 'package:sport_timer/features/templates/built_in_templates.dart';
import 'package:sport_timer/features/templates/workout_template.dart';

void main() {
  test('contains the five built-in templates in order with their settings', () {
    expect(builtInTemplates.map((template) => (template.id, template.settings)), [
      (
        TemplateId.standard,
        const TimerSettings(
          preparationTime: Duration(seconds: 20),
          roundTime: Duration(minutes: 1),
          restTime: Duration(seconds: 30),
          rounds: 5,
        ),
      ),
      (
        TemplateId.fullAbs,
        const TimerSettings(
          preparationTime: Duration(seconds: 20),
          roundTime: Duration(seconds: 30),
          restTime: Duration(seconds: 10),
          rounds: 20,
        ),
      ),
      (
        TemplateId.hyrox,
        const TimerSettings(
          preparationTime: Duration(seconds: 20),
          roundTime: Duration(minutes: 4),
          restTime: Duration(seconds: 30),
          rounds: 8,
        ),
      ),
      (
        TemplateId.stretching,
        const TimerSettings(
          preparationTime: Duration(seconds: 10),
          roundTime: Duration(seconds: 45),
          restTime: Duration(seconds: 15),
          rounds: 10,
        ),
      ),
      (
        TemplateId.strength,
        const TimerSettings(
          preparationTime: Duration(seconds: 10),
          roundTime: Duration(seconds: 40),
          restTime: Duration(minutes: 1, seconds: 30),
          rounds: 6,
        ),
      ),
    ]);
  });
}
