import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/statistics/timer_session.dart';

TimerSession session({
  String id = 'session',
  String accountId = 'account',
  int startedAtUtcMs = 1,
  int preparationDurationMs = 2,
  int workDurationMs = 3,
  int restDurationMs = 4,
  int roundCount = 5,
  int? endedAtUtcMs,
}) =>
    TimerSession(
      id: id,
      accountId: accountId,
      startedAtUtcMs: startedAtUtcMs,
      preparationDurationMs: preparationDurationMs,
      workDurationMs: workDurationMs,
      restDurationMs: restDurationMs,
      roundCount: roundCount,
      endedAtUtcMs: endedAtUtcMs,
    );

void main() {
  test('sessions with the same values are equal and have the same hash', () {
    final first = session();
    final second = session();
    expect(first, equals(second));
    expect(first.hashCode, second.hashCode);
    expect({first}.contains(second), isTrue);
  });

  test('each field contributes to session equality', () {
    final baseline = session();
    final different = [
      session(id: 'other'),
      session(accountId: 'other'),
      session(startedAtUtcMs: 10),
      session(preparationDurationMs: 10),
      session(workDurationMs: 10),
      session(restDurationMs: 10),
      session(roundCount: 10),
      session(endedAtUtcMs: 10),
    ];
    for (final value in different) {
      expect(value, isNot(equals(baseline)));
    }
  });
}
