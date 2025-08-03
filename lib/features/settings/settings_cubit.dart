part of 'settings.dart';

@injectable
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
    try {
      final settings = await _settingsRepository.getTimerSettings();
      emit(state.copyWith(
        status: SettingsStatus.loaded,
        timerSettings: settings,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> saveSettings(TimerSettings settings) async {
    emit(state.copyWith(status: SettingsStatus.saving));
    try {
      await _settingsRepository.saveTimerSettings(settings);
      emit(state.copyWith(
        status: SettingsStatus.saved,
        timerSettings: settings,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void updatePreparationTime(Duration duration) {
    if (state.timerSettings != null) {
      final updatedSettings = state.timerSettings!.copyWith(preparationTime: duration);
      emit(state.copyWith(timerSettings: updatedSettings));
    }
  }

  void updateRoundTime(Duration duration) {
    if (state.timerSettings != null) {
      final updatedSettings = state.timerSettings!.copyWith(roundTime: duration);
      emit(state.copyWith(timerSettings: updatedSettings));
    }
  }

  void updateRestTime(Duration duration) {
    if (state.timerSettings != null) {
      final updatedSettings = state.timerSettings!.copyWith(restTime: duration);
      emit(state.copyWith(timerSettings: updatedSettings));
    }
  }

  void updateRounds(int rounds) {
    if (state.timerSettings != null) {
      final updatedSettings = state.timerSettings!.copyWith(rounds: rounds);
      emit(state.copyWith(timerSettings: updatedSettings));
    }
  }
}
