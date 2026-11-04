import 'package:flutter/foundation.dart';
import 'package:sport_timer/features/statistics/domain/activity_period.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';

enum StatisticsStatus { initial, loading, content, empty, error }

enum StatisticsView { list, charts }

enum StatisticsPerspective {
  workTime,
  rounds,
  workVsRest,
  totalTime,
  consistency,
}

class StatisticsState {
  final StatisticsStatus status;
  final List<DailyActivity> dailyActivity;
  final String? errorMessage;
  final StatisticsView view;
  final StatisticsPerspective perspective;
  final ActivityPeriodUnit periodUnit;
  final DateTime? referenceDate;
  final int firstWeekday;
  final DateTime? selectedBucket;

  StatisticsState({
    this.status = StatisticsStatus.initial,
    List<DailyActivity> dailyActivity = const [],
    this.errorMessage,
    this.view = StatisticsView.list,
    this.perspective = StatisticsPerspective.workTime,
    this.periodUnit = ActivityPeriodUnit.week,
    this.referenceDate,
    this.firstWeekday = DateTime.monday,
    this.selectedBucket,
  }) : dailyActivity = List.unmodifiable(dailyActivity);

  StatisticsState copyWith({
    StatisticsStatus? status,
    List<DailyActivity>? dailyActivity,
    String? errorMessage,
    bool clearError = false,
    StatisticsView? view,
    StatisticsPerspective? perspective,
    ActivityPeriodUnit? periodUnit,
    DateTime? referenceDate,
    int? firstWeekday,
    DateTime? selectedBucket,
    bool clearSelection = false,
  }) =>
      StatisticsState(
        status: status ?? this.status,
        dailyActivity: dailyActivity ?? this.dailyActivity,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
        view: view ?? this.view,
        perspective: perspective ?? this.perspective,
        periodUnit: periodUnit ?? this.periodUnit,
        referenceDate: referenceDate ?? this.referenceDate,
        firstWeekday: firstWeekday ?? this.firstWeekday,
        selectedBucket: clearSelection ? null : selectedBucket ?? this.selectedBucket,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatisticsState &&
          other.status == status &&
          listEquals(other.dailyActivity, dailyActivity) &&
          other.errorMessage == errorMessage &&
          other.view == view &&
          other.perspective == perspective &&
          other.periodUnit == periodUnit &&
          other.referenceDate == referenceDate &&
          other.firstWeekday == firstWeekday &&
          other.selectedBucket == selectedBucket;

  @override
  int get hashCode => Object.hash(
        status,
        Object.hashAll(dailyActivity),
        errorMessage,
        view,
        perspective,
        periodUnit,
        referenceDate,
        firstWeekday,
        selectedBucket,
      );
}
