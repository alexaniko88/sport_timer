import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/statistics/domain/activity_period.dart';

void main() {
  test('weeks respect the first weekday across year boundaries', () {
    final monday = ActivityPeriod(unit: ActivityPeriodUnit.week, date: DateTime(2023, 1, 1), firstWeekday: 1);
    final sunday = ActivityPeriod(unit: ActivityPeriodUnit.week, date: DateTime(2023, 1, 1), firstWeekday: 7);
    expect(monday.start, DateTime.utc(2022, 12, 26));
    expect(monday.endExclusive, DateTime.utc(2023, 1, 2));
    expect(sunday.start, DateTime.utc(2023, 1, 1));
    expect(sunday.endExclusive, DateTime.utc(2023, 1, 8));
    expect(monday.previous.start, DateTime.utc(2022, 12, 19));
    expect(monday.next.start, DateTime.utc(2023, 1, 2));
  });

  test('months and years navigate over leap days and year boundaries', () {
    final february = ActivityPeriod(unit: ActivityPeriodUnit.month, date: DateTime(2024, 2, 29), firstWeekday: 1);
    expect(february.start, DateTime.utc(2024, 2, 1));
    expect(february.endExclusive, DateTime.utc(2024, 3, 1));
    expect(february.previous.start, DateTime.utc(2024, 1, 1));
    expect(february.next.start, DateTime.utc(2024, 3, 1));
    final year = ActivityPeriod(unit: ActivityPeriodUnit.year, date: DateTime(2024), firstWeekday: 7);
    expect(year.previous.start, DateTime.utc(2023));
    expect(year.next.start, DateTime.utc(2025));
    expect(year.canNavigateNext(DateTime(2024, 12, 31)), isFalse);
    expect(year.canNavigateNext(DateTime(2025)), isTrue);
  });

  test('calendar boundaries do not use elapsed local hours across DST', () {
    final week = ActivityPeriod(unit: ActivityPeriodUnit.week, date: DateTime(2024, 3, 31, 23), firstWeekday: 1);
    expect(week.start, DateTime.utc(2024, 3, 25));
    expect(week.endExclusive, DateTime.utc(2024, 4, 1));
    expect(week.next.endExclusive, DateTime.utc(2024, 4, 8));
    expect(
      () => ActivityPeriod(unit: ActivityPeriodUnit.week, date: DateTime(2024), firstWeekday: 0),
      throwsRangeError,
    );
  });
}
