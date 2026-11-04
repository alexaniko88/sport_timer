import 'package:sport_timer/features/statistics/domain/activity_chart_data.dart';
import 'package:sport_timer/features/statistics/domain/activity_period.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';

extension DailyActivityListExtension on List<DailyActivity> {
  ActivityChartData chartData({required ActivityPeriod period, required DateTime today}) {
    final todayDate = DateTime.utc(today.year, today.month, today.day);
    final byDate = {for (final activity in this) activity.localDate: activity};
    final days = <ActivityChartDay>[];
    for (var date = period.start; date.isBefore(period.endExclusive);) {
      final key = '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      final activity = byDate[key];
      days.add(
        ActivityChartDay(
          date: date,
          roundCount: activity?.roundCount ?? 0,
          workDurationMs: activity?.workDurationMs ?? 0,
          restDurationMs: activity?.restDurationMs ?? 0,
          hasRecordedActivity: activity != null,
          isFuture: date.isAfter(todayDate),
        ),
      );
      date = DateTime.utc(date.year, date.month, date.day + 1);
    }

    final buckets = <ActivityChartBucket>[];
    if (period.unit == ActivityPeriodUnit.year) {
      for (var month = 1; month <= 12; month++) {
        final start = DateTime.utc(period.start.year, month);
        final end = DateTime.utc(period.start.year, month + 1);
        buckets.add(
          ActivityChartBucket(
            start: start,
            endExclusive: end,
            days: days.where((day) => day.date.month == month).toList(),
          ),
        );
      }
    } else {
      for (final day in days) {
        buckets.add(
          ActivityChartBucket(
            start: day.date,
            endExclusive: DateTime.utc(day.date.year, day.date.month, day.date.day + 1),
            days: [day],
          ),
        );
      }
    }
    return ActivityChartData(period: period, days: days, buckets: buckets);
  }
}
