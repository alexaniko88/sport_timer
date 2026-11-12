import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:sport_timer/features/settings/domain/settings_repository.dart';
import 'package:sport_timer/features/settings/data/shared_preferences_settings_repository.dart';
import 'package:sport_timer/features/templates/data/shared_preferences_custom_template_repository.dart';
import 'package:sport_timer/features/templates/domain/custom_template_repository.dart';
import 'package:sport_timer/features/statistics/data/activity_access.dart';
import 'package:sport_timer/features/statistics/domain/activity_account_source.dart';
import 'package:sport_timer/features/statistics/data/activity_database.dart';
import 'package:sport_timer/features/statistics/data/firebase_activity_account_source.dart';
import 'package:sport_timer/features/statistics/data/sqflite_activity_repository.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';
import 'package:sport_timer/features/user/domain/user_repository.dart';
import 'package:sport_timer/features/user/data/firebase_user_repository.dart';
import 'package:sport_timer/features/timer/domain/audio_manager.dart';
import 'package:sport_timer/features/timer/domain/background_keep_alive.dart';
import 'package:sport_timer/features/timer/data/default_audio_manager.dart';
import 'package:sport_timer/features/timer/data/default_background_keep_alive.dart';
import 'package:sport_timer/features/timer/data/default_timer_activity_recorder.dart';
import 'package:sport_timer/features/timer/domain/timer_activity_recorder.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  getIt
    ..registerLazySingleton(AudioPlayer.new)
    ..registerLazySingleton<UserRepository>(FirebaseUserRepository.new)
    ..registerLazySingleton<SettingsRepository>(
      SharedPreferencesSettingsRepository.new,
    )
    ..registerLazySingleton<CustomTemplateRepository>(SharedPreferencesCustomTemplateRepository.new)
    ..registerLazySingleton<ActivityDatabase>(ActivityDatabase.new, dispose: (database) => database.close())
    ..registerLazySingleton<ActivityAccountSource>(() => FirebaseActivityAccountSource(FirebaseAuth.instance))
    ..registerLazySingleton<ActivityAccess>(
      () => ActivityAccess(getIt(), getIt()),
      dispose: (access) => access.close(),
    )
    ..registerLazySingleton<ActivityRepository>(() => SqfliteActivityRepository(getIt()))
    ..registerLazySingleton<DefaultTimerActivityRecorder>(
      () => DefaultTimerActivityRecorder(getIt(), getIt()),
      dispose: (recorder) => recorder.dispose(),
    )
    ..registerLazySingleton<TimerActivityRecorder>(() => getIt<DefaultTimerActivityRecorder>())
    ..registerLazySingleton<AudioManager>(() => DefaultAudioManager(getIt()))
    ..registerLazySingleton<BackgroundKeepAlive>(DefaultBackgroundKeepAlive.new);
}
