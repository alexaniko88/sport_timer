import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
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

class FakeAccounts implements ActivityAccountSource {
  final controller = StreamController<void>.broadcast(sync: true);
  String? account = 'a';

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
  String get sessionId => 'run';
}

class FakeCreation implements ActivitySessionCreation {}

class DelayedAccess extends ActivityAccess {
  final sessions = Completer<List<TimerSession>>();
  final phases = Completer<List<CompletedPhase>>();
  final days = Completer<List<DailyActivity>>();
  final dayRuns = Completer<List<DayRunActivity>>();
  final session = Completer<ActivitySessionHandle>();

  DelayedAccess(ActivityAccountSource accounts) : super(ActivityDatabase(), accounts);

  @override
  Future<List<TimerSession>> readSessions() => sessions.future;

  @override
  Future<List<CompletedPhase>> readPhases(String sessionId) => phases.future;

  @override
  Future<List<DailyActivity>> readDailyActivity() => days.future;

  @override
  Future<List<DayRunActivity>> readDayActivity(String localDate) => dayRuns.future;

  @override
  Future<ActivitySessionHandle> openSession(String sessionId) => session.future;
}

void main() {
  const session = TimerSession(
    id: 'run',
    accountId: 'a',
    startedAtUtcMs: 1000,
    preparationDurationMs: 0,
    workDurationMs: 30000,
    restDurationMs: 10000,
    roundCount: 2,
  );
  late FakeAccounts accounts;
  late DelayedAccess access;
  late SqfliteActivityRepository repository;

  setUp(() {
    accounts = FakeAccounts();
    access = DelayedAccess(accounts);
    repository = SqfliteActivityRepository(access);
  });

  tearDown(() async {
    await access.close();
    await accounts.controller.close();
  });

  test('discards sessions if the account changes after access completes', () async {
    final pending = repository.readSessions();
    access.sessions.complete([]);
    accounts.change('b');
    expect(await pending, isA<Failure<List<TimerSession>>>());
  });

  test('discards phases after an account changes away and back', () async {
    final pending = repository.readPhases('run');
    access.phases.complete([]);
    accounts.change('b');
    accounts.change('a');
    expect(await pending, isA<Failure<List<CompletedPhase>>>());
  });

  test('discards daily totals if the account changes after access completes', () async {
    final pending = repository.readDailyActivity();
    access.days.complete([]);
    accounts.change(null);
    expect(await pending, isA<Failure<List<DailyActivity>>>());
  });

  test('discards day runs if the account changes after access completes', () async {
    final pending = repository.readDayActivity('2026-11-02');
    access.dayRuns.complete([]);
    accounts.change('b');
    accounts.change('a');
    expect(await pending, isA<Failure<List<DayRunActivity>>>());
  });

  test('returns a failure when the day query fails', () async {
    final pending = repository.readDayActivity('2026-11-02');
    access.dayRuns.completeError(StateError('query failed'));
    expect(await pending, isA<Failure<List<DayRunActivity>>>());
  });

  test('discards a session handle if the account changes after access completes', () async {
    final pending = repository.openSession('run');
    access.session.complete(FakeHandle());
    accounts.change('b');
    expect(await pending, isA<Failure<ActivitySessionHandle>>());
  });

  test('preparing a session requires its signed-in owner', () {
    expect(repository.prepareSession(session), isA<Success<ActivitySessionCreation>>());
    accounts.change('b');
    expect(repository.prepareSession(session), isA<Failure<ActivitySessionCreation>>());
    accounts.change(null);
    expect(repository.prepareSession(session), isA<Failure<ActivitySessionCreation>>());
  });

  test('rejects forged and foreign session creation capabilities', () async {
    final creation = (repository.prepareSession(session) as Success<ActivitySessionCreation>).value;
    final other = DelayedAccess(accounts);
    addTearDown(other.close);
    expect(await repository.createPreparedSession(FakeCreation()), isA<Failure<ActivitySessionHandle>>());
    expect(
      await SqfliteActivityRepository(other).createPreparedSession(creation),
      isA<Failure<ActivitySessionHandle>>(),
    );
  });
}
