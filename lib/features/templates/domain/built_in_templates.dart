import 'package:sport_timer/features/settings/domain/timer_settings.dart';
import 'package:sport_timer/features/templates/domain/workout_template.dart';

const List<WorkoutTemplate> builtInTemplates = [
  WorkoutTemplate(
    id: TemplateId.standard,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(minutes: 1),
      restTime: Duration(seconds: 30),
      rounds: 12,
    ),
  ),
  WorkoutTemplate(
    id: TemplateId.fullAbs,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(seconds: 40),
      restTime: Duration(seconds: 10),
      rounds: 12,
    ),
  ),
  WorkoutTemplate(
    id: TemplateId.hyrox,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(minutes: 5),
      restTime: Duration(minutes: 1),
      rounds: 8,
    ),
  ),
  WorkoutTemplate(
    id: TemplateId.stretching,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(minutes: 1),
      restTime: Duration(seconds: 5),
      rounds: 10,
    ),
  ),
  WorkoutTemplate(
    id: TemplateId.strength,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(minutes: 1, seconds: 30),
      restTime: Duration(seconds: 30),
      rounds: 8,
    ),
  ),
];
