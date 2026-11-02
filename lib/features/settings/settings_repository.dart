import 'dart:convert';

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

class TimerConfiguration {
  final TimerSettings settings;
  final String? selectedTemplateId;

  const TimerConfiguration(this.settings, this.selectedTemplateId);

  @override
  bool operator ==(Object other) =>
      other is TimerConfiguration && other.settings == settings && other.selectedTemplateId == selectedTemplateId;

  @override
  int get hashCode => Object.hash(settings, selectedTemplateId);
}

abstract class SettingsRepository {
  Future<Result<TimerConfiguration>> getTimerConfiguration();
  Future<Result<void>> saveTimerConfiguration(TimerConfiguration configuration);
  Future<Result<TimerSettings>> getTimerSettings();
  Future<Result<void>> saveTimerSettings(TimerSettings settings);
  Future<Result<TimerStyle>> getTimerStyle();
  Future<Result<void>> saveTimerStyle(TimerStyle style);
}

class SharedPreferencesSettingsRepository implements SettingsRepository {
  static const String _configurationKey = 'timer_configuration';
  static const String _preparationTimeKey = 'preparation_time';
  static const String _roundTimeKey = 'round_time';
  static const String _restTimeKey = 'rest_time';
  static const String _roundsKey = 'rounds';
  static const String _timerStyleKey = 'timer_style';

  final Set<String> _failedWrites = {};

  @override
  Future<Result<TimerConfiguration>> getTimerConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // A failed platform write can still change the shared in-memory cache.
      await prefs.reload();
      final raw = prefs.getString(_configurationKey);
      if (raw == null) {
        final legacy = await getTimerSettings();
        return switch (legacy) {
          Success(:final value) => Success(TimerConfiguration(value, null)),
          Failure(:final error) => Failure(error),
        };
      }
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return Success(
        TimerConfiguration(
          TimerSettings(
            preparationTime: Duration(seconds: data['preparation'] as int),
            roundTime: Duration(seconds: data['round'] as int),
            restTime: Duration(seconds: data['rest'] as int),
            rounds: (data['rounds'] as int).clamp(1, TimerSettings.maxRounds),
          ),
          data['template'] as String?,
        ),
      );
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveTimerConfiguration(TimerConfiguration configuration) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final settings = configuration.settings;
      final encoded = jsonEncode({
        'preparation': settings.preparationTime.inSeconds,
        'round': settings.roundTime.inSeconds,
        'rest': settings.restTime.inSeconds,
        'rounds': settings.rounds,
        'template': configuration.selectedTemplateId,
      });
      if (!_failedWrites.contains(_configurationKey) && prefs.getString(_configurationKey) == encoded) {
        return const Success(null);
      }
      _failedWrites.add(_configurationKey);
      if (!await prefs.setString(_configurationKey, encoded)) {
        return Failure(Exception('Could not save timer configuration'));
      }
      _failedWrites.remove(_configurationKey);
      return const Success(null);
    } catch (e) {
      return Failure(e is Exception ? e : Exception(e.toString()));
    }
  }

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

      final values = {
        _preparationTimeKey: settings.preparationTime.inSeconds,
        _roundTimeKey: settings.roundTime.inSeconds,
        _restTimeKey: settings.restTime.inSeconds,
        _roundsKey: settings.rounds,
      };
      const defaults = {
        _preparationTimeKey: 20,
        _roundTimeKey: 60,
        _restTimeKey: 30,
        _roundsKey: 5,
      };
      for (final entry in values.entries) {
        if (!_failedWrites.contains(entry.key) && (prefs.getInt(entry.key) ?? defaults[entry.key]) == entry.value) {
          continue;
        }
        // SharedPreferences updates its cache even when the platform write fails.
        _failedWrites.add(entry.key);
        if (!await prefs.setInt(entry.key, entry.value)) {
          return Failure(Exception('Could not save timer settings'));
        }
        _failedWrites.remove(entry.key);
      }
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
