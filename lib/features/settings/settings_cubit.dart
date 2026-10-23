part of 'settings.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._settingsRepository)
      : super(
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

  final SettingsRepository _settingsRepository;

  Future<void> loadSettings() async {
    emit(state.copyWith(status: SettingsStatus.loading));
    final result = await _settingsRepository.getTimerSettings();
    switch (result) {
      case Success(:final value):
        emit(state.copyWith(
          status: SettingsStatus.loaded,
          timerSettings: value,
        ));
      case Failure(:final error):
        emit(state.copyWith(
          status: SettingsStatus.error,
          errorMessage: error.toString(),
        ));
    }
  }

  Future<void> saveSettings(TimerSettings settings) async {
    emit(state.copyWith(status: SettingsStatus.saving));
    final result = await _settingsRepository.saveTimerSettings(settings);
    switch (result) {
      case Success():
        emit(state.copyWith(
          status: SettingsStatus.saved,
          timerSettings: settings,
        ));
      case Failure(:final error):
        emit(state.copyWith(
          status: SettingsStatus.error,
          errorMessage: error.toString(),
        ));
    }
  }

  void updatePreparationTime(Duration duration) {
    final updatedSettings =
        state.timerSettings.copyWith(preparationTime: duration);
    emit(state.copyWith(timerSettings: updatedSettings));
  }

  void updateRoundTime(Duration duration) {
    final updatedSettings = state.timerSettings.copyWith(roundTime: duration);
    emit(state.copyWith(timerSettings: updatedSettings));
  }

  void updateRestTime(Duration duration) {
    final updatedSettings = state.timerSettings.copyWith(restTime: duration);
    emit(state.copyWith(timerSettings: updatedSettings));
  }

  void updateRounds(int rounds) {
    final updatedSettings = state.timerSettings.copyWith(rounds: rounds);
    emit(state.copyWith(timerSettings: updatedSettings));
  }
}
