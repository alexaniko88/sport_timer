import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/statistics/data/activity_access.dart';
import 'package:sport_timer/features/statistics/data/activity_database.dart';
import 'package:sport_timer/features/statistics/data/sqflite_activity_repository.dart';
import 'package:sport_timer/features/statistics/domain/activity_account_source.dart';
import 'package:sport_timer/features/statistics/domain/activity_session_creation.dart';
import 'package:sport_timer/features/statistics/domain/activity_session_handle.dart';
import 'package:sport_timer/features/statistics/domain/completed_phase.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/domain/day_run_activity.dart';
import 'package:sport_timer/features/statistics/domain/timer_session.dart';
import 'package:sqflite/sqflite.dart';

class FakeAccounts implements ActivityAccountSource {
  final controller = StreamController<void>.broadcast(sync: true);
  String? account;

  @override
  String? get currentAccountId => account;

  @override
  Stream<void> get changes => controller.stream;

  void change(String? value) {
    account = value;
    controller.add(null);
  }
}

class FakeHandle implements ActivitySessionHandle {
  @override
  final String sessionId;

  FakeHandle(this.sessionId);
}

TimerSession session(String id, String account) => TimerSession(
      id: id,
      accountId: account,
      startedAtUtcMs: 1000,
      preparationDurationMs: 0,
      workDurationMs: 30000,
      restDurationMs: 10000,
      roundCount: 2,
    );

CompletedPhase phase({
  required String id,
  required String runId,
  required int position,
  CompletedPhaseType type = CompletedPhaseType.work,
  int duration = 30000,
  String date = '2026-11-02',
}) =>
    CompletedPhase(
      id: id,
      runId: runId,
      schedulePosition: position,
      type: type,
      roundNumber: 1,
      durationMs: duration,
      completedAtUtcMs: 31000,
      localCompletionDate: date,
      utcOffsetMinutes: 60,
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late String dbPath;
  late ActivityDatabase db;
  late ActivityAccess access;
  late SqfliteActivityRepository repository;
  late FakeAccounts accounts;

  setUp(() async {
    dbPath = path.join(await getDatabasesPath(), 'repository_${DateTime.now().microsecondsSinceEpoch}.db');
    accounts = FakeAccounts();
    db = ActivityDatabase(databasePath: dbPath);
    access = ActivityAccess(db, accounts);
    repository = SqfliteActivityRepository(access);
  });

  tearDown(() async {
    await access.close();
    await accounts.controller.close();
    await db.close();
    await deleteDatabase(dbPath);
  });

  testWidgets('exact retries succeed and conflicts roll back the whole batch', (tester) async {
    accounts.change('a');
    final run = (await repository.createSession(session('run', 'a')) as Success<ActivitySessionHandle>).value;
    final first = phase(id: 'first', runId: 'run', position: 0);
    expect(await repository.recordPhases(session: run, phases: [first]), isA<Success<void>>());
    expect(await repository.recordPhases(session: run, phases: [first]), isA<Success<void>>());
    final second = phase(id: 'second', runId: 'run', position: 1);
    final conflicting = phase(id: 'first', runId: 'run', position: 0, duration: 5);
    expect(await repository.recordPhases(session: run, phases: [second, conflicting]), isA<Failure<void>>());
    expect((await repository.readPhases('run') as Success<List<CompletedPhase>>).value, [first]);
    final positionConflict = phase(id: 'other-id', runId: 'run', position: 0);
    expect(await repository.recordPhases(session: run, phases: [positionConflict]), isA<Failure<void>>());
    expect(await repository.recordPhases(session: FakeHandle('run'), phases: [second]), isA<Failure<void>>());
    expect(await repository.recordPhases(session: run, phases: [second]), isA<Success<void>>());
    expect((await repository.readPhases('run') as Success<List<CompletedPhase>>).value, [first, second]);
  });

  testWidgets('daily totals use fixed dates and isolate accounts including pending writes', (tester) async {
    accounts.change('a');
    final a = (await repository.createSession(session('a', 'a')) as Success<ActivitySessionHandle>).value;
    const differentSettings = TimerSession(
      id: 'a2',
      accountId: 'a',
      startedAtUtcMs: 1000,
      preparationDurationMs: 5000,
      workDurationMs: 45000,
      restDurationMs: 15000,
      roundCount: 3,
    );
    final a2 = (await repository.createSession(differentSettings) as Success<ActivitySessionHandle>).value;
    await repository.createSession(session('empty', 'a'));
    await repository.recordPhases(
      session: a,
      phases: [
        phase(id: 'work', runId: 'a', position: 0),
        phase(id: 'rest', runId: 'a', position: 1, type: CompletedPhaseType.rest, duration: 10000),
        phase(id: 'old', runId: 'a', position: 2, date: '2026-11-01'),
        phase(
          id: 'rest-only',
          runId: 'a',
          position: 3,
          type: CompletedPhaseType.rest,
          duration: 15000,
          date: '2026-11-03',
        ),
      ],
    );
    accounts.change('b');
    final b = (await repository.createSession(session('b', 'b')) as Success<ActivitySessionHandle>).value;
    await repository.recordPhases(session: b, phases: [phase(id: 'b-work', runId: 'b', position: 0, duration: 5000)]);
    await repository
        .recordPhases(session: a2, phases: [phase(id: 'a2-work', runId: 'a2', position: 0, duration: 45000)]);
    final bDays = (await repository.readDailyActivity() as Success<List<DailyActivity>>).value;
    expect(bDays.single.workDurationMs, 5000);
    expect((await repository.readPhases('a') as Success<List<CompletedPhase>>).value, isEmpty);
    accounts.change('a');
    final days = (await repository.readDailyActivity() as Success<List<DailyActivity>>).value;
    expect(days, [
      const DailyActivity(localDate: '2026-11-03', roundCount: 0, workDurationMs: 0, restDurationMs: 15000),
      const DailyActivity(localDate: '2026-11-02', roundCount: 2, workDurationMs: 75000, restDurationMs: 10000),
      const DailyActivity(localDate: '2026-11-01', roundCount: 1, workDurationMs: 30000, restDurationMs: 0),
    ]);
    expect(days[1].totalDurationMs, 85000);
  });

  testWidgets('day activity groups runs by fixed date and account', (tester) async {
    accounts.change('a');
    final older = session('older', 'a');
    const newer = TimerSession(
      id: 'newer',
      accountId: 'a',
      startedAtUtcMs: 2000,
      preparationDurationMs: 5000,
      workDurationMs: 45000,
      restDurationMs: 15000,
      roundCount: 3,
    );
    final oldHandle = (await repository.createSession(older) as Success<ActivitySessionHandle>).value;
    final newHandle = (await repository.createSession(newer) as Success<ActivitySessionHandle>).value;
    await repository.createSession(session('empty', 'a'));
    await repository.recordPhases(
      session: oldHandle,
      phases: [
        phase(id: 'old-work', runId: 'older', position: 0),
        phase(id: 'old-rest', runId: 'older', position: 1, type: CompletedPhaseType.rest, duration: 10000),
        phase(
          id: 'next-day',
          runId: 'older',
          position: 2,
          type: CompletedPhaseType.rest,
          duration: 15000,
          date: '2026-11-03',
        ),
      ],
    );
    await repository.recordPhases(
      session: newHandle,
      phases: [
        phase(id: 'new-work', runId: 'newer', position: 0, duration: 45000),
      ],
    );
    accounts.change('b');
    final other = (await repository.createSession(session('other', 'b')) as Success<ActivitySessionHandle>).value;
    await repository.recordPhases(session: other, phases: [phase(id: 'other-work', runId: 'other', position: 0)]);
    final otherDay = (await repository.readDayActivity('2026-11-02') as Success<List<DayRunActivity>>).value;
    expect(otherDay.map((entry) => entry.session.id), ['other']);
    accounts.change('a');
    final day = (await repository.readDayActivity('2026-11-02') as Success<List<DayRunActivity>>).value;
    expect(day, [
      const DayRunActivity(
        session: newer,
        activity: DailyActivity(localDate: '2026-11-02', roundCount: 1, workDurationMs: 45000, restDurationMs: 0),
      ),
      DayRunActivity(
        session: older,
        activity: const DailyActivity(
          localDate: '2026-11-02',
          roundCount: 1,
          workDurationMs: 30000,
          restDurationMs: 10000,
        ),
      ),
    ]);
    expect(day.last.activity.totalDurationMs, 40000);
    final nextDay = (await repository.readDayActivity('2026-11-03') as Success<List<DayRunActivity>>).value;
    expect(nextDay, [
      DayRunActivity(
        session: older,
        activity: const DailyActivity(localDate: '2026-11-03', roundCount: 0, workDurationMs: 0, restDurationMs: 15000),
      ),
    ]);
    expect((await repository.readDayActivity('2026-11-04') as Success<List<DayRunActivity>>).value, isEmpty);
  });

  testWidgets('account changes invalidate reads and notify listeners', (tester) async {
    var changes = 0;
    final subscription = repository.changes.listen((_) => changes++);
    accounts.change('a');
    final pending = repository.readDailyActivity();
    accounts.change('b');
    accounts.change('a');
    expect(await pending, isA<Failure>());
    expect(changes, 3);
    final run = (await repository.createSession(session('run', 'a')) as Success<ActivitySessionHandle>).value;
    expect(changes, 4);
    await repository.recordPhases(session: run, phases: [phase(id: 'work', runId: 'run', position: 0)]);
    expect(changes, 5);
    await repository.recordPhases(session: run, phases: [phase(id: 'different', runId: 'run', position: 0)]);
    expect(changes, 5);
    await subscription.cancel();
  });

  testWidgets('known end time is owner-bound and exact retries succeed', (tester) async {
    accounts.change('a');
    final run = (await repository.createSession(session('run', 'a')) as Success<ActivitySessionHandle>).value;
    accounts.change('b');
    expect(await repository.endSession(session: run, endedAtUtcMs: 40000), isA<Success<void>>());
    expect(await repository.endSession(session: run, endedAtUtcMs: 40000), isA<Success<void>>());
    expect(await repository.endSession(session: run, endedAtUtcMs: 50000), isA<Failure<void>>());
    expect((await repository.readSessions() as Success<List<TimerSession>>).value, isEmpty);
    accounts.change('a');
    expect((await repository.readSessions() as Success<List<TimerSession>>).value.single.endedAtUtcMs, 40000);
  });

  testWidgets('prepared session retries keep their original account after a switch', (tester) async {
    accounts.change('a');
    final creation = (repository.prepareSession(session('run', 'a')) as Success<ActivitySessionCreation>).value;
    accounts.change('b');
    expect(await repository.createPreparedSession(creation), isA<Success<ActivitySessionHandle>>());
    expect(await repository.createPreparedSession(creation), isA<Success<ActivitySessionHandle>>());
    expect((await repository.readSessions() as Success<List<TimerSession>>).value, isEmpty);
    accounts.change('a');
    expect((await repository.readSessions() as Success<List<TimerSession>>).value, [session('run', 'a')]);

    const conflictingSession = TimerSession(
      id: 'run',
      accountId: 'a',
      startedAtUtcMs: 2000,
      preparationDurationMs: 0,
      workDurationMs: 30000,
      restDurationMs: 10000,
      roundCount: 2,
    );
    final conflict = (repository.prepareSession(conflictingSession) as Success<ActivitySessionCreation>).value;
    expect(await repository.createPreparedSession(conflict), isA<Failure<ActivitySessionHandle>>());
  });
}
