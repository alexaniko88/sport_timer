import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/settings/settings_repository.dart';
import 'package:sport_timer/features/settings/settings_state.dart';
import 'package:sport_timer/features/settings/timer_style.dart';

typedef TimerSettingsUpdate = TimerSettings Function(TimerSettings settings);

class SettingsViewModel {
  static const TimerSettings _defaults = TimerSettings(
    preparationTime: Duration(seconds: 20),
    roundTime: Duration(seconds: 60),
    restTime: Duration(seconds: 30),
    rounds: 5,
  );

  final SettingsRepository _settingsRepository;
  final ValueNotifier<SettingsState> _state = ValueNotifier(
    const SettingsState(
      status: SettingsStatus.initial,
      timerSettings: _defaults,
      timerStyle: TimerStyle.ring,
    ),
  );
  final List<TimerSettingsUpdate> _editsBeforeLoad = [];
  TimerSettings _currentSettings = _defaults;
  TimerSettings? _lastSavedSettings;
  TimerSettings? _pendingSettings;
  Future<void>? _loadFuture;
  Future<void>? _saveFuture;
  bool _hasSettingsEdits = false;
  bool _saveFailed = false;
  bool _disposed = false;
  bool _styleSelected = false;

  SettingsViewModel(this._settingsRepository);

  ValueListenable<SettingsState> get state => _state;

  Future<void> loadSettings() => _loadFuture ??= _readSettings().whenComplete(() => _loadFuture = null);

  Future<void> _readSettings() async {
    _setStatus(SettingsStatus.loading);
    final result = await _settingsRepository.getTimerSettings();
    final styleResult = await _settingsRepository.getTimerStyle();
    if (styleResult case Success(:final value) when !_disposed && !_styleSelected) {
      _state.value = _state.value.copyWith(timerStyle: value);
    }
    if (result case Success(:final value)) {
      _lastSavedSettings = value;
      var settings = value;
      // Replay only edited fields so a slow load preserves the other saved values.
      for (final update in _editsBeforeLoad) {
        settings = update(settings);
      }
      _editsBeforeLoad.clear();
      _setSettings(settings);
      _hasSettingsEdits = settings != value;
      _setStatus(SettingsStatus.loaded);
    } else if (result case Failure(:final error)) {
      _setStatus(SettingsStatus.error, error: error);
    }
  }

  Future<void> saveSettings(TimerSettings settings) {
    _updateTimerSettings((_) => settings);
    return flushSettings();
  }

  Future<void> flushSettings() async {
    if (!_hasSettingsEdits) return;
    if (_loadFuture case final loading?) {
      await loading;
    } else if (_lastSavedSettings == null) {
      await loadSettings();
    }
    // A failed read must not replace untouched persisted fields with defaults.
    if (_lastSavedSettings == null || !_hasSettingsEdits) return;
    _pendingSettings = _currentSettings;
    if (_saveFuture case final saving?) {
      await saving;
      return;
    }
    final completion = Completer<void>();
    _saveFuture = completion.future;
    unawaited(_drainSaves().then(completion.complete, onError: completion.completeError));
    await completion.future;
  }

  Future<void> _drainSaves() async {
    try {
      while (_pendingSettings != null) {
        final settings = _pendingSettings;
        if (settings == null) break;
        _pendingSettings = null;
        if (!_saveFailed && settings == _lastSavedSettings) {
          _hasSettingsEdits = _currentSettings != _lastSavedSettings;
          continue;
        }
        final result = await _settingsRepository.saveTimerSettings(settings);
        if (result case Failure(:final error)) {
          _saveFailed = true;
          _setStatus(SettingsStatus.error, error: error);
          return;
        }
        _saveFailed = false;
        _lastSavedSettings = settings;
        _hasSettingsEdits = _currentSettings != settings;
        // Save completion never replaces edits made while the write was pending.
        _setStatus(_hasSettingsEdits ? SettingsStatus.loaded : SettingsStatus.saved);
      }
    } finally {
      _saveFuture = null;
    }
  }

  void _setSettings(TimerSettings settings) {
    _currentSettings = settings;
    if (!_disposed) {
      _state.value = _state.value.copyWith(timerSettings: settings);
    }
  }

  void _setStatus(SettingsStatus status, {Exception? error}) {
    if (!_disposed) {
      _state.value = _state.value.copyWith(
        status: status,
        errorMessage: error?.toString(),
      );
    }
  }

  Future<void> selectTimerStyle(TimerStyle style) async {
    final previousStyle = _state.value.timerStyle;
    _styleSelected = true;
    _state.value = _state.value.copyWith(timerStyle: style);
    final result = await _settingsRepository.saveTimerStyle(style);
    if (_disposed) return;
    if (result case Failure(:final error)) {
      _state.value = _state.value.copyWith(
        timerStyle: previousStyle,
        status: SettingsStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  void updatePreparationTime(Duration duration) => _updateTimerSettings(
        (settings) => settings.copyWith(preparationTime: duration),
      );

  void updateRoundTime(Duration duration) => _updateTimerSettings(
        (settings) => settings.copyWith(roundTime: duration),
      );

  void updateRestTime(Duration duration) => _updateTimerSettings((settings) => settings.copyWith(restTime: duration));

  void updateRounds(int rounds) => _updateTimerSettings((settings) => settings.copyWith(rounds: rounds));

  void _updateTimerSettings(TimerSettingsUpdate update) {
    if (_disposed) return;
    final settings = update(_currentSettings);
    if (_lastSavedSettings == null) _editsBeforeLoad.add(update);
    if (settings == _currentSettings && _lastSavedSettings != null) return;
    _hasSettingsEdits = true;
    _setSettings(settings);
  }

  void dispose() {
    _disposed = true;
    unawaited(flushSettings());
    _state.dispose();
  }
}
