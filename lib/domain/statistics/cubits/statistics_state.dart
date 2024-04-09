part of '../statistics.dart';

@freezed
class StatisticsState with _$StatisticsState {
  const factory StatisticsState({
    required List<StatisticModel> statistics,
    required StatisticsStatus status,
    Exception? exception,
  }) = _StatisticsState;
}

enum StatisticsStatus {
  initial,
  loading,
  success,
  failure,
}