import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:sport_timer/features/settings/settings_repository.dart';
import 'package:sport_timer/features/statistics/activity_access.dart';
import 'package:sport_timer/features/statistics/activity_account_source.dart';
import 'package:sport_timer/features/statistics/activity_database.dart';
import 'package:sport_timer/features/statistics/firebase_activity_account_source.dart';
import 'package:sport_timer/features/user/user_repository.dart';
import 'package:sport_timer/managers/audio_manager.dart';
import 'package:sport_timer/managers/background_keep_alive.dart';
import 'package:sport_timer/managers/default_audio_manager.dart';
import 'package:sport_timer/managers/default_background_keep_alive.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  getIt
    ..registerLazySingleton(AudioPlayer.new)
    ..registerLazySingleton<UserRepository>(FirebaseUserRepository.new)
    ..registerLazySingleton<SettingsRepository>(
      SharedPreferencesSettingsRepository.new,
    )
    ..registerLazySingleton<ActivityDatabase>(ActivityDatabase.new, dispose: (database) => database.close())
    ..registerLazySingleton<ActivityAccountSource>(() => FirebaseActivityAccountSource(FirebaseAuth.instance))
    ..registerLazySingleton<ActivityAccess>(
      () => ActivityAccess(getIt(), getIt()),
      dispose: (access) => access.close(),
    )
    ..registerLazySingleton<AudioManager>(() => DefaultAudioManager(getIt()))
    ..registerLazySingleton<BackgroundKeepAlive>(DefaultBackgroundKeepAlive.new);
}
