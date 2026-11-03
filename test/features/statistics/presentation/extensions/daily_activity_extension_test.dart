import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/presentation/extensions/daily_activity_extension.dart';

void main() {
  test('formats the stored calendar date with its year', () {
    const activity = DailyActivity(localDate: '2026-10-31', roundCount: 1, workDurationMs: 1000, restDurationMs: 0);

    expect(activity.formattedDate, '31 October 2026');
  });
}
