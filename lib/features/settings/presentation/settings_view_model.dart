import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/settings/domain/settings_repository.dart';
import 'package:sport_timer/features/settings/domain/timer_configuration.dart';
import 'package:sport_timer/features/settings/domain/timer_settings.dart';
import 'package:sport_timer/features/settings/presentation/settings_state.dart';
import 'package:sport_timer/features/settings/domain/timer_style.dart';
import 'package:sport_timer/features/templates/domain/built_in_templates.dart';
import 'package:sport_timer/features/templates/domain/workout_template.dart';

typedef TimerSettingsUpdate = TimerSettings Function(TimerSettings settings);
typedef ConfigurationUpdate = TimerConfiguration Function(TimerConfiguration configuration);

class SettingsViewModel {
  static const TimerSettings _defaults = TimerSettings(
    preparationTime: Duration(seconds: 20),
    roundTime: Duration(seconds: 60),
    restTime: Duration(seconds: 30),
    rounds: 12,
  );

  final SettingsRepository _settingsRepository;
  final ValueNotifier<SettingsState> _state = ValueNotifier(
    const SettingsState(
      status: SettingsStatus.initial,
      timerSettings: _defaults,
      timerStyle: TimerStyle.ring,
    ),
  );
  final List<ConfigurationUpdate> _editsBeforeLoad = [];
  TimerSettings _currentSettings = _defaults;
  TemplateId? _selectedTemplateId;
  TimerConfiguration? _lastSavedSettings;
  TimerConfiguration? _pendingSettings;
  Future<void>? _loadFuture;
  Future<void>? _saveFuture;
  bool _hasSettingsEdits = false;
  bool _saveFailed = false;
  bool _disposed = false;
  bool _styleSelected = false;

  SettingsViewModel(this._settingsRepository);

  ValueListenable<SettingsState> get state => _state;

  Future<void> loadSettings() {
    if (_lastSavedSettings != null) return Future.value();
    return _loadFuture ??= _readSettings().whenComplete(() => _loadFuture = null);
  }

  Future<void> _readSettings() async {
    _setStatus(SettingsStatus.loading);
    final result = await _settingsRepository.getTimerConfiguration();
    final styleResult = await _settingsRepository.getTimerStyle();
    if (styleResult case Success(:final value) when !_disposed && !_styleSelected) {
      _state.value = _state.value.copyWith(timerStyle: value);
    }
    if (result case Success(:final value)) {
      _lastSavedSettings = value;
      var configuration = _validated(value);
      // Replay only edited fields so a slow load preserves the other saved values.
      for (final update in _editsBeforeLoad) {
        configuration = update(configuration);
      }
      _editsBeforeLoad.clear();
      _setConfiguration(configuration);
      _hasSettingsEdits = configuration != value;
      _setStatus(SettingsStatus.loaded);
    } else if (result case Failure(:final error)) {
      _setStatus(SettingsStatus.error, error: error);
    }
  }

  Future<void> saveSettings(TimerSettings settings) {
    _updateTimerSettings((_) => settings);
    return flushSettings();
  }

  Future<void> selectTemplate(WorkoutTemplate template) {
    if (_disposed) return Future.value();
    final configuration = TimerConfiguration(template.settings, template.id.name);
    if (_lastSavedSettings == null) _editsBeforeLoad.add((_) => configuration);
    _hasSettingsEdits = true;
    _setConfiguration(configuration);
    return flushSettings();
  }

  TimerConfiguration _validated(TimerConfiguration configuration) {
    for (final template in builtInTemplates) {
      if (template.id.name == configuration.selectedTemplateId && template.settings == configuration.settings) {
        return configuration;
      }
    }
    return TimerConfiguration(configuration.settings, null);
  }

  TimerConfiguration get _currentConfiguration => TimerConfiguration(_currentSettings, _selectedTemplateId?.name);

  Future<void> flushSettings() async {
    if (!_hasSettingsEdits) return;
    if (_loadFuture case final loading?) {
      await loading;
    } else if (_lastSavedSettings == null) {
      await loadSettings();
    }
    // A failed read must not replace untouched persisted fields with defaults.
    if (_lastSavedSettings == null || !_hasSettingsEdits) return;
    _pendingSettings = _currentConfiguration;
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
          _hasSettingsEdits = _currentConfiguration != _lastSavedSettings;
          continue;
        }
        final result = await _settingsRepository.saveTimerConfiguration(settings);
        if (result case Failure(:final error)) {
          _saveFailed = true;
          _setStatus(SettingsStatus.error, error: error);
          return;
        }
        _saveFailed = false;
        _lastSavedSettings = settings;
        _hasSettingsEdits = _currentConfiguration != settings;
        // Save completion never replaces edits made while the write was pending.
        _setStatus(_hasSettingsEdits ? SettingsStatus.loaded : SettingsStatus.saved);
      }
    } finally {
      _saveFuture = null;
    }
  }

  void _setConfiguration(TimerConfiguration configuration) {
    _currentSettings = configuration.settings;
    _selectedTemplateId = TemplateId.values.asNameMap()[configuration.selectedTemplateId];
    if (!_disposed) {
      _state.value = _state.value.copyWith(
        timerSettings: configuration.settings,
        selectedTemplateId: _selectedTemplateId,
        clearSelectedTemplate: _selectedTemplateId == null,
      );
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
    TimerConfiguration apply(TimerConfiguration configuration) {
      final settings = update(configuration.settings);
      return TimerConfiguration(
        settings,
        settings == configuration.settings ? configuration.selectedTemplateId : null,
      );
    }

    final configuration = apply(_currentConfiguration);
    if (_lastSavedSettings == null) _editsBeforeLoad.add(apply);
    if (configuration == _currentConfiguration && _lastSavedSettings != null) return;
    _hasSettingsEdits = true;
    _setConfiguration(configuration);
  }

  void dispose() {
    _disposed = true;
    unawaited(flushSettings());
    _state.dispose();
  }
}
