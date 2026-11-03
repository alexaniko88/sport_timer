import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/settings/domain/timer_style.dart';
import 'package:sport_timer/features/statistics/domain/activity_account_source.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';
import 'package:sport_timer/features/statistics/domain/activity_session_creation.dart';
import 'package:sport_timer/features/statistics/domain/activity_session_handle.dart';
import 'package:sport_timer/features/statistics/domain/completed_phase.dart';
import 'package:sport_timer/features/statistics/domain/timer_session.dart';
import 'package:sport_timer/features/timer/data/default_timer_activity_recorder.dart';
import 'package:sport_timer/features/timer/domain/timer_activity_recorder.dart';
import 'package:sport_timer/features/timer/domain/timer_params.dart';

class _Accounts implements ActivityAccountSource {
  String? account = 'owner';

  @override
  String? get currentAccountId => account;

  @override
  Stream<void> get changes => const Stream.empty();
}

class _Creation implements ActivitySessionCreation {}

class _Handle implements ActivitySessionHandle {
  @override
  final String sessionId;

  _Handle(this.sessionId);
}

class _Repository implements ActivityRepository {
  TimerSession? prepared;
  final creation = _Creation();
  final batches = <List<CompletedPhase>>[];
  final ends = <int>[];
  int createAttempts = 0;
  int phaseAttempts = 0;
  bool failCreate = false;
  bool failPhases = false;
  Completer<void>? createGate;

  @override
  Result<ActivitySessionCreation> prepareSession(TimerSession session) {
    prepared = session;
    return Success(creation);
  }

  @override
  Future<Result<ActivitySessionHandle>> createPreparedSession(ActivitySessionCreation value) async {
    expect(value, same(creation));
    createAttempts++;
    await createGate?.future;
    if (failCreate) return Failure(Exception('create failed'));
    return Success(_Handle(prepared?.id ?? 'missing'));
  }

  @override
  Future<Result<void>> recordPhases({
    required ActivitySessionHandle session,
    required List<CompletedPhase> phases,
  }) async {
    phaseAttempts++;
    batches.add(List.of(phases));
    if (failPhases) return Failure(Exception('write failed'));
    return const Success(null);
  }

  @override
  Future<Result<void>> endSession({required ActivitySessionHandle session, required int endedAtUtcMs}) async {
    ends.add(endedAtUtcMs);
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Accounts accounts;
  late _Repository repository;
  late DateTime now;
  late DefaultTimerActivityRecorder recorder;
  var nextId = 0;

  const params = TimerParams(
    preparationTime: Duration(seconds: 2),
    roundTime: Duration(seconds: 10),
    restTime: Duration(seconds: 5),
    rounds: 2,
    style: TimerStyle.ring,
  );

  setUp(() {
    accounts = _Accounts();
    repository = _Repository();
    now = DateTime.utc(2026, 11, 1, 23, 59, 50);
    nextId = 0;
    recorder = DefaultTimerActivityRecorder(
      repository,
      accounts,
      clock: () => now,
      newId: () => 'id-${nextId++}',
    );
  });

  test('reconciles every crossed boundary once and stores its logical instant', () async {
    final run = (recorder.start(params) as Success<TimerActivityRun>).value;
    now = now.add(const Duration(minutes: 2));
    run.reconcile(const Duration(seconds: 27));
    run.reconcile(const Duration(seconds: 27));
    run.end(const Duration(seconds: 30));
    await Future<void>.delayed(Duration.zero);

    final phases = repository.batches.single;
    expect(phases.map((phase) => phase.schedulePosition), [1, 2, 3]);
    expect(
      phases.map((phase) => phase.type),
      [CompletedPhaseType.work, CompletedPhaseType.rest, CompletedPhaseType.work],
    );
    expect(phases.map((phase) => phase.completedAtUtcMs), [
      DateTime.utc(2026, 11, 2, 0, 0, 2).millisecondsSinceEpoch,
      DateTime.utc(2026, 11, 2, 0, 0, 7).millisecondsSinceEpoch,
      DateTime.utc(2026, 11, 2, 0, 0, 17).millisecondsSinceEpoch,
    ]);
    final local = DateTime.utc(2026, 11, 2, 0, 0, 2).toLocal();
    expect(phases.first.utcOffsetMinutes, local.timeZoneOffset.inMinutes);
    expect(
      phases.first.localCompletionDate,
      '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}',
    );
    expect(repository.ends.single, DateTime.utc(2026, 11, 2, 0, 0, 17).millisecondsSinceEpoch);
  });

  test('pause excludes paused time and stop excludes incomplete work', () async {
    final run = (recorder.start(params) as Success<TimerActivityRun>).value;
    now = now.add(const Duration(milliseconds: 7500));
    run.pause(const Duration(milliseconds: 7500));
    now = now.add(const Duration(minutes: 2));
    run.resume();
    now = now.add(const Duration(seconds: 6));
    run.end(const Duration(milliseconds: 13500));
    await Future<void>.delayed(Duration.zero);

    final phase = repository.batches.single.single;
    expect(phase.completedAtUtcMs, DateTime.utc(2026, 11, 2, 0, 2, 2).millisecondsSinceEpoch);
    expect(phase.durationMs, 10000);
    expect(repository.ends.single, DateTime.utc(2026, 11, 2, 0, 2, 3, 500).millisecondsSinceEpoch);
  });

  test('retries a failed batch with identical phase data and keeps the original owner', () async {
    repository.failCreate = true;
    final failures = <Exception>[];
    final subscription = recorder.failures.listen(failures.add);
    final run = (recorder.start(params) as Success<TimerActivityRun>).value;
    run.end(const Duration(seconds: 12));
    await Future<void>.delayed(Duration.zero);
    expect(repository.createAttempts, 1);
    expect(repository.batches, isEmpty);
    accounts.account = 'other';
    repository.failCreate = false;
    repository.failPhases = true;
    recorder.retryPendingWrites();
    await Future<void>.delayed(Duration.zero);
    expect(repository.prepared?.accountId, 'owner');
    expect(repository.batches, hasLength(1));
    expect(repository.ends, isEmpty);
    repository.failPhases = false;
    recorder.retryPendingWrites();
    await Future<void>.delayed(Duration.zero);
    expect(repository.createAttempts, 2);
    expect(repository.batches, hasLength(2));
    expect(repository.batches.first, repository.batches.last);
    expect(repository.ends, hasLength(1));
    expect(failures, hasLength(2));
    await subscription.cancel();
  });

  test('does not start recording without an account', () {
    accounts.account = null;
    expect(recorder.start(params), isA<Failure<TimerActivityRun>>());
    expect(repository.prepared, isNull);
  });

  test('finishes queued writes after the caller ends a run while creation is pending', () async {
    repository.createGate = Completer<void>();
    final run = (recorder.start(params) as Success<TimerActivityRun>).value;
    run.end(const Duration(seconds: 12));
    await Future<void>.delayed(Duration.zero);
    expect(repository.batches, isEmpty);
    repository.createGate?.complete();
    await Future<void>.delayed(Duration.zero);
    expect(repository.batches.single.single.schedulePosition, 1);
    expect(repository.ends, hasLength(1));
  });

  test('omits zero-duration stages and preparation from activity', () async {
    const omitted = TimerParams(
      preparationTime: Duration(seconds: 2),
      roundTime: Duration(seconds: 10),
      restTime: Duration.zero,
      rounds: 2,
      style: TimerStyle.ring,
    );
    final run = (recorder.start(omitted) as Success<TimerActivityRun>).value;
    run.end(const Duration(seconds: 22));
    await Future<void>.delayed(Duration.zero);
    expect(repository.batches.single.map((phase) => phase.schedulePosition), [1, 2]);
    expect(repository.batches.single.map((phase) => phase.type), [CompletedPhaseType.work, CompletedPhaseType.work]);
  });

  test('applies a forward clock correction after observed boundaries across midnight', () async {
    now = DateTime(2026, 11, 1, 23, 59, 50).toUtc();
    final start = now;
    final run = (recorder.start(params) as Success<TimerActivityRun>).value;
    now = start.add(const Duration(hours: 2, seconds: 17));
    run.reconcile(const Duration(seconds: 17));
    now = now.add(const Duration(seconds: 10));
    run.end(const Duration(seconds: 27));
    await Future<void>.delayed(Duration.zero);

    final phases = repository.batches.expand((batch) => batch).toList();
    expect(phases.map((phase) => phase.schedulePosition), [1, 2, 3]);
    expect(phases[0].completedAtUtcMs, start.add(const Duration(seconds: 12)).millisecondsSinceEpoch);
    expect(phases[1].completedAtUtcMs, start.add(const Duration(seconds: 17)).millisecondsSinceEpoch);
    expect(phases[2].completedAtUtcMs, start.add(const Duration(hours: 2, seconds: 27)).millisecondsSinceEpoch);
    expect(phases.first.localCompletionDate, '2026-11-02');
    expect(phases.last.localCompletionDate, '2026-11-02');
  });

  test('uses a backward correction for future boundaries across midnight and a pause', () async {
    now = DateTime(2026, 11, 1, 23, 59, 50).toUtc();
    final start = now;
    final run = (recorder.start(params) as Success<TimerActivityRun>).value;
    now = start.subtract(const Duration(hours: 2)).add(const Duration(seconds: 13));
    run.pause(const Duration(seconds: 13));
    now = now.add(const Duration(minutes: 1));
    run.resume();
    now = now.add(const Duration(seconds: 14));
    run.end(const Duration(seconds: 27));
    await Future<void>.delayed(Duration.zero);

    final phases = repository.batches.expand((batch) => batch).toList();
    expect(phases.map((phase) => phase.schedulePosition), [1, 2, 3]);
    expect(phases.map((phase) => phase.completedAtUtcMs), [
      start.add(const Duration(seconds: 12)).millisecondsSinceEpoch,
      start.subtract(const Duration(hours: 2)).add(const Duration(seconds: 77)).millisecondsSinceEpoch,
      start.subtract(const Duration(hours: 2)).add(const Duration(seconds: 87)).millisecondsSinceEpoch,
    ]);
    expect(phases.map((phase) => phase.localCompletionDate), ['2026-11-02', '2026-11-01', '2026-11-01']);
    expect(repository.ends.single, phases.last.completedAtUtcMs);
  });

  test('keeps delayed boundaries immutable when a backward correction is first observed', () async {
    now = DateTime(2026, 11, 1, 23, 59, 50).toUtc();
    final start = now;
    final run = (recorder.start(params) as Success<TimerActivityRun>).value;
    now = start.subtract(const Duration(hours: 2)).add(const Duration(seconds: 17));
    run.reconcile(const Duration(seconds: 17));
    now = now.add(const Duration(seconds: 10));
    run.end(const Duration(seconds: 27));
    await Future<void>.delayed(Duration.zero);

    final phases = repository.batches.expand((batch) => batch).toList();
    expect(phases.map((phase) => phase.schedulePosition), [1, 2, 3]);
    expect(phases.map((phase) => phase.completedAtUtcMs), [
      start.add(const Duration(seconds: 12)).millisecondsSinceEpoch,
      start.add(const Duration(seconds: 17)).millisecondsSinceEpoch,
      start.subtract(const Duration(hours: 2)).add(const Duration(seconds: 27)).millisecondsSinceEpoch,
    ]);
    expect(phases.map((phase) => phase.localCompletionDate), ['2026-11-02', '2026-11-02', '2026-11-01']);
  });
}
