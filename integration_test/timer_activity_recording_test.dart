import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/settings/domain/timer_style.dart';
import 'package:sport_timer/features/statistics/data/activity_access.dart';
import 'package:sport_timer/features/statistics/data/activity_database.dart';
import 'package:sport_timer/features/statistics/data/sqflite_activity_repository.dart';
import 'package:sport_timer/features/statistics/domain/activity_account_source.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';
import 'package:sport_timer/features/statistics/domain/activity_session_creation.dart';
import 'package:sport_timer/features/statistics/domain/activity_session_handle.dart';
import 'package:sport_timer/features/statistics/domain/completed_phase.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/domain/timer_session.dart';
import 'package:sport_timer/features/timer/data/default_timer_activity_recorder.dart';
import 'package:sport_timer/features/timer/domain/audio_manager.dart';
import 'package:sport_timer/features/timer/domain/background_keep_alive.dart';
import 'package:sport_timer/features/timer/domain/timer_params.dart';
import 'package:sport_timer/features/timer/presentation/timer_view_model.dart';
import 'package:sqflite/sqflite.dart';

class _Accounts implements ActivityAccountSource {
  final controller = StreamController<void>.broadcast(sync: true);
  String? account = 'owner';

  @override
  String? get currentAccountId => account;

  @override
  Stream<void> get changes => controller.stream;

  void change(String value) {
    account = value;
    controller.add(null);
  }
}

class _Audio implements AudioManager {
  @override
  Future<void> dispose() async {}
  @override
  void playPreparationSound() {}
  @override
  void playRoundFinishSound() {}
  @override
  void playRoundStartSound() {}
  @override
  void playWorkoutDoneSound() {}
}

class _KeepAlive implements BackgroundKeepAlive {
  @override
  Future<void> start({
    required String notificationTitle,
    required String notificationText,
    required KeepAliveAction onPause,
    required KeepAliveAction onResume,
  }) async {}
  @override
  Future<void> setPaused({required bool isPaused}) async {}
  @override
  Future<void> updateText({required String text}) async {}
  @override
  Future<void> stop() async {}
}

class _UncertainRepository implements ActivityRepository {
  final ActivityRepository delegate;
  final attempts = <List<CompletedPhase>>[];
  final firstCommit = Completer<void>();
  final ended = Completer<void>();
  final bool loseResponse;

  _UncertainRepository(this.delegate, {this.loseResponse = true});

  @override
  Result<ActivitySessionCreation> prepareSession(TimerSession session) => delegate.prepareSession(session);
  @override
  Future<Result<ActivitySessionHandle>> createPreparedSession(ActivitySessionCreation creation) =>
      delegate.createPreparedSession(creation);
  @override
  Future<Result<void>> recordPhases({
    required ActivitySessionHandle session,
    required List<CompletedPhase> phases,
  }) async {
    attempts.add(List.of(phases));
    final result = await delegate.recordPhases(session: session, phases: phases);
    if (loseResponse && attempts.length == 1 && result is Success<void>) {
      firstCommit.complete();
      return Failure(Exception('Commit response lost'));
    }
    return result;
  }

  @override
  Future<Result<void>> endSession({required ActivitySessionHandle session, required int endedAtUtcMs}) async {
    final result = await delegate.endSession(session: session, endedAtUtcMs: endedAtUtcMs);
    ended.complete();
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('timer retries an uncertain commit under the original account and survives reopening', (tester) async {
    final dbPath = path.join(await getDatabasesPath(), 'timer_recording_${DateTime.now().microsecondsSinceEpoch}.db');
    final accounts = _Accounts();
    var db = ActivityDatabase(databasePath: dbPath);
    var access = ActivityAccess(db, accounts);
    var repository = SqfliteActivityRepository(access);
    final uncertain = _UncertainRepository(repository);
    var now = DateTime(2026, 11, 1, 23, 59, 40);
    var elapsed = Duration.zero;
    var id = 0;
    final recorder = DefaultTimerActivityRecorder(
      uncertain,
      accounts,
      clock: () => now,
      newId: () => 'id-${id++}',
    );
    const params = TimerParams(
      preparationTime: Duration(seconds: 2),
      roundTime: Duration(seconds: 10),
      restTime: Duration(seconds: 5),
      rounds: 2,
      style: TimerStyle.ring,
    );
    final viewModel = TimerViewModel(
      params,
      _Audio(),
      _KeepAlive(),
      timeSource: () => elapsed,
      activityRecorder: recorder,
    );
    final failure = recorder.failures.first;
    try {
      viewModel.start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Workout');
      elapsed = const Duration(seconds: 7);
      now = now.add(const Duration(seconds: 7));
      viewModel.togglePauseResume();
      now = now.add(const Duration(seconds: 20));
      viewModel.togglePauseResume();
      elapsed += const Duration(seconds: 20);
      now = now.add(const Duration(seconds: 20));
      viewModel.reconcileProgress();
      viewModel.dispose();

      await uncertain.firstCommit.future.timeout(const Duration(seconds: 10));
      await failure.timeout(const Duration(seconds: 10));
      accounts.change('other');
      recorder.retryPendingWrites();
      await uncertain.ended.future.timeout(const Duration(seconds: 10));
      expect(uncertain.attempts, hasLength(2));
      expect(uncertain.attempts.first, uncertain.attempts.last);
      expect((await repository.readSessions() as Success<List<TimerSession>>).value, isEmpty);
      accounts.change('owner');
      final sessions = (await repository.readSessions() as Success<List<TimerSession>>).value;
      expect(sessions, hasLength(1));
      final phases = (await repository.readPhases(sessions.single.id) as Success<List<CompletedPhase>>).value;
      expect(phases, uncertain.attempts.first);
      expect(phases.map((phase) => phase.schedulePosition), [1, 2, 3]);
      expect(phases.map((phase) => phase.localCompletionDate), ['2026-11-02', '2026-11-02', '2026-11-02']);
      final day = (await repository.readDailyActivity() as Success<List<DailyActivity>>).value.single;
      expect(day.roundCount, 2);
      expect(day.workDurationMs, 20000);
      expect(day.restDurationMs, 5000);
      expect(day.totalDurationMs, 25000);

      final earlyWrites = _UncertainRepository(repository, loseResponse: false);
      final earlyRecorder = DefaultTimerActivityRecorder(
        earlyWrites,
        accounts,
        clock: () => now,
        newId: () => 'id-${id++}',
      );
      elapsed = Duration.zero;
      final early = TimerViewModel(
        params,
        _Audio(),
        _KeepAlive(),
        timeSource: () => elapsed,
        activityRecorder: earlyRecorder,
      );
      early.start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Workout');
      elapsed = const Duration(seconds: 12);
      now = now.add(const Duration(seconds: 12));
      early.reconcileProgress();
      elapsed += const Duration(seconds: 4);
      now = now.add(const Duration(seconds: 4));
      early.dispose();
      await earlyWrites.ended.future.timeout(const Duration(seconds: 10));
      final earlySessions = (await repository.readSessions() as Success<List<TimerSession>>).value;
      expect(earlySessions, hasLength(2));
      final earlySession = earlySessions.singleWhere((session) => session.id != sessions.single.id);
      final earlyPhases = (await repository.readPhases(earlySession.id) as Success<List<CompletedPhase>>).value;
      expect(earlyPhases.map((phase) => phase.type), [CompletedPhaseType.work]);
      expect(earlyPhases.single.durationMs, 10000);
      earlyRecorder.dispose();

      await access.close();
      await db.close();
      db = ActivityDatabase(databasePath: dbPath);
      access = ActivityAccess(db, accounts);
      repository = SqfliteActivityRepository(access);
      expect((await repository.readPhases(sessions.single.id) as Success<List<CompletedPhase>>).value, phases);
      expect(
        (await repository.readDailyActivity() as Success<List<DailyActivity>>).value.single.totalDurationMs,
        35000,
      );
    } finally {
      viewModel.dispose();
      recorder.dispose();
      await access.close();
      await db.close();
      await accounts.controller.close();
      await deleteDatabase(dbPath);
    }
  });
}
