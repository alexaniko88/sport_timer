import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
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
}
