import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:injectable/injectable.dart';
import 'package:sport_timer/managers/audio_manager.dart';

@LazySingleton(as: AudioManager)
class DefaultAudioManager extends AudioManager {
  DefaultAudioManager(this.audioPlayer);

  final AssetsAudioPlayer audioPlayer;

  @override
  void playPreparationSound() {
    audioPlayer.open(
      Playlist(
          audios: [
            Audio("assets/audio/beep.mp3"),
            Audio("assets/audio/beep.mp3"),
            Audio("assets/audio/beep.mp3"),
          ]
      ),
      autoStart: true,
    );
  }

  @override
  void playRoundFinishSound() {
    audioPlayer.open(
      Audio('assets/audio/bell_ring.mp3'),
      autoStart: true,
    );
  }

  @override
  void playRoundStartSound() {
    audioPlayer.open(
      Audio('assets/audio/bell_ring.mp3'),
      autoStart: true,
    );
  }

  @override
  Future<void> dispose() => audioPlayer.dispose();
}
