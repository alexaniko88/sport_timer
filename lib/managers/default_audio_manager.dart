import 'package:audioplayers/audioplayers.dart';
import 'package:injectable/injectable.dart';
import 'package:sport_timer/managers/audio_manager.dart';

@LazySingleton(as: AudioManager)
class DefaultAudioManager extends AudioManager {
  DefaultAudioManager(this.audioPlayer) {
    audioPlayer.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        contentType: AndroidContentType.sonification,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
      ),
    ));
  }

  final AudioPlayer audioPlayer;

  @override
  Future<void> playPreparationSound() async {
    int playCount = 0;
    const int maxPlays = 3;
    await _playBeepSound();
    audioPlayer.onPlayerComplete.listen((event) async {
      playCount++;
      await audioPlayer.stop();
      if (playCount < maxPlays) {
        await _playBeepSound();
      }
    });
  }

  Future<void> _playBeepSound() => audioPlayer.play(
        AssetSource('audio/beep.mp3'),
        position: const Duration(milliseconds: 200),
      );

  @override
  void playRoundFinishSound() {
    audioPlayer.play(AssetSource('audio/3beeps.mp3'), volume: 1.0);
  }

  @override
  void playRoundStartSound() {
    audioPlayer.play(AssetSource('audio/3beeps.mp3'), volume: 1.0);
  }

  @override
  Future<void> dispose() => audioPlayer.dispose();
}
