import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/domain/run_activity_summary.dart';
import 'package:sport_timer/features/statistics/domain/timer_session.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_state.dart';

void main() {
  test('state snapshots and compares summaries and can clear an error', () {
    const activity = DailyActivity(localDate: '2026-10-31', roundCount: 2, workDurationMs: 60, restDurationMs: 30);
    final source = [activity];
    final state = StatisticsState(status: StatisticsStatus.content, dailyActivity: source, errorMessage: 'error');
    final equal = StatisticsState(status: StatisticsStatus.content, dailyActivity: [activity], errorMessage: 'error');
    source.clear();

    expect(state.dailyActivity, [activity]);
    expect(() => state.dailyActivity.clear(), throwsUnsupportedError);
    expect(state, equal);
    expect(state.hashCode, equal.hashCode);
    expect(state.copyWith(clearError: true).errorMessage, isNull);
    expect(state.copyWith(status: StatisticsStatus.empty), isNot(state));
  });

  test('compares the open day fields and clears them', () {
    const activity = DailyActivity(localDate: '2026-10-31', roundCount: 2, workDurationMs: 60, restDurationMs: 30);
    const run = RunActivitySummary(
      session: TimerSession(
        id: 'a',
        accountId: 'account',
        startedAtUtcMs: 0,
        preparationDurationMs: 0,
        workDurationMs: 60,
        restDurationMs: 30,
        roundCount: 2,
      ),
      activity: activity,
    );
    final base = StatisticsState();
    final open = base.copyWith(expandedDate: '2026-10-31', dayStatus: StatisticsStatus.content, dayRuns: [run]);

    expect(open, base.copyWith(expandedDate: '2026-10-31', dayStatus: StatisticsStatus.content, dayRuns: [run]));
    final same = base.copyWith(expandedDate: '2026-10-31', dayStatus: StatisticsStatus.content, dayRuns: [run]);
    expect(open.hashCode, same.hashCode);
    expect(open, isNot(base.copyWith(expandedDate: '2026-11-01', dayStatus: StatisticsStatus.content, dayRuns: [run])));
    expect(open, isNot(base.copyWith(expandedDate: '2026-10-31', dayStatus: StatisticsStatus.error, dayRuns: [run])));
    expect(open, isNot(base.copyWith(expandedDate: '2026-10-31', dayStatus: StatisticsStatus.content)));
    expect(() => open.dayRuns.clear(), throwsUnsupportedError);

    final cleared = open.copyWith(clearExpanded: true);
    expect(cleared.expandedDate, isNull);
    expect(cleared.dayStatus, StatisticsStatus.initial);
    expect(cleared.dayRuns, isEmpty);
  });
}
