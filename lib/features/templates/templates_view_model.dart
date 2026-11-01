import 'package:flutter/foundation.dart';
import 'package:sport_timer/features/settings/settings_repository.dart';
import 'package:sport_timer/features/settings/settings_view_model.dart';
import 'package:sport_timer/features/templates/built_in_templates.dart';
import 'package:sport_timer/features/templates/templates_state.dart';
import 'package:sport_timer/features/templates/workout_template.dart';

class TemplatesViewModel {
  final SettingsViewModel _settingsViewModel;
  late final ValueNotifier<TemplatesState> _state;
  bool _disposed = false;

  TemplatesViewModel(this._settingsViewModel) {
    _state = ValueNotifier(_stateFor(_settingsViewModel.state.value.timerSettings));
    _settingsViewModel.state.addListener(_onSettingsChanged);
  }

  ValueListenable<TemplatesState> get state => _state;

  Future<void> applyTemplate(WorkoutTemplate template) async {
    if (_disposed) return;
    await _settingsViewModel.saveSettings(template.settings);
  }

  void _onSettingsChanged() {
    if (_disposed) return;
    _state.value = _stateFor(_settingsViewModel.state.value.timerSettings);
  }

  TemplatesState _stateFor(TimerSettings settings) {
    TemplateId? selectedTemplateId;
    for (final template in builtInTemplates) {
      if (template.settings == settings) {
        selectedTemplateId = template.id;
        break;
      }
    }
    return TemplatesState(timerSettings: settings, selectedTemplateId: selectedTemplateId);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _settingsViewModel.state.removeListener(_onSettingsChanged);
    _state.dispose();
  }
}
