import 'package:sport_timer/features/settings/settings_repository.dart';
import 'package:sport_timer/features/templates/workout_template.dart';

const List<WorkoutTemplate> builtInTemplates = [
  WorkoutTemplate(
    id: TemplateId.standard,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(minutes: 1),
      restTime: Duration(seconds: 30),
      rounds: 5,
    ),
  ),
  WorkoutTemplate(
    id: TemplateId.fullAbs,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(seconds: 30),
      restTime: Duration(seconds: 10),
      rounds: 20,
    ),
  ),
  WorkoutTemplate(
    id: TemplateId.hyrox,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(minutes: 4),
      restTime: Duration(seconds: 30),
      rounds: 8,
    ),
  ),
  WorkoutTemplate(
    id: TemplateId.stretching,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 10),
      roundTime: Duration(seconds: 45),
      restTime: Duration(seconds: 15),
      rounds: 10,
    ),
  ),
  WorkoutTemplate(
    id: TemplateId.strength,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 10),
      roundTime: Duration(seconds: 40),
      restTime: Duration(minutes: 1, seconds: 30),
      rounds: 6,
    ),
  ),
];
