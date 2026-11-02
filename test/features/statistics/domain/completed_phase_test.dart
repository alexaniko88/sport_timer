import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/statistics/domain/completed_phase.dart';

CompletedPhase phase({
  String id = 'phase',
  String runId = 'session',
  int schedulePosition = 0,
  CompletedPhaseType type = CompletedPhaseType.work,
  int roundNumber = 1,
  int durationMs = 2,
  int completedAtUtcMs = 3,
  String localCompletionDate = '2026-11-02',
  int utcOffsetMinutes = 60,
}) =>
    CompletedPhase(
      id: id,
      runId: runId,
      schedulePosition: schedulePosition,
      type: type,
      roundNumber: roundNumber,
      durationMs: durationMs,
      completedAtUtcMs: completedAtUtcMs,
      localCompletionDate: localCompletionDate,
      utcOffsetMinutes: utcOffsetMinutes,
    );

void main() {
  test('phases with the same values are equal and have the same hash', () {
    final first = phase();
    final second = phase();
    expect(first, equals(second));
    expect(first.hashCode, second.hashCode);
    expect({first}.contains(second), isTrue);
  });

  test('each field contributes to phase equality', () {
    final baseline = phase();
    final different = [
      phase(id: 'other'),
      phase(runId: 'other'),
      phase(schedulePosition: 1),
      phase(type: CompletedPhaseType.rest),
      phase(roundNumber: 2),
      phase(durationMs: 10),
      phase(completedAtUtcMs: 10),
      phase(localCompletionDate: '2026-11-03'),
      phase(utcOffsetMinutes: 120),
    ];
    for (final value in different) {
      expect(value, isNot(equals(baseline)));
    }
  });
}
