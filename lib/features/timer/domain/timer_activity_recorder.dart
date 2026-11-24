import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/timer/domain/timer_params.dart';

abstract interface class TimerActivityRecorder {
  // Captures the current account before returning and queues the session write.
  Result<TimerActivityRun> start(TimerParams params);

  // Failed session creation and finishRun writes stay queued until retried.
  // A failed draft is dropped when a newer write replaces it or a write waits behind it.
  // Events report each failure.
  Stream<Exception> get failures;
  void retryPendingWrites();
}

abstract interface class TimerActivityRun {
  // Elapsed time includes active time only and must not decrease. These only
  // update the run in memory; nothing is written until end.
  void reconcile(Duration elapsed);
  void pause(Duration elapsed);
  void resume();

  // Queues the one write of the whole run, with its partial phase and end time,
  // without waiting for storage.
  void end(Duration elapsed);
}
