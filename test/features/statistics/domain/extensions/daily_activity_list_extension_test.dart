import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/statistics/domain/activity_period.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/domain/extensions/daily_activity_list_extension.dart';

void main() {
  const activity = [
    DailyActivity(localDate: '2023-12-31', roundCount: 1, workDurationMs: 30, restDurationMs: 10),
    DailyActivity(localDate: '2024-02-28', roundCount: 0, workDurationMs: 0, restDurationMs: 20),
    DailyActivity(localDate: '2024-02-29', roundCount: 2, workDurationMs: 80, restDurationMs: 15),
    DailyActivity(localDate: '2024-03-01', roundCount: 1, workDurationMs: 40, restDurationMs: 0),
    DailyActivity(localDate: '2024-12-31', roundCount: 3, workDurationMs: 90, restDurationMs: 30),
  ];

  test('week has daily buckets across years and separates past, future and recorded days', () {
    final period = ActivityPeriod(unit: ActivityPeriodUnit.week, date: DateTime(2024, 1, 1), firstWeekday: 7);
    final data = activity.chartData(period: period, today: DateTime(2024, 1, 1, 23));
    expect(data.days.length, 7);
    expect(data.buckets.length, 7);
    expect(data.days.first.date, DateTime.utc(2023, 12, 31));
    expect(data.days.first.isActive, isTrue);
    expect(data.days.first.hasRecordedActivity, isTrue);
    expect(data.days[1].hasRecordedActivity, isFalse);
    expect(data.days[1].isFuture, isFalse);
    expect(data.days[2].isFuture, isTrue);
    expect(data.roundCount, 1);
    expect(data.workDurationMs, 30);
    expect(data.restDurationMs, 10);
    expect(data.totalDurationMs, 40);
  });

  test('month includes leap day and preserves recorded future data', () {
    final period = ActivityPeriod(unit: ActivityPeriodUnit.month, date: DateTime(2024, 2), firstWeekday: 1);
    final data = activity.chartData(period: period, today: DateTime(2024, 2, 28));
    expect(data.days.length, 29);
    expect(data.buckets.length, 29);
    final restOnly = data.days[27];
    expect(restOnly.hasRecordedActivity, isTrue);
    expect(restOnly.isActive, isFalse);
    expect(restOnly.restDurationMs, 20);
    final leapDay = data.days.last;
    expect(leapDay.date, DateTime.utc(2024, 2, 29));
    expect(leapDay.isFuture, isTrue);
    expect(leapDay.isActive, isTrue);
    expect(leapDay.workDurationMs, 80);
    expect(data.activeDayCount, 1);
    expect(data.totalDurationMs, 115);
  });

  test('year groups by month while retaining each stored local date', () {
    final period = ActivityPeriod(unit: ActivityPeriodUnit.year, date: DateTime(2024), firstWeekday: 1);
    final data = activity.chartData(period: period, today: DateTime(2024, 3, 1));
    expect(data.days.length, 366);
    expect(data.buckets.length, 12);
    expect(data.buckets[0].hasRecordedActivity, isFalse);
    expect(data.buckets[1].days.length, 29);
    expect(data.buckets[1].roundCount, 2);
    expect(data.buckets[1].workDurationMs, 80);
    expect(data.buckets[1].restDurationMs, 35);
    expect(data.buckets[1].activeDayCount, 1);
    expect(data.buckets[2].isFuture, isFalse);
    expect(data.buckets[3].isFuture, isTrue);
    expect(data.buckets.last.hasRecordedActivity, isTrue);
    expect(data.buckets.last.isFuture, isTrue);
    expect(data.roundCount, 6);
    expect(data.workDurationMs, 210);
    expect(data.restDurationMs, 65);
    expect(data.totalDurationMs, 275);
    expect(data.activeDayCount, 3);
  });
}
