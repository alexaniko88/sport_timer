import 'package:sport_timer/features/settings/settings_repository.dart';
import 'package:sport_timer/features/settings/timer_style.dart';
import 'package:sport_timer/features/templates/workout_template.dart';

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

  const SettingsState({
    required this.status,
    required this.timerSettings,
    required this.timerStyle,
    this.errorMessage,
    this.selectedTemplateId,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    TimerSettings? timerSettings,
    TimerStyle? timerStyle,
    String? errorMessage,
    TemplateId? selectedTemplateId,
    bool clearSelectedTemplate = false,
  }) {
    return SettingsState(
      status: status ?? this.status,
      timerSettings: timerSettings ?? this.timerSettings,
      timerStyle: timerStyle ?? this.timerStyle,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedTemplateId: clearSelectedTemplate ? null : selectedTemplateId ?? this.selectedTemplateId,
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
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(status, timerSettings, timerStyle, errorMessage, selectedTemplateId);
}
