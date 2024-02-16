import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:injectable/injectable.dart';

@module
abstract class InjectorModule {
  @lazySingleton
  AssetsAudioPlayer get audioPlayer => AssetsAudioPlayer();
}
