import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/statistics/domain/activity_session_creation.dart';
import 'package:sport_timer/features/statistics/domain/activity_session_handle.dart';
import 'package:sport_timer/features/statistics/domain/completed_phase.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/domain/run_activity_summary.dart';
import 'package:sport_timer/features/statistics/domain/timer_session.dart';

abstract interface class ActivityRepository {
  // Clear and refresh account-specific state when this stream emits. Consumers
  // must discard results invalidated before they update their own state.
  Stream<void> get changes;

  // Capture ownership before asynchronous writes so retries keep the same owner.
  Result<ActivitySessionCreation> prepareSession(TimerSession session);
  Future<Result<ActivitySessionHandle>> createPreparedSession(ActivitySessionCreation creation);
  Future<Result<ActivitySessionHandle>> createSession(TimerSession session);
  Future<Result<ActivitySessionHandle>> openSession(String sessionId);

  // Retry a failed batch with the same phase IDs and values. Only advance a
  // completion checkpoint after this method succeeds.
  Future<Result<void>> recordPhases({
    required ActivitySessionHandle session,
    required List<CompletedPhase> phases,
  });

  Future<Result<void>> endSession({
    required ActivitySessionHandle session,
    required int endedAtUtcMs,
  });

  // Deletes every account's local activity. Writes prepared before the call are dropped.
  Future<Result<void>> deleteAllActivity();

  Future<Result<List<TimerSession>>> readSessions();
  Future<Result<List<CompletedPhase>>> readPhases(String sessionId);
  Future<Result<List<DailyActivity>>> readDailyActivity();
  Future<Result<List<RunActivitySummary>>> readDayActivity(String localDate);
}
