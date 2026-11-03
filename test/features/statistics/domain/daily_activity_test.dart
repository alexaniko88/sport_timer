import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';

void main() {
  test('daily summaries compare all stored values', () {
    const summary = DailyActivity(localDate: '2026-10-31', roundCount: 2, workDurationMs: 60, restDurationMs: 30);
    const same = DailyActivity(localDate: '2026-10-31', roundCount: 2, workDurationMs: 60, restDurationMs: 30);
    const different = DailyActivity(localDate: '2026-10-31', roundCount: 2, workDurationMs: 60, restDurationMs: 31);

    expect(summary, same);
    expect(summary.hashCode, same.hashCode);
    expect(summary, isNot(different));
    expect(summary.totalDurationMs, 90);
  });
}
