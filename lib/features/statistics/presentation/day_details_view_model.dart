import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';
import 'package:sport_timer/features/statistics/presentation/day_details_state.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_state.dart';

class DayDetailsViewModel {
  final ActivityRepository _repository;
  final String localDate;
  final ValueNotifier<DayDetailsState> _state = ValueNotifier(DayDetailsState());
  late final StreamSubscription<void> _changes;
  int _generation = 0;
  bool _disposed = false;

  DayDetailsViewModel(this._repository, this.localDate) {
    _changes = _repository.changes.listen((_) => unawaited(refresh()));
    unawaited(refresh());
  }

  ValueListenable<DayDetailsState> get state => _state;

  Future<void> refresh() async {
    if (_disposed) return;
    final generation = ++_generation;
    _state.value = DayDetailsState(status: StatisticsStatus.loading);
    final result = await _repository.readDayActivity(localDate);
    if (_disposed || generation != _generation) return;
    result.fold(
      onSuccess: (value) => _state.value =
          DayDetailsState(status: value.isEmpty ? StatisticsStatus.empty : StatisticsStatus.content, runs: value),
      onFailure: (error) =>
          _state.value = DayDetailsState(status: StatisticsStatus.error, errorMessage: error.toString()),
    );
  }

  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_changes.cancel());
    _state.dispose();
  }
}
