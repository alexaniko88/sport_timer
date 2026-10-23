import 'package:sport_timer/features/settings/settings_repository.dart';

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
  final String? errorMessage;

  const SettingsState({
    required this.status,
    required this.timerSettings,
    this.errorMessage,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    TimerSettings? timerSettings,
    String? errorMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      timerSettings: timerSettings ?? this.timerSettings,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsState &&
          other.status == status &&
          other.timerSettings == timerSettings &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(status, timerSettings, errorMessage);
}
