import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/timer/domain/timer_params.dart';

abstract interface class TimerActivityRecorder {
  // Captures the current account before returning and queues the session write.
  Result<TimerActivityRun> start(TimerParams params);

  // Failed writes remain queued until retried; events report each failure.
  Stream<Exception> get failures;
  void retryPendingWrites();
}

abstract interface class TimerActivityRun {
  // Elapsed time includes active time only and must not decrease.
  void reconcile(Duration elapsed);
  void pause(Duration elapsed);
  void resume();

  // Queues final reconciliation and the known end without waiting for storage.
  void end(Duration elapsed);
}
