import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/settings/domain/timer_configuration.dart';
import 'package:sport_timer/features/settings/domain/timer_settings.dart';
import 'package:sport_timer/features/settings/domain/timer_style.dart';

abstract class SettingsRepository {
  Future<Result<TimerConfiguration>> getTimerConfiguration();
  Future<Result<void>> saveTimerConfiguration(TimerConfiguration configuration);
  Future<Result<TimerSettings>> getTimerSettings();
  Future<Result<void>> saveTimerSettings(TimerSettings settings);
  Future<Result<TimerStyle>> getTimerStyle();
  Future<Result<void>> saveTimerStyle(TimerStyle style);
}
