import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/statistics/data/activity_access.dart';
import 'package:sport_timer/features/statistics/data/activity_database.dart';
import 'package:sport_timer/features/statistics/data/sqflite_activity_repository.dart';
import 'package:sport_timer/features/statistics/domain/activity_account_source.dart';
import 'package:sport_timer/features/statistics/domain/completed_phase.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/domain/run_activity_summary.dart';
import 'package:sport_timer/features/statistics/domain/timer_session.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeAccounts implements ActivityAccountSource {
  final StreamController<void> controller;
  String? account = 'a';

  _FakeAccounts() : controller = StreamController<void>.broadcast(sync: true);

  @override
  String? get currentAccountId => account;

  @override
  Stream<void> get changes => controller.stream;
}

TimerSession _session(String id, String accountId) => TimerSession(
      id: id,
      accountId: accountId,
      startedAtUtcMs: 1000,
      preparationDurationMs: 0,
      workDurationMs: 30000,
      restDurationMs: 10000,
      roundCount: 2,
    );

CompletedPhase _phase(String id, String runId, int position) => CompletedPhase(
      id: id,
      runId: runId,
      schedulePosition: position,
      type: CompletedPhaseType.work,
      roundNumber: 1,
      durationMs: 30000,
      completedAtUtcMs: 2000,
      localCompletionDate: '2026-01-01',
      utcOffsetMinutes: 0,
    );

TimerSession _sessionWithWork(String id, int workDurationMs) => TimerSession(
      id: id,
      accountId: 'a',
      startedAtUtcMs: 1000,
      preparationDurationMs: 0,
      workDurationMs: workDurationMs,
      restDurationMs: 10000,
      roundCount: 2,
    );

CompletedPhase _work(String id, String runId, int position, int durationMs, {CompletedPhaseType? type}) =>
    CompletedPhase(
      id: id,
      runId: runId,
      schedulePosition: position,
      type: type ?? CompletedPhaseType.work,
      roundNumber: 1,
      durationMs: durationMs,
      completedAtUtcMs: 2000,
      localCompletionDate: '2026-01-01',
      utcOffsetMinutes: 0,
    );

void main() {
  late _FakeAccounts accounts;
  late ActivityDatabase database;
  late ActivityAccess access;
  late SqfliteActivityRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    accounts = _FakeAccounts();
    database = ActivityDatabase(databasePath: inMemoryDatabasePath);
    access = ActivityAccess(database, accounts);
    repository = SqfliteActivityRepository(access);
  });

  tearDown(() async {
    await access.close();
    await database.close();
    await accounts.controller.close();
  });

  Future<int> count(String table) async {
    final db = await database.connection;
    final rows = await db.rawQuery('SELECT COUNT(*) AS total FROM $table');
    return rows.single['total']! as int;
  }

  Future<void> seed(String sessionId, String accountId) async {
    accounts.account = accountId;
    final handle = await access.createSession(_session(sessionId, accountId));
    await access.addPhases(session: handle, phases: [_phase('$sessionId-p', sessionId, 0)]);
  }

  test('deletes sessions and phases of every account', () async {
    expect(await count('timer_sessions'), 0);
    expect(await count('completed_phases'), 0);
    await seed('run-a', 'a');
    await seed('run-b', 'b');
    expect(await count('timer_sessions'), 2);
    expect(await count('completed_phases'), 2);

    final result = await repository.deleteAllActivity();

    expect(result, isA<Success<void>>());
    expect(await count('timer_sessions'), 0);
    expect(await count('completed_phases'), 0);
  });

  test('purges an empty database', () async {
    final result = await repository.deleteAllActivity();

    expect(result, isA<Success<void>>());
  });

  test('emits a change after a purge', () async {
    var emissions = 0;
    final subscription = repository.changes.listen((_) => emissions++);
    addTearDown(subscription.cancel);

    await repository.deleteAllActivity();

    expect(emissions, 1);
  });

  test('returns a failure when the access is closed', () async {
    await seed('run-a', 'a');
    await access.close();

    final result = await repository.deleteAllActivity();

    expect(result, isA<Failure<void>>());
    expect(await count('timer_sessions'), 1);
    expect(await count('completed_phases'), 1);
  });

  test('drops a session prepared before the purge', () async {
    final creation = access.prepareSession(_session('run-a', 'a'));
    await repository.deleteAllActivity();

    final handle = await access.createPreparedSession(creation);
    await access.addPhases(session: handle, phases: [_phase('p', 'run-a', 0)]);
    await access.endSession(session: handle, endedAtUtcMs: 5000);

    expect(await count('timer_sessions'), 0);
    expect(await count('completed_phases'), 0);
  });

  test('drops writes through a handle from before the purge', () async {
    final handle = await access.createSession(_session('run-a', 'a'));
    await repository.deleteAllActivity();
    var emissions = 0;
    final subscription = repository.changes.listen((_) => emissions++);
    addTearDown(subscription.cancel);

    await access.addPhases(session: handle, phases: [_phase('p', 'run-a', 0)]);
    await access.endSession(session: handle, endedAtUtcMs: 5000);

    expect(await count('timer_sessions'), 0);
    expect(await count('completed_phases'), 0);
    expect(emissions, 0);
  });

  test('records new activity after the purge', () async {
    await seed('old', 'a');
    await repository.deleteAllActivity();

    await seed('new', 'a');

    final result = await repository.readDailyActivity();
    expect(result, isA<Success<List<DailyActivity>>>());
    final days = (result as Success<List<DailyActivity>>).value;
    expect(days, hasLength(1));
    expect(days.single.roundCount, 1);
    expect(await count('timer_sessions'), 1);
  });

  Future<int?> endOf(String sessionId) async {
    final db = await database.connection;
    final rows =
        await db.query('timer_sessions', columns: ['ended_at_utc_ms'], where: 'id = ?', whereArgs: [sessionId]);
    return rows.single['ended_at_utc_ms'] as int?;
  }

  group('deleteAccountActivity', () {
    test('deletes only the signed-in account', () async {
      await seed('run-b', 'b');
      final handleB = await access.createSession(_session('run-b2', 'b'));
      await access.saveDraft(session: handleB, phases: [_work('db', 'run-b2', 0, 30000)], checkpointAtUtcMs: 3000);
      await seed('run-a', 'a');
      final handleA = await access.createSession(_session('run-a2', 'a'));
      await access.saveDraft(session: handleA, phases: [_work('da', 'run-a2', 0, 30000)], checkpointAtUtcMs: 3000);

      final result = await repository.deleteAccountActivity();

      expect(result, isA<Success<void>>());
      final db = await database.connection;
      expect(await db.query('timer_sessions', where: 'account_id = ?', whereArgs: ['a']), isEmpty);
      expect(await count('timer_sessions'), 2);
      expect(await count('completed_phases'), 1);
      expect(await db.query('draft_phases'), hasLength(1));
      expect((await db.query('draft_phases')).single['id'], 'db');
    });

    test('deleting an empty account succeeds', () async {
      var emissions = 0;
      final subscription = repository.changes.listen((_) => emissions++);
      addTearDown(subscription.cancel);

      final result = await repository.deleteAccountActivity();

      expect(result, isA<Success<void>>());
      expect(emissions, 1);
    });

    test('delete needs an account and an open access', () async {
      await seed('run-a', 'a');
      accounts.account = null;

      final withoutAccount = await repository.deleteAccountActivity();

      expect(withoutAccount, isA<Failure<void>>());
      expect(await count('timer_sessions'), 1);

      accounts.account = 'a';
      await access.close();
      final closed = await repository.deleteAccountActivity();

      expect(closed, isA<Failure<void>>());
      expect(await count('timer_sessions'), 1);
      expect(await count('completed_phases'), 1);
    });

    test('account change aborts the delete', () async {
      await seed('run-b', 'b');
      await seed('run-a', 'a');

      final pending = repository.deleteAccountActivity();
      accounts.account = 'b';
      accounts.controller.add(null);
      final result = await pending;

      expect(result, isA<Failure<void>>());
      expect(await count('timer_sessions'), 2);
      expect(await count('completed_phases'), 2);
    });

    test('drops the account\'s writes from before the delete', () async {
      final creation = access.prepareSession(_session('run-new', 'a'));
      final handle = await access.createSession(_session('run-old', 'a'));
      await repository.deleteAccountActivity();
      var emissions = 0;
      final subscription = repository.changes.listen((_) => emissions++);
      addTearDown(subscription.cancel);

      final created = await access.createPreparedSession(creation);
      final finished = await repository.finishRun(
        session: handle,
        phases: [_phase('p', 'run-old', 0)],
        endedAtUtcMs: 5000,
      );
      final drafted = await repository.saveDraft(
        session: handle,
        phases: [_work('d', 'run-old', 0, 30000)],
        checkpointAtUtcMs: 3000,
      );

      expect(created, isNotNull);
      expect(finished, isA<Success<void>>());
      expect(drafted, isA<Success<void>>());
      expect(await count('timer_sessions'), 0);
      expect(await count('completed_phases'), 0);
      expect(await count('draft_phases'), 0);
      expect(emissions, 0);
    });

    test('other accounts keep their pending writes', () async {
      accounts.account = 'b';
      final handleB = await access.createSession(_session('run-b', 'b'));
      accounts.account = 'a';
      await repository.deleteAccountActivity();
      accounts.account = 'b';

      final result = await repository.finishRun(
        session: handleB,
        phases: [_phase('p', 'run-b', 0)],
        endedAtUtcMs: 5000,
      );

      expect(result, isA<Success<void>>());
      expect(await count('completed_phases'), 1);
      expect(await endOf('run-b'), 5000);
    });

    test('recovery restores nothing after a delete', () async {
      final handle = await access.createSession(_session('run-a', 'a'));
      await access.saveDraft(session: handle, phases: [_work('d1', 'run-a', 0, 30000)], checkpointAtUtcMs: 9000);

      await repository.deleteAccountActivity();
      final result = await repository.recoverUnfinishedRuns(startedBeforeUtcMs: 5000);

      expect(result, isA<Success<void>>());
      expect(await count('draft_phases'), 0);
      expect(await count('timer_sessions'), 0);
      expect(await count('completed_phases'), 0);
    });

    test('records new activity after a delete', () async {
      await seed('old', 'a');
      await repository.deleteAccountActivity();

      await seed('new', 'a');

      final days = (await repository.readDailyActivity() as Success<List<DailyActivity>>).value;
      expect(days, hasLength(1));
      expect(days.single.roundCount, 1);
      expect(await count('timer_sessions'), 1);
    });

    test('purge and account delete epochs are independent', () async {
      await repository.deleteAccountActivity();
      await repository.deleteAllActivity();

      await seed('new', 'a');

      expect(await count('timer_sessions'), 1);
      expect(await count('completed_phases'), 1);
    });
  });

  group('finishRun', () {
    test('finishRun stores the phases and the end time', () async {
      final handle = await access.createSession(_session('run-a', 'a'));
      var emissions = 0;
      final subscription = repository.changes.listen((_) => emissions++);
      addTearDown(subscription.cancel);

      final result = await repository.finishRun(
        session: handle,
        phases: [
          _work('p1', 'run-a', 0, 30000),
          _work('p2', 'run-a', 1, 10000, type: CompletedPhaseType.rest),
          _work('p3', 'run-a', 2, 150000),
        ],
        endedAtUtcMs: 5000,
      );

      expect(result, isA<Success<void>>());
      expect(await count('completed_phases'), 3);
      expect(await endOf('run-a'), 5000);
      expect(emissions, 1);
    });

    test('finishRun with no phases ends the session and adds no day', () async {
      final handle = await access.createSession(_session('run-a', 'a'));
      var emissions = 0;
      final subscription = repository.changes.listen((_) => emissions++);
      addTearDown(subscription.cancel);

      final result = await repository.finishRun(session: handle, phases: const [], endedAtUtcMs: 5000);

      expect(result, isA<Success<void>>());
      expect(await endOf('run-a'), 5000);
      expect(emissions, 1);
      final days = (await repository.readDailyActivity() as Success<List<DailyActivity>>).value;
      expect(days, isEmpty);
    });

    test('finishRun rolls back on a conflicting phase', () async {
      final handle = await access.createSession(_session('run-a', 'a'));
      await access.addPhases(session: handle, phases: [_work('existing', 'run-a', 1, 30000)]);

      final result = await repository.finishRun(
        session: handle,
        phases: [_work('new', 'run-a', 0, 30000), _work('other', 'run-a', 1, 30000)],
        endedAtUtcMs: 5000,
      );

      expect(result, isA<Failure<void>>());
      expect(await count('completed_phases'), 1);
      expect(await endOf('run-a'), isNull);
    });

    test('finishRun rolls back on a conflicting end', () async {
      final handle = await access.createSession(_session('run-a', 'a'));
      await access.endSession(session: handle, endedAtUtcMs: 5000);

      final result = await repository.finishRun(
        session: handle,
        phases: [_work('p1', 'run-a', 0, 30000)],
        endedAtUtcMs: 6000,
      );

      expect(result, isA<Failure<void>>());
      expect(await count('completed_phases'), 0);
      expect(await endOf('run-a'), 5000);
    });

    test('finishRun twice with the same values stores one copy', () async {
      final handle = await access.createSession(_session('run-a', 'a'));
      final phases = [_work('p1', 'run-a', 0, 30000), _work('p2', 'run-a', 1, 20000)];

      final first = await repository.finishRun(session: handle, phases: phases, endedAtUtcMs: 5000);
      final second = await repository.finishRun(session: handle, phases: phases, endedAtUtcMs: 5000);

      expect(first, isA<Success<void>>());
      expect(second, isA<Success<void>>());
      expect(await count('completed_phases'), 2);
      expect(await endOf('run-a'), 5000);
    });

    test('finishRun with a stale handle writes nothing', () async {
      final handle = await access.createSession(_session('run-a', 'a'));
      await repository.deleteAllActivity();
      var emissions = 0;
      final subscription = repository.changes.listen((_) => emissions++);
      addTearDown(subscription.cancel);

      final withPhases = await repository.finishRun(
        session: handle,
        phases: [_work('p1', 'run-a', 0, 30000)],
        endedAtUtcMs: 5000,
      );
      final empty = await repository.finishRun(session: handle, phases: const [], endedAtUtcMs: 5000);

      expect(withPhases, isA<Success<void>>());
      expect(empty, isA<Success<void>>());
      expect(await count('timer_sessions'), 0);
      expect(await count('completed_phases'), 0);
      expect(emissions, 0);
    });
  });

  group('round rule', () {
    test('round rule counts full phases and partial phases from 5 s', () async {
      final full = await access.createSession(_sessionWithWork('full', 3000));
      final five = await access.createSession(_sessionWithWork('five', 60000));
      final four = await access.createSession(_sessionWithWork('four', 60000));
      await access.addPhases(session: full, phases: [_work('f', 'full', 0, 3000)]);
      await access.addPhases(session: five, phases: [_work('v', 'five', 0, 5000)]);
      await access.addPhases(session: four, phases: [_work('r', 'four', 0, 4000)]);

      final days = (await repository.readDailyActivity() as Success<List<DailyActivity>>).value;
      final summaries = (await repository.readDayActivity('2026-01-01') as Success<List<RunActivitySummary>>).value;

      expect(days.single.roundCount, 2);
      expect(days.single.workDurationMs, 12000);
      expect(summaries.fold<int>(0, (sum, item) => sum + item.activity.roundCount), 2);
      expect(summaries.fold<int>(0, (sum, item) => sum + item.activity.workDurationMs), 12000);
    });

    test('full phases keep their totals under the round rule', () async {
      final handle = await access.createSession(_session('run-a', 'a'));
      await access.addPhases(
        session: handle,
        phases: [
          _work('p1', 'run-a', 0, 30000),
          _work('p2', 'run-a', 1, 10000, type: CompletedPhaseType.rest),
          _work('p3', 'run-a', 2, 30000),
        ],
      );

      final days = (await repository.readDailyActivity() as Success<List<DailyActivity>>).value;
      final summaries = (await repository.readDayActivity('2026-01-01') as Success<List<RunActivitySummary>>).value;

      expect(days.single.roundCount, 2);
      expect(days.single.workDurationMs, 60000);
      expect(days.single.restDurationMs, 10000);
      expect(summaries.single.activity.roundCount, 2);
      expect(summaries.single.activity.workDurationMs, 60000);
      expect(summaries.single.activity.restDurationMs, 10000);
    });
  });

  Future<List<String>> draftIds(String sessionId) async {
    final db = await database.connection;
    final rows = await db.query(
      'draft_phases',
      columns: ['id'],
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'id',
    );
    return rows.map((row) => row['id']! as String).toList();
  }

  Future<int?> checkpointOf(String sessionId) async {
    final db = await database.connection;
    final rows = await db.query(
      'timer_sessions',
      columns: ['checkpoint_at_utc_ms'],
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    return rows.single['checkpoint_at_utc_ms'] as int?;
  }

  group('saveDraft', () {
    test('saveDraft replaces the draft and statistics ignore it', () async {
      final handle = await access.createSession(_session('run-a', 'a'));
      var emissions = 0;
      final subscription = repository.changes.listen((_) => emissions++);
      addTearDown(subscription.cancel);

      final first = await repository.saveDraft(
        session: handle,
        phases: [_work('d1', 'run-a', 0, 30000), _work('d2', 'run-a', 1, 10000)],
        checkpointAtUtcMs: 3000,
      );
      final second = await repository.saveDraft(
        session: handle,
        phases: [_work('d3', 'run-a', 0, 30000)],
        checkpointAtUtcMs: 4000,
      );

      expect(first, isA<Success<void>>());
      expect(second, isA<Success<void>>());
      expect(await draftIds('run-a'), ['d3']);
      expect(await checkpointOf('run-a'), 4000);
      expect(emissions, 0);
      final days = (await repository.readDailyActivity() as Success<List<DailyActivity>>).value;
      expect(days, isEmpty);
    });

    test('saveDraft writes nothing for an ended session or a stale handle', () async {
      final ended = await access.createSession(_session('run-a', 'a'));
      await access.endSession(session: ended, endedAtUtcMs: 5000);
      final endedResult = await repository.saveDraft(
        session: ended,
        phases: [_work('d1', 'run-a', 0, 30000)],
        checkpointAtUtcMs: 3000,
      );

      expect(endedResult, isA<Success<void>>());
      expect(await count('draft_phases'), 0);
      expect(await checkpointOf('run-a'), isNull);

      final stale = await access.createSession(_session('run-b', 'a'));
      await repository.deleteAllActivity();
      final staleResult = await repository.saveDraft(
        session: stale,
        phases: [_work('d2', 'run-b', 0, 30000)],
        checkpointAtUtcMs: 3000,
      );

      expect(staleResult, isA<Success<void>>());
      expect(await count('draft_phases'), 0);
      expect(await count('timer_sessions'), 0);
    });

    test('saveDraft rejects a phase from another session', () async {
      final handle = await access.createSession(_session('run-a', 'a'));

      final result = await repository.saveDraft(
        session: handle,
        phases: [_work('d1', 'run-other', 0, 30000)],
        checkpointAtUtcMs: 3000,
      );

      expect(result, isA<Failure<void>>());
      expect(await count('draft_phases'), 0);
      expect(await checkpointOf('run-a'), isNull);
    });

    test('saveDraft fails when the session is missing', () async {
      final handle = await access.createSession(_session('run-a', 'a'));
      final db = await database.connection;
      await db.delete('timer_sessions');

      final result = await repository.saveDraft(
        session: handle,
        phases: [_work('d1', 'run-a', 0, 30000)],
        checkpointAtUtcMs: 3000,
      );

      expect(result, isA<Failure<void>>());
      expect(await count('draft_phases'), 0);
    });

    test('finishRun removes the draft', () async {
      final handle = await access.createSession(_session('run-a', 'a'));
      await access.saveDraft(
        session: handle,
        phases: [_work('p1', 'run-a', 0, 30000)],
        checkpointAtUtcMs: 3000,
      );
      expect(await count('draft_phases'), 1);

      final result = await repository.finishRun(
        session: handle,
        phases: [_work('p1', 'run-a', 0, 30000), _work('p2', 'run-a', 1, 10000)],
        endedAtUtcMs: 5000,
      );

      expect(result, isA<Success<void>>());
      expect(await count('draft_phases'), 0);
      expect(await count('completed_phases'), 2);
      expect(await endOf('run-a'), 5000);
    });
  });

  group('recoverUnfinishedRuns', () {
    CompletedPhase dated(String id, int position, String date, int offset) => CompletedPhase(
          id: id,
          runId: 'run-a',
          schedulePosition: position,
          type: CompletedPhaseType.work,
          roundNumber: 1,
          durationMs: 30000,
          completedAtUtcMs: 2000,
          localCompletionDate: date,
          utcOffsetMinutes: offset,
        );

    test('recovery turns a draft into completed phases', () async {
      final handle = await access.createSession(_session('run-a', 'a'));
      final phases = [dated('d1', 0, '2026-01-01', 0), dated('d2', 1, '2026-01-02', 60)];
      await access.saveDraft(session: handle, phases: phases, checkpointAtUtcMs: 9000);
      var emissions = 0;
      final subscription = repository.changes.listen((_) => emissions++);
      addTearDown(subscription.cancel);

      final result = await repository.recoverUnfinishedRuns(startedBeforeUtcMs: 5000);

      expect(result, isA<Success<void>>());
      expect(await access.readPhases('run-a'), unorderedEquals(phases));
      expect(await endOf('run-a'), 9000);
      expect(await count('draft_phases'), 0);
      expect(emissions, 1);
    });

    test('recovery runs only once per draft', () async {
      final handle = await access.createSession(_session('run-a', 'a'));
      await access.saveDraft(
        session: handle,
        phases: [_work('d1', 'run-a', 0, 30000)],
        checkpointAtUtcMs: 9000,
      );
      await repository.recoverUnfinishedRuns(startedBeforeUtcMs: 5000);
      var emissions = 0;
      final subscription = repository.changes.listen((_) => emissions++);
      addTearDown(subscription.cancel);

      final result = await repository.recoverUnfinishedRuns(startedBeforeUtcMs: 5000);

      expect(result, isA<Success<void>>());
      expect(await count('completed_phases'), 1);
      expect(await endOf('run-a'), 9000);
      expect(emissions, 0);
    });

    test('recovery keeps the account that started the run', () async {
      accounts.account = 'b';
      final handleB = await access.createSession(_session('run-b', 'b'));
      await access.saveDraft(
        session: handleB,
        phases: [_work('d1', 'run-b', 0, 30000)],
        checkpointAtUtcMs: 9000,
      );
      accounts.account = 'a';

      final withOtherAccount = await repository.recoverUnfinishedRuns(startedBeforeUtcMs: 5000);
      final daysOfA = (await repository.readDailyActivity() as Success<List<DailyActivity>>).value;

      expect(withOtherAccount, isA<Success<void>>());
      expect(daysOfA, isEmpty);
      expect(await endOf('run-b'), 9000);

      accounts.account = 'b';
      final handleC = await access.createSession(_session('run-c', 'b'));
      await access.saveDraft(
        session: handleC,
        phases: [_work('d2', 'run-c', 0, 30000)],
        checkpointAtUtcMs: 9000,
      );
      accounts.account = null;

      final withNoAccount = await repository.recoverUnfinishedRuns(startedBeforeUtcMs: 5000);

      expect(withNoAccount, isA<Success<void>>());
      expect(await endOf('run-c'), 9000);
      accounts.account = 'a';
      final stillEmpty = (await repository.readDailyActivity() as Success<List<DailyActivity>>).value;
      expect(stillEmpty, isEmpty);
      accounts.account = 'b';
      final daysOfB = (await repository.readDailyActivity() as Success<List<DailyActivity>>).value;
      expect(daysOfB, hasLength(1));
    });

    test('deleted sessions lose their drafts and stay deleted', () async {
      final handle = await access.createSession(_session('run-a', 'a'));
      await access.saveDraft(
        session: handle,
        phases: [_work('d1', 'run-a', 0, 30000)],
        checkpointAtUtcMs: 9000,
      );
      expect(await count('draft_phases'), 1);

      await repository.deleteAllActivity();
      final result = await repository.recoverUnfinishedRuns(startedBeforeUtcMs: 5000);

      expect(result, isA<Success<void>>());
      expect(await count('draft_phases'), 0);
      expect(await count('timer_sessions'), 0);
      expect(await count('completed_phases'), 0);
    });

    test('recovery skips sessions started after it began', () async {
      final handle = await access.createSession(_session('run-a', 'a'));
      await access.saveDraft(
        session: handle,
        phases: [_work('d1', 'run-a', 0, 30000)],
        checkpointAtUtcMs: 9000,
      );
      var emissions = 0;
      final subscription = repository.changes.listen((_) => emissions++);
      addTearDown(subscription.cancel);

      final result = await repository.recoverUnfinishedRuns(startedBeforeUtcMs: 1000);

      expect(result, isA<Success<void>>());
      expect(await endOf('run-a'), isNull);
      expect(await draftIds('run-a'), ['d1']);
      expect(await count('completed_phases'), 0);
      expect(emissions, 0);
    });

    test('recovery keeps going after one session fails', () async {
      final bad = await access.createSession(_session('run-a', 'a'));
      final good = await access.createSession(_session('run-b', 'a'));
      await access.addPhases(session: bad, phases: [_work('existing', 'run-a', 0, 99000)]);
      await access.saveDraft(
        session: bad,
        phases: [_work('d1', 'run-a', 0, 30000)],
        checkpointAtUtcMs: 9000,
      );
      await access.saveDraft(
        session: good,
        phases: [_work('d2', 'run-b', 0, 30000)],
        checkpointAtUtcMs: 9000,
      );

      final result = await repository.recoverUnfinishedRuns(startedBeforeUtcMs: 5000);

      expect(result, isA<Failure<void>>());
      expect(await endOf('run-b'), 9000);
      expect(await draftIds('run-b'), isEmpty);
      expect(await endOf('run-a'), isNull);
      expect(await draftIds('run-a'), ['d1']);
      expect(await count('completed_phases'), 2);
    });

    test('recovery fails when the access is closed', () async {
      await access.close();

      final result = await repository.recoverUnfinishedRuns(startedBeforeUtcMs: 5000);

      expect(result, isA<Failure<void>>());
    });
  });

  test('upgrades a version 2 database to version 3', () async {
    final directory = await Directory.systemTemp.createTemp('activity_upgrade');
    addTearDown(() => directory.delete(recursive: true));
    final databasePath = '${directory.path}/activity.db';
    final old = await databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE timer_sessions (
              id TEXT PRIMARY KEY NOT NULL,
              account_id TEXT NOT NULL CHECK (length(account_id) > 0),
              started_at_utc_ms INTEGER NOT NULL,
              preparation_duration_ms INTEGER NOT NULL CHECK (preparation_duration_ms >= 0),
              work_duration_ms INTEGER NOT NULL CHECK (work_duration_ms >= 0),
              rest_duration_ms INTEGER NOT NULL CHECK (rest_duration_ms >= 0),
              round_count INTEGER NOT NULL CHECK (round_count > 0),
              ended_at_utc_ms INTEGER
            )
          ''');
          await db.execute('CREATE INDEX timer_sessions_account_id ON timer_sessions(account_id)');
          await db.execute('''
            CREATE TABLE completed_phases (
              id TEXT PRIMARY KEY NOT NULL,
              session_id TEXT NOT NULL REFERENCES timer_sessions(id) ON DELETE RESTRICT,
              schedule_position INTEGER NOT NULL CHECK (schedule_position >= 0),
              type TEXT NOT NULL CHECK (type IN ('work', 'rest')),
              round_number INTEGER NOT NULL CHECK (round_number > 0),
              duration_ms INTEGER NOT NULL CHECK (duration_ms > 0),
              completed_at_utc_ms INTEGER NOT NULL,
              local_completion_date TEXT NOT NULL,
              utc_offset_minutes INTEGER NOT NULL,
              UNIQUE (session_id, schedule_position)
            )
          ''');
          await db.execute(
            'CREATE INDEX completed_phases_session_date ON completed_phases(session_id, local_completion_date)',
          );
        },
      ),
    );
    await old.insert('timer_sessions', {
      'id': 'run-a',
      'account_id': 'a',
      'started_at_utc_ms': 1000,
      'preparation_duration_ms': 0,
      'work_duration_ms': 30000,
      'rest_duration_ms': 10000,
      'round_count': 2,
      'ended_at_utc_ms': 5000,
    });
    await old.insert('completed_phases', {
      'id': 'p1',
      'session_id': 'run-a',
      'schedule_position': 0,
      'type': 'work',
      'round_number': 1,
      'duration_ms': 30000,
      'completed_at_utc_ms': 2000,
      'local_completion_date': '2026-01-01',
      'utc_offset_minutes': 0,
    });
    await old.close();

    final upgraded = ActivityDatabase(databasePath: databasePath);
    addTearDown(upgraded.close);
    final db = await upgraded.connection;

    expect(await db.getVersion(), 3);
    expect(await db.query('timer_sessions'), hasLength(1));
    expect(await db.query('completed_phases'), hasLength(1));
    expect(await db.query('draft_phases'), isEmpty);
    final columns = await db.rawQuery('PRAGMA table_info(timer_sessions)');
    expect(columns.map((column) => column['name']), contains('checkpoint_at_utc_ms'));
    final session = (await db.query('timer_sessions')).single;
    expect(session['checkpoint_at_utc_ms'], isNull);
  });
}
