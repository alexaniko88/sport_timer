import 'package:sport_timer/features/settings/settings_repository.dart';
import 'package:sport_timer/features/settings/timer_style.dart';

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

  const SettingsState({
    required this.status,
    required this.timerSettings,
    required this.timerStyle,
    this.errorMessage,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    TimerSettings? timerSettings,
    TimerStyle? timerStyle,
    String? errorMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      timerSettings: timerSettings ?? this.timerSettings,
      timerStyle: timerStyle ?? this.timerStyle,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsState &&
          other.status == status &&
          other.timerSettings == timerSettings &&
          other.timerStyle == timerStyle &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(status, timerSettings, timerStyle, errorMessage);
}
