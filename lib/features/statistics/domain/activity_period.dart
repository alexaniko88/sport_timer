enum ActivityPeriodUnit {
  week,
  month,
  year,
}

/// Calendar dates are represented as UTC midnight, without timezone conversion.
class ActivityPeriod {
  final ActivityPeriodUnit unit;
  final int firstWeekday;
  final DateTime start;
  final DateTime endExclusive;

  factory ActivityPeriod({
    required ActivityPeriodUnit unit,
    required DateTime date,
    required int firstWeekday,
  }) {
    RangeError.checkValueInInterval(firstWeekday, DateTime.monday, DateTime.sunday, 'firstWeekday');
    final day = DateTime.utc(date.year, date.month, date.day);
    final start = switch (unit) {
      ActivityPeriodUnit.week => DateTime.utc(
          day.year,
          day.month,
          day.day - (day.weekday - firstWeekday) % DateTime.daysPerWeek,
        ),
      ActivityPeriodUnit.month => DateTime.utc(day.year, day.month),
      ActivityPeriodUnit.year => DateTime.utc(day.year),
    };
    final end = switch (unit) {
      ActivityPeriodUnit.week => DateTime.utc(start.year, start.month, start.day + 7),
      ActivityPeriodUnit.month => DateTime.utc(start.year, start.month + 1),
      ActivityPeriodUnit.year => DateTime.utc(start.year + 1),
    };
    return ActivityPeriod._(unit, firstWeekday, start, end);
  }

  const ActivityPeriod._(this.unit, this.firstWeekday, this.start, this.endExclusive);

  ActivityPeriod get previous => ActivityPeriod(
        unit: unit,
        date: DateTime.utc(start.year, start.month, start.day - 1),
        firstWeekday: firstWeekday,
      );

  ActivityPeriod get next => ActivityPeriod(
        unit: unit,
        date: endExclusive,
        firstWeekday: firstWeekday,
      );

  bool canNavigateNext(DateTime today) {
    final date = DateTime.utc(today.year, today.month, today.day);
    return endExclusive.isBefore(date) || endExclusive == date;
  }
}
