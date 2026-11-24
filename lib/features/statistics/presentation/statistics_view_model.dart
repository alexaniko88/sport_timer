import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/statistics/domain/activity_chart_data.dart';
import 'package:sport_timer/features/statistics/domain/activity_period.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';
import 'package:sport_timer/features/statistics/domain/extensions/daily_activity_list_extension.dart';
import 'package:sport_timer/features/statistics/domain/run_activity_summary.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_state.dart';

typedef StatisticsClock = DateTime Function();

class StatisticsViewModel {
  final ActivityRepository _repository;
  final StatisticsClock _clock;
  final ValueNotifier<StatisticsState> _state = ValueNotifier(StatisticsState());
  late final StreamSubscription<void> _changes;
  final Map<String, List<RunActivitySummary>> _dayRuns = {};
  int _generation = 0;
  int _dayGeneration = 0;
  bool _disposed = false;

  StatisticsViewModel(this._repository, {StatisticsClock? clock}) : _clock = clock ?? DateTime.now {
    _changes = _repository.changes.listen((_) {
      _state.value = _state.value.copyWith(clearSelection: true);
      unawaited(refresh());
    });
    unawaited(refresh());
  }

  ValueListenable<StatisticsState> get state => _state;
  DateTime get today => _clock();
  ActivityPeriod get period => ActivityPeriod(
        unit: _state.value.periodUnit,
        date: _state.value.referenceDate ?? today,
        firstWeekday: _state.value.firstWeekday,
      );
  bool get canNavigateNext => period.canNavigateNext(today);
  ActivityChartData get currentChartData => chartData(period: period, today: today);
  double get chartMaxY {
    final perspective = _state.value.perspective;
    final max = currentChartData.buckets.fold<double>(
      0,
      (value, bucket) => math.max(
        value,
        switch (perspective) {
          StatisticsPerspective.workTime || StatisticsPerspective.consistency => bucket.workDurationMs / 1000,
          StatisticsPerspective.rounds => bucket.roundCount.toDouble(),
          StatisticsPerspective.workVsRest || StatisticsPerspective.totalTime => bucket.totalDurationMs / 1000,
        },
      ),
    );
    return math.max(1, (max * 1.15).ceil()).toDouble();
  }

  ActivityChartData chartData({required ActivityPeriod period, required DateTime today}) =>
      _state.value.dailyActivity.chartData(period: period, today: today);

  void setView(StatisticsView view) {
    _state.value = _state.value.copyWith(view: view, referenceDate: _state.value.referenceDate ?? today);
  }

  void setPerspective(StatisticsPerspective perspective) {
    if (_state.value.perspective != perspective) {
      _state.value = _state.value.copyWith(perspective: perspective, clearSelection: true);
    }
  }

  void setFirstWeekday(int day) {
    if (_state.value.firstWeekday != day) {
      _state.value = _state.value.copyWith(firstWeekday: day, clearSelection: true);
    }
  }

  void setPeriodUnit(ActivityPeriodUnit unit) {
    if (_state.value.periodUnit != unit) {
      _state.value = _state.value
          .copyWith(periodUnit: unit, referenceDate: _state.value.referenceDate ?? today, clearSelection: true);
    }
  }

  void previousPeriod() =>
      _state.value = _state.value.copyWith(referenceDate: period.previous.start, clearSelection: true);

  void nextPeriod() {
    if (canNavigateNext) {
      _state.value = _state.value.copyWith(referenceDate: period.next.start, clearSelection: true);
    }
  }

  void selectBucket(ActivityChartBucket bucket) {
    if (bucket.isFuture) return;
    _state.value = _state.value
        .copyWith(selectedBucket: bucket.start, clearSelection: _state.value.selectedBucket == bucket.start);
  }

  void selectDay(ActivityChartDay day) {
    if (day.isFuture) return;
    _state.value = _state.value.copyWith(
      selectedBucket: day.date,
      clearSelection: _state.value.selectedBucket == day.date,
    );
  }

  void openMonth(DateTime month) {
    final now = today;
    if (DateTime.utc(month.year, month.month).isAfter(DateTime.utc(now.year, now.month))) return;
    _state.value = _state.value.copyWith(
      periodUnit: ActivityPeriodUnit.month,
      referenceDate: month,
      clearSelection: true,
    );
  }

  Future<void> refresh() async {
    if (_disposed) return;
    final generation = ++_generation;
    _dayRuns.clear();
    _dayGeneration++;
    _state.value = _state.value.copyWith(
      status: StatisticsStatus.loading,
      dailyActivity: [],
      clearError: true,
      clearExpanded: true,
    );
    final result = await _repository.readDailyActivity();
    if (_disposed || generation != _generation) return;
    if (result case Success(:final value)) {
      _state.value = _state.value
          .copyWith(status: value.isEmpty ? StatisticsStatus.empty : StatisticsStatus.content, dailyActivity: value);
    } else if (result case Failure(:final error)) {
      _state.value = _state.value.copyWith(status: StatisticsStatus.error, errorMessage: error.toString());
    }
  }

  Future<bool> deleteStatistics() async {
    if (_state.value.isDeleting) return false;
    _state.value = _state.value.copyWith(isDeleting: true);
    final result = await _repository.deleteAccountActivity();
    if (!_disposed) _state.value = _state.value.copyWith(isDeleting: false);
    return result.fold(onSuccess: (_) => true, onFailure: (_) => false);
  }

  void toggleDay(String localDate) {
    if (_state.value.expandedDate == localDate) {
      _state.value = _state.value.copyWith(clearExpanded: true);
      return;
    }
    final cached = _dayRuns[localDate];
    if (cached != null) {
      _state.value = _state.value.copyWith(
        expandedDate: localDate,
        dayStatus: cached.isEmpty ? StatisticsStatus.empty : StatisticsStatus.content,
        dayRuns: cached,
      );
      return;
    }
    _state.value = _state.value.copyWith(
      expandedDate: localDate,
      dayStatus: StatisticsStatus.loading,
      dayRuns: [],
    );
    unawaited(_loadDay(localDate));
  }

  Future<void> retryDay() async {
    final localDate = _state.value.expandedDate;
    if (localDate == null) return;
    _state.value = _state.value.copyWith(dayStatus: StatisticsStatus.loading, dayRuns: []);
    await _loadDay(localDate);
  }

  Future<void> _loadDay(String localDate) async {
    final generation = ++_dayGeneration;
    final result = await _repository.readDayActivity(localDate);
    if (_disposed || generation != _dayGeneration || _state.value.expandedDate != localDate) return;
    result.fold(
      onSuccess: (value) {
        _dayRuns[localDate] = value;
        _state.value = _state.value.copyWith(
          dayStatus: value.isEmpty ? StatisticsStatus.empty : StatisticsStatus.content,
          dayRuns: value,
        );
      },
      onFailure: (_) => _state.value = _state.value.copyWith(dayStatus: StatisticsStatus.error),
    );
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _dayGeneration++;
    unawaited(_changes.cancel());
    _state.dispose();
  }
}
