import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/settings/domain/settings_repository.dart';
import 'package:sport_timer/features/settings/domain/timer_configuration.dart';
import 'package:sport_timer/features/settings/domain/timer_settings.dart';
import 'package:sport_timer/features/settings/presentation/settings_state.dart';
import 'package:sport_timer/features/settings/domain/timer_style.dart';
import 'package:sport_timer/features/templates/domain/built_in_templates.dart';
import 'package:sport_timer/features/templates/domain/custom_template.dart';
import 'package:sport_timer/features/templates/domain/custom_template_repository.dart';
import 'package:sport_timer/features/templates/domain/workout_template.dart';

typedef TimerSettingsUpdate = TimerSettings Function(TimerSettings settings);
typedef TemplateWrite = Future<bool> Function();
typedef ConfigurationUpdate = TimerConfiguration Function(TimerConfiguration configuration);

class SettingsViewModel {
  static const TimerSettings _defaults = TimerSettings(
    preparationTime: Duration(seconds: 20),
    roundTime: Duration(seconds: 60),
    restTime: Duration(seconds: 30),
    rounds: 12,
  );

  final SettingsRepository _settingsRepository;
  final CustomTemplateRepository _customTemplateRepository;
  final ValueNotifier<SettingsState> _state = ValueNotifier(
    const SettingsState(
      status: SettingsStatus.initial,
      timerSettings: _defaults,
      timerStyle: TimerStyle.ring,
    ),
  );
  final List<ConfigurationUpdate> _editsBeforeLoad = [];
  TimerSettings _currentSettings = _defaults;
  String? _selectedTemplateId;
  List<CustomTemplate> _customTemplates = const [];
  bool _customTemplatesLoaded = false;
  TimerConfiguration? _lastSavedSettings;
  TimerConfiguration? _pendingSettings;
  Future<void>? _loadFuture;
  Future<void>? _saveFuture;
  Future<void>? _templateWrite;
  bool _hasSettingsEdits = false;
  bool _saveFailed = false;
  bool _disposed = false;
  bool _styleSelected = false;

  SettingsViewModel(this._settingsRepository, this._customTemplateRepository);

  ValueListenable<SettingsState> get state => _state;

  Future<void> loadSettings() {
    if (_lastSavedSettings != null) return Future.value();
    return _loadFuture ??= _readSettings().whenComplete(() => _loadFuture = null);
  }

  Future<void> _readSettings() async {
    _setStatus(SettingsStatus.loading);
    await _loadCustomTemplates();
    final result = await _settingsRepository.getTimerConfiguration();
    final styleResult = await _settingsRepository.getTimerStyle();
    if (styleResult case Success(:final value) when !_disposed && !_styleSelected) {
      _state.value = _state.value.copyWith(timerStyle: value);
    }
    result.fold(
      onSuccess: (settings) {
        _lastSavedSettings = settings;
        var configuration = _validated(settings);
        // Replay only edited fields so a slow load preserves the other saved values.
        for (final update in _editsBeforeLoad) {
          configuration = update(configuration);
        }
        _editsBeforeLoad.clear();
        _setConfiguration(configuration);
        _hasSettingsEdits = configuration != settings;
        _setStatus(SettingsStatus.loaded);
      },
      onFailure: (error) => _setStatus(SettingsStatus.error, error: error),
    );
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

  Future<void> selectCustomTemplate(CustomTemplate template) {
    if (_disposed) return Future.value();
    final configuration = TimerConfiguration(template.settings, template.id);
    if (_lastSavedSettings == null) _editsBeforeLoad.add((_) => configuration);
    _hasSettingsEdits = true;
    _setConfiguration(configuration);
    return flushSettings();
  }

  Future<bool> saveCustomTemplate(CustomTemplate template) =>
      _enqueueTemplateWrite(() => _saveCustomTemplate(template));

  Future<bool> deleteCustomTemplate(String id) => _enqueueTemplateWrite(() => _deleteCustomTemplate(id));

  // Each write starts from the list the previous one stored, so overlapping calls never drop a change.
  Future<bool> _enqueueTemplateWrite(TemplateWrite write) {
    final result = (_templateWrite ?? Future<void>.value()).then((_) => write());
    _templateWrite = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<bool> _saveCustomTemplate(CustomTemplate template) async {
    if (!await _ensureCustomTemplatesLoaded()) return false;
    final index = _customTemplates.indexWhere((existing) => existing.id == template.id);
    if (index == -1 && _customTemplates.length >= CustomTemplate.maxCount) return false;
    final templates = List.of(_customTemplates);
    if (index == -1) {
      templates.add(template);
    } else {
      templates[index] = template;
    }
    if (!await _writeCustomTemplates(templates)) return false;
    if (template.id == _selectedTemplateId && template.settings != _currentSettings) {
      await _clearSelection();
    }
    return true;
  }

  Future<bool> _deleteCustomTemplate(String id) async {
    if (!await _ensureCustomTemplatesLoaded()) return false;
    if (!_customTemplates.any((template) => template.id == id)) return true;
    final templates = _customTemplates.where((template) => template.id != id).toList();
    if (!await _writeCustomTemplates(templates)) return false;
    if (id == _selectedTemplateId) await _clearSelection();
    return true;
  }

  Future<void> _loadCustomTemplates() async {
    final result = await _customTemplateRepository.getTemplates();
    if (result case Success(:final value)) {
      _customTemplates = value;
      _customTemplatesLoaded = true;
      if (!_disposed) _state.value = _state.value.copyWith(customTemplates: value);
    } else if (result case Failure(:final error)) {
      debugPrint('Could not load own templates: $error');
    }
  }

  Future<bool> _ensureCustomTemplatesLoaded() async {
    if (_disposed) return false;
    if (!_customTemplatesLoaded) await _loadCustomTemplates();
    return _customTemplatesLoaded && !_disposed;
  }

  Future<bool> _writeCustomTemplates(List<CustomTemplate> templates) async {
    final result = await _customTemplateRepository.saveTemplates(templates);
    if (result is Failure) return false;
    _customTemplates = templates;
    // The selection may point to the old value of an edited template.
    _setConfiguration(_currentConfiguration);
    return true;
  }

  Future<void> _clearSelection() {
    _selectedTemplateId = null;
    _hasSettingsEdits = true;
    _setConfiguration(_currentConfiguration);
    return flushSettings();
  }

  TimerConfiguration _validated(TimerConfiguration configuration) {
    final id = configuration.selectedTemplateId;
    for (final template in builtInTemplates) {
      if (template.id.name == id && template.settings == configuration.settings) {
        return configuration;
      }
    }
    for (final template in _customTemplates) {
      if (template.id == id && template.settings == configuration.settings) {
        return configuration;
      }
    }
    return TimerConfiguration(configuration.settings, null);
  }

  TimerConfiguration get _currentConfiguration => TimerConfiguration(_currentSettings, _selectedTemplateId);

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
    _selectedTemplateId = configuration.selectedTemplateId;
    final builtInId = TemplateId.values.asNameMap()[_selectedTemplateId];
    final customTemplate = _customTemplates.where((template) => template.id == _selectedTemplateId).firstOrNull;
    if (!_disposed) {
      _state.value = _state.value.copyWith(
        timerSettings: configuration.settings,
        selectedTemplateId: builtInId,
        clearSelectedTemplate: builtInId == null,
        customTemplates: _customTemplates,
        selectedCustomTemplate: customTemplate,
        clearSelectedCustomTemplate: customTemplate == null,
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
