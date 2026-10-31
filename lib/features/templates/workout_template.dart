import 'package:sport_timer/features/settings/settings_repository.dart';

enum TemplateId {
  standard,
  fullAbs,
  hyrox,
  stretching,
  strength,
}

class WorkoutTemplate {
  final TemplateId id;
  final TimerSettings settings;

  const WorkoutTemplate({required this.id, required this.settings});

  Duration get totalTime =>
      settings.preparationTime + settings.roundTime * settings.rounds + settings.restTime * (settings.rounds - 1);
}
