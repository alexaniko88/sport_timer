import 'package:audioplayers/audioplayers.dart';
import 'package:get_it/get_it.dart';
import 'package:sport_timer/features/settings/settings_repository.dart';
import 'package:sport_timer/features/user/user_repository.dart';
import 'package:sport_timer/managers/audio_manager.dart';
import 'package:sport_timer/managers/default_audio_manager.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  getIt
    ..registerLazySingleton(AudioPlayer.new)
    ..registerLazySingleton<UserRepository>(FirebaseUserRepository.new)
    ..registerLazySingleton<SettingsRepository>(
        SharedPreferencesSettingsRepository.new)
    ..registerLazySingleton<AudioManager>(() => DefaultAudioManager(getIt()));
}
