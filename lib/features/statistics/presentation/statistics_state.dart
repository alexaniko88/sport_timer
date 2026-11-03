import 'package:flutter/foundation.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';

enum StatisticsStatus {
  initial,
  loading,
  content,
  empty,
  error,
}

class StatisticsState {
  final StatisticsStatus status;
  final List<DailyActivity> dailyActivity;
  final String? errorMessage;

  StatisticsState({
    this.status = StatisticsStatus.initial,
    List<DailyActivity> dailyActivity = const [],
    this.errorMessage,
  }) : dailyActivity = List.unmodifiable(dailyActivity);

  StatisticsState copyWith({
    StatisticsStatus? status,
    List<DailyActivity>? dailyActivity,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StatisticsState(
      status: status ?? this.status,
      dailyActivity: dailyActivity ?? this.dailyActivity,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatisticsState &&
          other.status == status &&
          listEquals(other.dailyActivity, dailyActivity) &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(status, Object.hashAll(dailyActivity), errorMessage);
}
