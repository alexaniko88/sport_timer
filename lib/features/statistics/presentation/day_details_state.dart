import 'package:flutter/foundation.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/domain/run_activity_summary.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_state.dart';

class DayDetailsState {
  final StatisticsStatus status;
  final List<RunActivitySummary> runs;
  final String? errorMessage;

  DayDetailsState({this.status = StatisticsStatus.initial, List<RunActivitySummary> runs = const [], this.errorMessage})
      : runs = List.unmodifiable(runs);

  DailyActivity summary(String localDate) => DailyActivity(
        localDate: localDate,
        roundCount: runs.fold(0, (sum, run) => sum + run.activity.roundCount),
        workDurationMs: runs.fold(0, (sum, run) => sum + run.activity.workDurationMs),
        restDurationMs: runs.fold(0, (sum, run) => sum + run.activity.restDurationMs),
      );

  DayDetailsState copyWith({
    StatisticsStatus? status,
    List<RunActivitySummary>? runs,
    String? errorMessage,
    bool clearError = false,
  }) =>
      DayDetailsState(
        status: status ?? this.status,
        runs: runs ?? this.runs,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayDetailsState &&
          other.status == status &&
          listEquals(other.runs, runs) &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(status, Object.hashAll(runs), errorMessage);
}
