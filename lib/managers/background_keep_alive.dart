/// Keeps the app running with the screen off or in the background, so the
/// timer keeps counting and the round sounds keep playing.
abstract class BackgroundKeepAlive {
  Future<void> start({required String notificationTitle});

  Future<void> stop();
}
