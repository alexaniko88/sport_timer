import 'package:flutter/foundation.dart';

/// Keeps the app running with the screen off or in the background, so the
/// timer keeps counting and the round sounds keep playing.
abstract class BackgroundKeepAlive {
  /// [onPause] and [onResume] run when the user taps the notification button or
  /// a headphone button. They are dropped on [stop].
  Future<void> start({
    required String notificationTitle,
    required String notificationText,
    required VoidCallback onPause,
    required VoidCallback onResume,
  });

  /// Shows the play button while paused and the pause button otherwise.
  Future<void> setPaused({required bool isPaused});

  Future<void> updateText({required String text});

  Future<void> stop();
}
