import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/statistics/data/activity_access.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';
import 'package:sport_timer/features/statistics/domain/activity_session_creation.dart';
import 'package:sport_timer/features/statistics/domain/activity_session_handle.dart';
import 'package:sport_timer/features/statistics/domain/completed_phase.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/domain/run_activity_summary.dart';
import 'package:sport_timer/features/statistics/domain/timer_session.dart';

typedef _ActivityOperation<T> = Future<T> Function();
typedef _SyncActivityOperation<T> = T Function();

class SqfliteActivityRepository implements ActivityRepository {
  final ActivityAccess _access;

  SqfliteActivityRepository(this._access);

  @override
  Stream<void> get changes => _access.changes;

  Future<Result<T>> _run<T>(_ActivityOperation<T> operation, {bool checkAccount = false}) async {
    final token = checkAccount ? _access.readToken : null;
    try {
      final value = await operation();
      if (checkAccount && _access.readToken != token) {
        return Failure(Exception('Account changed during activity read'));
      }
      return Success(value);
    } on Exception catch (error) {
      return Failure(error);
    } on StateError catch (error) {
      return Failure(Exception(error.message));
    }
  }

  Result<T> _runSync<T>(_SyncActivityOperation<T> operation) {
    try {
      return Success(operation());
    } on Exception catch (error) {
      return Failure(error);
    } on StateError catch (error) {
      return Failure(Exception(error.message));
    }
  }

  @override
  Result<ActivitySessionCreation> prepareSession(TimerSession session) =>
      _runSync(() => _access.prepareSession(session));

  @override
  Future<Result<ActivitySessionHandle>> createPreparedSession(ActivitySessionCreation creation) =>
      _run(() => _access.createPreparedSession(creation));

  @override
  Future<Result<ActivitySessionHandle>> createSession(TimerSession session) =>
      _run(() => _access.createSession(session));

  @override
  Future<Result<ActivitySessionHandle>> openSession(String sessionId) =>
      _run(() => _access.openSession(sessionId), checkAccount: true);

  @override
  Future<Result<void>> recordPhases({
    required ActivitySessionHandle session,
    required List<CompletedPhase> phases,
  }) =>
      _run(() => _access.addPhases(session: session, phases: phases));

  @override
  Future<Result<void>> endSession({
    required ActivitySessionHandle session,
    required int endedAtUtcMs,
  }) =>
      _run(() => _access.endSession(session: session, endedAtUtcMs: endedAtUtcMs));

  @override
  Future<Result<void>> deleteAllActivity() => _run(_access.deleteAllActivity);

  @override
  Future<Result<List<TimerSession>>> readSessions() => _run(_access.readSessions, checkAccount: true);

  @override
  Future<Result<List<CompletedPhase>>> readPhases(String sessionId) =>
      _run(() => _access.readPhases(sessionId), checkAccount: true);

  @override
  Future<Result<List<DailyActivity>>> readDailyActivity() => _run(_access.readDailyActivity, checkAccount: true);

  @override
  Future<Result<List<RunActivitySummary>>> readDayActivity(String localDate) =>
      _run(() => _access.readDayActivity(localDate), checkAccount: true);
}
