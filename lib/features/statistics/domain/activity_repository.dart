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

  // Stores the phases and the end time in one transaction. Retry a failure with
  // the same phase IDs, values and end time.
  Future<Result<void>> finishRun({
    required ActivitySessionHandle session,
    required List<CompletedPhase> phases,
    required int endedAtUtcMs,
  });

  // Replaces the hidden draft of a running session. Statistics never read it.
  // Writes nothing for an ended session or a handle from before a purge.
  Future<Result<void>> saveDraft({
    required ActivitySessionHandle session,
    required List<CompletedPhase> phases,
    required int checkpointAtUtcMs,
  });

  // Turns the drafts of sessions started before the given time into final records,
  // for every account. A failed session keeps its draft for the next start.
  Future<Result<void>> recoverUnfinishedRuns({required int startedBeforeUtcMs});

  // Deletes every account's local activity. Writes prepared before the call are dropped.
  Future<Result<void>> deleteAllActivity();

  // Deletes the signed-in account's local activity. That account's writes issued before the call are dropped.
  Future<Result<void>> deleteAccountActivity();

  Future<Result<List<TimerSession>>> readSessions();
  Future<Result<List<CompletedPhase>>> readPhases(String sessionId);
  Future<Result<List<DailyActivity>>> readDailyActivity();
  Future<Result<List<RunActivitySummary>>> readDayActivity(String localDate);
}
