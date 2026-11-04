import 'package:sport_timer/features/statistics/domain/activity_period.dart';

class ActivityChartDay {
  final DateTime date;
  final int roundCount;
  final int workDurationMs;
  final int restDurationMs;
  final bool hasRecordedActivity;
  final bool isFuture;

  const ActivityChartDay({
    required this.date,
    required this.roundCount,
    required this.workDurationMs,
    required this.restDurationMs,
    required this.hasRecordedActivity,
    required this.isFuture,
  });

  int get totalDurationMs => workDurationMs + restDurationMs;
  bool get isActive => roundCount > 0;
}

class ActivityChartBucket {
  final DateTime start;
  final DateTime endExclusive;
  final List<ActivityChartDay> days;
  final int roundCount;
  final int workDurationMs;
  final int restDurationMs;
  final int activeDayCount;
  final bool hasRecordedActivity;
  final bool isFuture;

  ActivityChartBucket({
    required this.start,
    required this.endExclusive,
    required List<ActivityChartDay> days,
  })  : days = List.unmodifiable(days),
        roundCount = days.fold(0, (sum, day) => sum + day.roundCount),
        workDurationMs = days.fold(0, (sum, day) => sum + day.workDurationMs),
        restDurationMs = days.fold(0, (sum, day) => sum + day.restDurationMs),
        activeDayCount = days.where((day) => day.isActive).length,
        hasRecordedActivity = days.any((day) => day.hasRecordedActivity),
        isFuture = days.every((day) => day.isFuture);

  int get totalDurationMs => workDurationMs + restDurationMs;
}

class ActivityChartData {
  final ActivityPeriod period;
  final List<ActivityChartDay> days;
  final List<ActivityChartBucket> buckets;
  final int roundCount;
  final int workDurationMs;
  final int restDurationMs;
  final int activeDayCount;
  final bool hasRecordedActivity;

  ActivityChartData({
    required this.period,
    required List<ActivityChartDay> days,
    required List<ActivityChartBucket> buckets,
  })  : days = List.unmodifiable(days),
        buckets = List.unmodifiable(buckets),
        roundCount = days.fold(0, (sum, day) => sum + day.roundCount),
        workDurationMs = days.fold(0, (sum, day) => sum + day.workDurationMs),
        restDurationMs = days.fold(0, (sum, day) => sum + day.restDurationMs),
        activeDayCount = days.where((day) => day.isActive).length,
        hasRecordedActivity = days.any((day) => day.hasRecordedActivity);

  int get totalDurationMs => workDurationMs + restDurationMs;
}
