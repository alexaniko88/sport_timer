import 'package:sport_timer/features/statistics/domain/timer_session.dart';
import 'package:sport_timer/features/templates/domain/built_in_templates.dart';
import 'package:sport_timer/features/templates/domain/workout_template.dart';

extension TimerSessionTemplate on TimerSession {
  TemplateId? get matchingTemplateId {
    for (final template in builtInTemplates) {
      final settings = template.settings;
      if (settings.preparationTime == Duration(milliseconds: preparationDurationMs) &&
          settings.roundTime == Duration(milliseconds: workDurationMs) &&
          settings.restTime == Duration(milliseconds: restDurationMs) &&
          settings.rounds == roundCount) {
        return template.id;
      }
    }
    return null;
  }
}
