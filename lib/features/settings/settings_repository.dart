import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/settings/timer_style.dart';

class TimerSettings {
  static const int maxRounds = 30;

  final Duration preparationTime;
  final Duration roundTime;
  final Duration restTime;
  final int rounds;

  const TimerSettings({
    required this.preparationTime,
    required this.roundTime,
    required this.restTime,
    required this.rounds,
  });

  TimerSettings copyWith({
    Duration? preparationTime,
    Duration? roundTime,
    Duration? restTime,
    int? rounds,
  }) {
    return TimerSettings(
      preparationTime: preparationTime ?? this.preparationTime,
      roundTime: roundTime ?? this.roundTime,
      restTime: restTime ?? this.restTime,
      rounds: rounds ?? this.rounds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerSettings &&
          other.preparationTime == preparationTime &&
          other.roundTime == roundTime &&
          other.restTime == restTime &&
          other.rounds == rounds;

  @override
  int get hashCode => Object.hash(preparationTime, roundTime, restTime, rounds);
}

abstract class SettingsRepository {
  Future<Result<TimerSettings>> getTimerSettings();
  Future<Result<void>> saveTimerSettings(TimerSettings settings);
  Future<Result<TimerStyle>> getTimerStyle();
  Future<Result<void>> saveTimerStyle(TimerStyle style);
}

class SharedPreferencesSettingsRepository implements SettingsRepository {
  static const String _preparationTimeKey = 'preparation_time';
  static const String _roundTimeKey = 'round_time';
  static const String _restTimeKey = 'rest_time';
  static const String _roundsKey = 'rounds';
  static const String _timerStyleKey = 'timer_style';

  @override
  Future<Result<TimerSettings>> getTimerSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return Success(
        TimerSettings(
          preparationTime: Duration(seconds: prefs.getInt(_preparationTimeKey) ?? 20),
          roundTime: Duration(seconds: prefs.getInt(_roundTimeKey) ?? 60),
          restTime: Duration(seconds: prefs.getInt(_restTimeKey) ?? 30),
          rounds: (prefs.getInt(_roundsKey) ?? 5).clamp(1, TimerSettings.maxRounds),
        ),
      );
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveTimerSettings(TimerSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        prefs.setInt(_preparationTimeKey, settings.preparationTime.inSeconds),
        prefs.setInt(_roundTimeKey, settings.roundTime.inSeconds),
        prefs.setInt(_restTimeKey, settings.restTime.inSeconds),
        prefs.setInt(_roundsKey, settings.rounds),
      ]);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<TimerStyle>> getTimerStyle() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_timerStyleKey);

      // A missing or unknown name falls back to the default style.
      return Success(TimerStyle.values.asNameMap()[name] ?? TimerStyle.ring);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveTimerStyle(TimerStyle style) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_timerStyleKey, style.name);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }
}
