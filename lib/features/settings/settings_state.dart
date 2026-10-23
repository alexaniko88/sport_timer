part of 'settings.dart';

enum SettingsStatus { initial, loading, loaded, saving, saved, error }

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    required SettingsStatus status,
    required TimerSettings timerSettings,
    String? errorMessage,
  }) = _SettingsState;
}
