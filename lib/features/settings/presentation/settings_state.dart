import 'package:flutter/foundation.dart';
import 'package:sport_timer/features/settings/domain/timer_settings.dart';
import 'package:sport_timer/features/settings/domain/timer_style.dart';
import 'package:sport_timer/features/templates/domain/custom_template.dart';
import 'package:sport_timer/features/templates/domain/workout_template.dart';

enum SettingsStatus {
  initial,
  loading,
  loaded,
  saving,
  saved,
  error,
}

class SettingsState {
  final SettingsStatus status;
  final TimerSettings timerSettings;
  final TimerStyle timerStyle;
  final String? errorMessage;
  final TemplateId? selectedTemplateId;
  final List<CustomTemplate> customTemplates;
  final CustomTemplate? selectedCustomTemplate;

  const SettingsState({
    required this.status,
    required this.timerSettings,
    required this.timerStyle,
    this.errorMessage,
    this.selectedTemplateId,
    this.customTemplates = const [],
    this.selectedCustomTemplate,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    TimerSettings? timerSettings,
    TimerStyle? timerStyle,
    String? errorMessage,
    TemplateId? selectedTemplateId,
    bool clearSelectedTemplate = false,
    List<CustomTemplate>? customTemplates,
    CustomTemplate? selectedCustomTemplate,
    bool clearSelectedCustomTemplate = false,
  }) {
    return SettingsState(
      status: status ?? this.status,
      timerSettings: timerSettings ?? this.timerSettings,
      timerStyle: timerStyle ?? this.timerStyle,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedTemplateId: clearSelectedTemplate ? null : selectedTemplateId ?? this.selectedTemplateId,
      customTemplates: customTemplates ?? this.customTemplates,
      selectedCustomTemplate:
          clearSelectedCustomTemplate ? null : selectedCustomTemplate ?? this.selectedCustomTemplate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsState &&
          other.status == status &&
          other.timerSettings == timerSettings &&
          other.timerStyle == timerStyle &&
          other.selectedTemplateId == selectedTemplateId &&
          other.errorMessage == errorMessage &&
          listEquals(other.customTemplates, customTemplates) &&
          other.selectedCustomTemplate == selectedCustomTemplate;

  @override
  int get hashCode => Object.hash(
        status,
        timerSettings,
        timerStyle,
        errorMessage,
        selectedTemplateId,
        Object.hashAll(customTemplates),
        selectedCustomTemplate,
      );
}
