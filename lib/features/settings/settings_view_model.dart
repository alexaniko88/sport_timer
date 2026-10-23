import 'package:flutter/foundation.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/settings/settings_repository.dart';
import 'package:sport_timer/features/settings/settings_state.dart';

typedef TimerSettingsUpdate = TimerSettings Function(TimerSettings settings);

class SettingsViewModel {
  final SettingsRepository _settingsRepository;
  final ValueNotifier<SettingsState> _state = ValueNotifier(
    const SettingsState(
      status: SettingsStatus.initial,
      timerSettings: TimerSettings(
        preparationTime: Duration(seconds: 20),
        roundTime: Duration(seconds: 60),
        restTime: Duration(seconds: 30),
        rounds: 5,
      ),
    ),
  );
  bool _disposed = false;

  SettingsViewModel(this._settingsRepository);

  ValueListenable<SettingsState> get state => _state;

  Future<void> loadSettings() async {
    _state.value = _state.value.copyWith(status: SettingsStatus.loading);
    final result = await _settingsRepository.getTimerSettings();
    // The page can be gone by the time the request finishes.
    if (_disposed) return;
    switch (result) {
      case Success(:final value):
        _state.value = _state.value.copyWith(
          status: SettingsStatus.loaded,
          timerSettings: value,
        );
      case Failure(:final error):
        _state.value = _state.value.copyWith(
          status: SettingsStatus.error,
          errorMessage: error.toString(),
        );
    }
  }

  Future<void> saveSettings(TimerSettings settings) async {
    _state.value = _state.value.copyWith(status: SettingsStatus.saving);
    final result = await _settingsRepository.saveTimerSettings(settings);
    if (_disposed) return;
    switch (result) {
      case Success():
        _state.value = _state.value.copyWith(
          status: SettingsStatus.saved,
          timerSettings: settings,
        );
      case Failure(:final error):
        _state.value = _state.value.copyWith(
          status: SettingsStatus.error,
          errorMessage: error.toString(),
        );
    }
  }

  void updatePreparationTime(Duration duration) => _updateTimerSettings(
      (settings) => settings.copyWith(preparationTime: duration));

  void updateRoundTime(Duration duration) => _updateTimerSettings(
      (settings) => settings.copyWith(roundTime: duration));

  void updateRestTime(Duration duration) =>
      _updateTimerSettings((settings) => settings.copyWith(restTime: duration));

  void updateRounds(int rounds) =>
      _updateTimerSettings((settings) => settings.copyWith(rounds: rounds));

  void _updateTimerSettings(TimerSettingsUpdate update) {
    _state.value = _state.value
        .copyWith(timerSettings: update(_state.value.timerSettings));
  }

  void dispose() {
    _disposed = true;
    _state.dispose();
  }
}
