import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/statistics/domain/activity_chart_data.dart';
import 'package:sport_timer/features/statistics/domain/activity_period.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';
import 'package:sport_timer/features/statistics/domain/extensions/daily_activity_list_extension.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_state.dart';

class StatisticsViewModel {
  final ActivityRepository _repository;
  final ValueNotifier<StatisticsState> _state = ValueNotifier(StatisticsState());
  late final StreamSubscription<void> _changes;
  int _generation = 0;
  bool _disposed = false;

  StatisticsViewModel(this._repository) {
    _changes = _repository.changes.listen((_) => unawaited(refresh()));
    unawaited(refresh());
  }

  ValueListenable<StatisticsState> get state => _state;

  ActivityChartData chartData({required ActivityPeriod period, required DateTime today}) =>
      _state.value.dailyActivity.chartData(period: period, today: today);

  Future<void> refresh() async {
    if (_disposed) return;
    final generation = ++_generation;
    _state.value = StatisticsState(status: StatisticsStatus.loading);
    final result = await _repository.readDailyActivity();
    if (_disposed || generation != _generation) return;
    if (result case Success(:final value)) {
      _state.value = StatisticsState(
        status: value.isEmpty ? StatisticsStatus.empty : StatisticsStatus.content,
        dailyActivity: value,
      );
    } else if (result case Failure(:final error)) {
      _state.value = StatisticsState(status: StatisticsStatus.error, errorMessage: error.toString());
    }
  }

  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_changes.cancel());
    _state.dispose();
  }
}
