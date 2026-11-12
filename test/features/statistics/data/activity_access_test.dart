import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/statistics/data/activity_access.dart';
import 'package:sport_timer/features/statistics/data/activity_database.dart';
import 'package:sport_timer/features/statistics/data/sqflite_activity_repository.dart';
import 'package:sport_timer/features/statistics/domain/activity_account_source.dart';
import 'package:sport_timer/features/statistics/domain/completed_phase.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
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
}
