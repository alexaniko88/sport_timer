import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:sport_timer/managers/audio_manager.dart';

class DefaultAudioManager extends AudioManager {
  final AudioPlayer audioPlayer;
  StreamSubscription<void>? _preparationSubscription;

  DefaultAudioManager(this.audioPlayer) {
    // The iOS audio session is shared by the whole app. Mixing with others keeps
    // the silent keep-alive loop from stopping the user's music or the beeps.
    final ios = AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: {AVAudioSessionOptions.mixWithOthers},
    );
    audioPlayer
        .setAudioContext(
          AudioContext(
            iOS: ios,
            android: const AudioContextAndroid(
              contentType: AndroidContentType.sonification,
              audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            ),
          ),
        )
        .catchError((Object error) => debugPrint('$runtimeType:: audio context failed: $error'));
  }

  @override
  Future<void> playPreparationSound() async {
    int playCount = 0;
    const int maxPlays = 3;
    // Drop the listener of a previous sequence so the beeps do not stack up.
    await _preparationSubscription?.cancel();
    await _playBeepSound();
    _preparationSubscription = audioPlayer.onPlayerComplete.listen((event) async {
      playCount++;
      await audioPlayer.stop();
      if (playCount < maxPlays) {
        await _playBeepSound();
      } else {
        await _preparationSubscription?.cancel();
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
  void playWorkoutDoneSound() {
    audioPlayer.play(AssetSource('audio/workout_done.mp3'), volume: 1.0);
  }

  @override
  void playRoundStartSound() {
    audioPlayer.play(AssetSource('audio/3beeps.mp3'), volume: 1.0);
  }

  @override
  Future<void> dispose() => audioPlayer.dispose();
}
