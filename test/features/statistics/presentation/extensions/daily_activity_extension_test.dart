import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/presentation/extensions/daily_activity_extension.dart';

void main() {
  test('formats the stored calendar date for each locale', () async {
    await initializeDateFormatting('es');
    const activity = DailyActivity(localDate: '2026-10-31', roundCount: 1, workDurationMs: 1000, restDurationMs: 0);
    expect(activity.formattedDate('en'), 'October 31, 2026');
    expect(activity.formattedDate('es'), '31 de octubre de 2026');
  });
}
