import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_repository.freezed.dart';

@freezed
class TimerSettings with _$TimerSettings {
  const factory TimerSettings({
    required Duration preparationTime,
    required Duration roundTime,
    required Duration restTime,
    required int rounds,
  }) = _TimerSettings;
}

abstract class SettingsRepository {
  Future<TimerSettings> getTimerSettings();
  Future<void> saveTimerSettings(TimerSettings settings);
}

@LazySingleton(as: SettingsRepository)
class SharedPreferencesSettingsRepository implements SettingsRepository {
  static const String _preparationTimeKey = 'preparation_time';
  static const String _roundTimeKey = 'round_time';
  static const String _restTimeKey = 'rest_time';
  static const String _roundsKey = 'rounds';

  @override
  Future<TimerSettings> getTimerSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return TimerSettings(
      preparationTime: Duration(seconds: prefs.getInt(_preparationTimeKey) ?? 20),
      roundTime: Duration(seconds: prefs.getInt(_roundTimeKey) ?? 60),
      restTime: Duration(seconds: prefs.getInt(_restTimeKey) ?? 30),
      rounds: prefs.getInt(_roundsKey) ?? 5,
    );
  }

  @override
  Future<void> saveTimerSettings(TimerSettings settings) async {
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      prefs.setInt(_preparationTimeKey, settings.preparationTime.inSeconds),
      prefs.setInt(_roundTimeKey, settings.roundTime.inSeconds),
      prefs.setInt(_restTimeKey, settings.restTime.inSeconds),
      prefs.setInt(_roundsKey, settings.rounds),
    ]);
  }
}
