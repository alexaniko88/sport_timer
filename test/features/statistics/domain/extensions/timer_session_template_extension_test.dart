import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/settings/domain/timer_settings.dart';
import 'package:sport_timer/features/statistics/domain/extensions/timer_session_template_extension.dart';
import 'package:sport_timer/features/statistics/domain/timer_session.dart';
import 'package:sport_timer/features/templates/domain/built_in_templates.dart';

TimerSession sessionFor(
  TimerSettings settings, {
  int preparationExtraMs = 0,
  int workExtraMs = 0,
  int restExtraMs = 0,
  int roundsExtra = 0,
}) =>
    TimerSession(
      id: 'session',
      accountId: 'account',
      startedAtUtcMs: 0,
      preparationDurationMs: settings.preparationTime.inMilliseconds + preparationExtraMs,
      workDurationMs: settings.roundTime.inMilliseconds + workExtraMs,
      restDurationMs: settings.restTime.inMilliseconds + restExtraMs,
      roundCount: settings.rounds + roundsExtra,
    );

void main() {
  test('every built-in template matches its id', () {
    for (final template in builtInTemplates) {
      expect(sessionFor(template.settings).matchingTemplateId, template.id);
    }
  });

  test('a change in preparation, work, rest or rounds gives null', () {
    final settings = builtInTemplates.first.settings;
    expect(sessionFor(settings, preparationExtraMs: 1000).matchingTemplateId, isNull);
    expect(sessionFor(settings, workExtraMs: 1000).matchingTemplateId, isNull);
    expect(sessionFor(settings, restExtraMs: 1000).matchingTemplateId, isNull);
    expect(sessionFor(settings, roundsExtra: 1).matchingTemplateId, isNull);
  });
}
