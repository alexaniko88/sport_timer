abstract class AudioManager {
  void playRoundFinishSound();

  void playWorkoutDoneSound();

  void playRoundStartSound();

  void playCountdownBeep();

  Future<void> dispose();
}
