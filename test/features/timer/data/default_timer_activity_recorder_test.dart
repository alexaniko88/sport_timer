import 'dart:async';

import 'package:fake_async/fake_async.dart';
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

class _Finish {
  final ActivitySessionHandle session;
  final List<CompletedPhase> phases;
  final int endedAtUtcMs;

  _Finish(this.session, this.phases, this.endedAtUtcMs);
}

class _Draft {
  final ActivitySessionHandle session;
  final List<CompletedPhase> phases;
  final int checkpointAtUtcMs;

  _Draft(this.session, this.phases, this.checkpointAtUtcMs);
}

class _Repository implements ActivityRepository {
  TimerSession? prepared;
  final creation = _Creation();
  final finishes = <_Finish>[];
  final drafts = <_Draft>[];
  final events = <String>[];
  int createAttempts = 0;
  bool failCreate = false;
  bool failFinish = false;
  bool failDraft = false;
  Completer<void>? createGate;
  Completer<void>? draftGate;

  @override
  Future<Result<void>> deleteAllActivity() async => const Success(null);

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
    events.add('create');
    return Success(_Handle(prepared?.id ?? 'missing'));
  }

  @override
  Future<Result<void>> finishRun({
    required ActivitySessionHandle session,
    required List<CompletedPhase> phases,
    required int endedAtUtcMs,
  }) async {
    finishes.add(_Finish(session, List.of(phases), endedAtUtcMs));
    events.add('finish');
    if (failFinish) return Failure(Exception('write failed'));
    return const Success(null);
  }

  @override
  Future<Result<void>> saveDraft({
    required ActivitySessionHandle session,
    required List<CompletedPhase> phases,
    required int checkpointAtUtcMs,
  }) async {
    drafts.add(_Draft(session, List.of(phases), checkpointAtUtcMs));
    events.add('draft');
    await draftGate?.future;
    if (failDraft) return Failure(Exception('draft failed'));
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

  TimerActivityRun startRun() => (recorder.start(params) as Success<TimerActivityRun>).value;

  test('reconciles every crossed boundary once and stores its logical instant', () async {
    final run = (recorder.start(params) as Success<TimerActivityRun>).value;
    now = now.add(const Duration(minutes: 2));
    run.reconcile(const Duration(seconds: 27));
    run.reconcile(const Duration(seconds: 27));
    run.end(const Duration(seconds: 30));
    await Future<void>.delayed(Duration.zero);

    final phases = repository.finishes.single.phases;
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
    expect(repository.finishes.single.endedAtUtcMs, DateTime.utc(2026, 11, 2, 0, 0, 17).millisecondsSinceEpoch);
  });

  test('pause excludes paused time and leaving saves the partial rest in whole seconds', () async {
    final run = (recorder.start(params) as Success<TimerActivityRun>).value;
    now = now.add(const Duration(milliseconds: 7500));
    run.pause(const Duration(milliseconds: 7500));
    now = now.add(const Duration(minutes: 2));
    run.resume();
    now = now.add(const Duration(seconds: 6));
    run.end(const Duration(milliseconds: 13500));
    await Future<void>.delayed(Duration.zero);

    final finish = repository.finishes.single;
    final work = finish.phases.first;
    expect(work.completedAtUtcMs, DateTime.utc(2026, 11, 2, 0, 2, 2).millisecondsSinceEpoch);
    expect(work.durationMs, 10000);
    expect(finish.phases.last.type, CompletedPhaseType.rest);
    expect(finish.phases.last.durationMs, 1000);
    expect(finish.endedAtUtcMs, DateTime.utc(2026, 11, 2, 0, 2, 3, 500).millisecondsSinceEpoch);
  });

  test('retries a failed finishRun with identical values and keeps the original owner', () async {
    repository.failCreate = true;
    final failures = <Exception>[];
    final subscription = recorder.failures.listen(failures.add);
    final run = (recorder.start(params) as Success<TimerActivityRun>).value;
    run.end(const Duration(seconds: 12));
    await Future<void>.delayed(Duration.zero);
    expect(repository.createAttempts, 1);
    expect(repository.finishes, isEmpty);
    accounts.account = 'other';
    repository.failCreate = false;
    repository.failFinish = true;
    recorder.retryPendingWrites();
    await Future<void>.delayed(Duration.zero);
    expect(repository.prepared?.accountId, 'owner');
    expect(repository.finishes, hasLength(1));
    repository.failFinish = false;
    recorder.retryPendingWrites();
    await Future<void>.delayed(Duration.zero);
    expect(repository.createAttempts, 2);
    expect(repository.finishes, hasLength(2));
    final first = repository.finishes.first;
    final last = repository.finishes.last;
    expect(last.phases, first.phases);
    expect(last.endedAtUtcMs, first.endedAtUtcMs);
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
    expect(repository.finishes, isEmpty);
    repository.createGate?.complete();
    await Future<void>.delayed(Duration.zero);
    expect(repository.finishes.single.phases.single.schedulePosition, 1);
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
    final phases = repository.finishes.single.phases;
    expect(phases.map((phase) => phase.schedulePosition), [1, 2]);
    expect(phases.map((phase) => phase.type), [CompletedPhaseType.work, CompletedPhaseType.work]);
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

    final phases = repository.finishes.single.phases;
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

    final phases = repository.finishes.single.phases;
    expect(phases.map((phase) => phase.schedulePosition), [1, 2, 3]);
    expect(phases.map((phase) => phase.completedAtUtcMs), [
      start.add(const Duration(seconds: 12)).millisecondsSinceEpoch,
      start.subtract(const Duration(hours: 2)).add(const Duration(seconds: 77)).millisecondsSinceEpoch,
      start.subtract(const Duration(hours: 2)).add(const Duration(seconds: 87)).millisecondsSinceEpoch,
    ]);
    expect(phases.map((phase) => phase.localCompletionDate), ['2026-11-02', '2026-11-01', '2026-11-01']);
    expect(repository.finishes.single.endedAtUtcMs, phases.last.completedAtUtcMs);
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

    final phases = repository.finishes.single.phases;
    expect(phases.map((phase) => phase.schedulePosition), [1, 2, 3]);
    expect(phases.map((phase) => phase.completedAtUtcMs), [
      start.add(const Duration(seconds: 12)).millisecondsSinceEpoch,
      start.add(const Duration(seconds: 17)).millisecondsSinceEpoch,
      start.subtract(const Duration(hours: 2)).add(const Duration(seconds: 27)).millisecondsSinceEpoch,
    ]);
    expect(phases.map((phase) => phase.localCompletionDate), ['2026-11-02', '2026-11-02', '2026-11-01']);
  });

  test('attributes a delayed callback to the day the phase finished', () async {
    now = DateTime(2026, 11, 1, 23, 59, 40).toUtc();
    final start = now;
    final run = (recorder.start(params) as Success<TimerActivityRun>).value;
    now = DateTime(2026, 11, 2, 0, 0, 10).toUtc();
    run.end(const Duration(seconds: 30));
    await Future<void>.delayed(Duration.zero);

    final phases = repository.finishes.single.phases;
    expect(phases.map((phase) => phase.localCompletionDate), ['2026-11-01', '2026-11-01', '2026-11-02']);
    expect(phases.first.completedAtUtcMs, start.add(const Duration(seconds: 12)).millisecondsSinceEpoch);
  });

  test('attributes a phase after a pause spanning midnight to its completion day', () async {
    now = DateTime(2026, 11, 1, 23, 59, 50).toUtc();
    final run = (recorder.start(params) as Success<TimerActivityRun>).value;
    now = now.add(const Duration(seconds: 7));
    run.pause(const Duration(seconds: 7));
    now = now.add(const Duration(seconds: 20));
    run.resume();
    now = now.add(const Duration(seconds: 5));
    run.end(const Duration(seconds: 12));
    await Future<void>.delayed(Duration.zero);

    final phase = repository.finishes.single.phases.single;
    expect(phase.localCompletionDate, '2026-11-02');
    expect(phase.completedAtUtcMs, now.millisecondsSinceEpoch);
    expect(phase.durationMs, 10000);
  });

  for (final elapsed in [11999, 12000, 12001]) {
    test('ending at ${elapsed}ms saves the finished and partial phases in whole seconds', () async {
      final run = (recorder.start(params) as Success<TimerActivityRun>).value;
      now = now.add(Duration(milliseconds: elapsed));
      run.end(Duration(milliseconds: elapsed));
      await Future<void>.delayed(Duration.zero);

      final phases = repository.finishes.single.phases;
      expect(phases.map((phase) => phase.durationMs), [elapsed < 12000 ? 9000 : 10000]);
    });
  }

  test('leaving mid-round finishes the run with the partial work', () async {
    const long = TimerParams(
      preparationTime: Duration(seconds: 5),
      roundTime: Duration(seconds: 180),
      restTime: Duration(seconds: 60),
      rounds: 3,
      style: TimerStyle.ring,
    );
    final start = now;
    final run = (recorder.start(long) as Success<TimerActivityRun>).value;
    now = start.add(const Duration(seconds: 395));
    run.end(const Duration(seconds: 395));
    await Future<void>.delayed(Duration.zero);

    final finish = repository.finishes.single;
    expect(finish.phases.map((phase) => phase.type), [
      CompletedPhaseType.work,
      CompletedPhaseType.rest,
      CompletedPhaseType.work,
    ]);
    expect(finish.phases.map((phase) => phase.roundNumber), [1, 1, 2]);
    expect(finish.phases.map((phase) => phase.durationMs), [180000, 60000, 150000]);
    expect(finish.endedAtUtcMs, now.millisecondsSinceEpoch);
  });

  test('leaving while paused saves the time up to the pause', () async {
    final start = now;
    final run = (recorder.start(params) as Success<TimerActivityRun>).value;
    now = start.add(const Duration(seconds: 5));
    run.pause(const Duration(seconds: 5));
    now = now.add(const Duration(minutes: 2));
    run.end(const Duration(seconds: 5));
    await Future<void>.delayed(Duration.zero);

    final phase = repository.finishes.single.phases.single;
    expect(phase.type, CompletedPhaseType.work);
    expect(phase.durationMs, 3000);
    expect(phase.completedAtUtcMs, start.add(const Duration(seconds: 5)).millisecondsSinceEpoch);
  });

  test('leaving after the finish saves every phase', () async {
    final start = now;
    final run = (recorder.start(params) as Success<TimerActivityRun>).value;
    now = start.add(const Duration(seconds: 27));
    run.reconcile(const Duration(seconds: 27));
    now = now.add(const Duration(minutes: 1));
    run.end(const Duration(seconds: 27));
    await Future<void>.delayed(Duration.zero);

    final finish = repository.finishes.single;
    expect(finish.phases.map((phase) => phase.durationMs), [10000, 5000, 10000]);
    expect(finish.endedAtUtcMs, start.add(const Duration(seconds: 27)).millisecondsSinceEpoch);
  });

  test('leaving during preparation finishes the run with no phases', () async {
    final run = (recorder.start(params) as Success<TimerActivityRun>).value;
    now = now.add(const Duration(seconds: 1));
    run.end(const Duration(seconds: 1));
    await Future<void>.delayed(Duration.zero);

    final finish = repository.finishes.single;
    expect(finish.phases, isEmpty);
    expect(finish.endedAtUtcMs, now.millisecondsSinceEpoch);
  });

  test('writes the run only once at end', () async {
    final run = (recorder.start(params) as Success<TimerActivityRun>).value;
    now = now.add(const Duration(seconds: 13));
    run.reconcile(const Duration(seconds: 13));
    run.pause(const Duration(seconds: 13));
    run.resume();
    await Future<void>.delayed(Duration.zero);
    expect(repository.createAttempts, 1);
    expect(repository.finishes, isEmpty);

    now = now.add(const Duration(seconds: 1));
    run.end(const Duration(seconds: 14));
    run.end(const Duration(seconds: 15));
    await Future<void>.delayed(Duration.zero);
    expect(repository.finishes, hasLength(1));
  });

  test('saves a draft every 10 s while running', () {
    fakeAsync((fake) {
      final start = now;
      final run = startRun();
      fake.elapse(const Duration(seconds: 5));
      now = start.add(const Duration(seconds: 5));
      run.reconcile(const Duration(seconds: 5));
      fake.flushMicrotasks();
      expect(repository.drafts, isEmpty);

      fake.elapse(const Duration(seconds: 5));
      expect(repository.drafts, hasLength(1));
      expect(repository.drafts.single.phases.single.durationMs, 3000);

      now = start.add(const Duration(seconds: 11));
      run.reconcile(const Duration(seconds: 11));
      fake.elapse(const Duration(seconds: 10));
      expect(repository.drafts, hasLength(2));
      expect(repository.drafts.last.phases.single.durationMs, 9000);
      expect(repository.drafts.last.checkpointAtUtcMs, now.millisecondsSinceEpoch);
      recorder.dispose();
    });
  });

  test('saves a draft at each phase change and stops after the finish', () {
    fakeAsync((fake) {
      final start = now;
      final run = startRun();
      now = start.add(const Duration(seconds: 13));
      run.reconcile(const Duration(seconds: 13));
      fake.flushMicrotasks();
      expect(repository.drafts, hasLength(1));
      expect(repository.drafts.last.phases.map((phase) => phase.durationMs), [10000, 1000]);

      now = start.add(const Duration(seconds: 27));
      run.reconcile(const Duration(seconds: 27));
      fake.flushMicrotasks();
      expect(repository.drafts, hasLength(2));
      expect(repository.drafts.last.phases.map((phase) => phase.durationMs), [10000, 5000, 10000]);
      expect(fake.periodicTimerCount, 0);

      fake.elapse(const Duration(seconds: 60));
      expect(repository.drafts, hasLength(2));
      recorder.dispose();
    });
  });

  test('saves a draft on pause and none while paused', () {
    fakeAsync((fake) {
      final start = now;
      final run = startRun();
      fake.elapse(const Duration(seconds: 5));
      now = start.add(const Duration(seconds: 5));
      run.pause(const Duration(seconds: 5));
      fake.flushMicrotasks();
      expect(repository.drafts, hasLength(1));
      expect(repository.drafts.single.phases.single.durationMs, 3000);

      fake.elapse(const Duration(seconds: 30));
      expect(repository.drafts, hasLength(1));

      now = now.add(const Duration(seconds: 30));
      run.resume();
      fake.elapse(const Duration(seconds: 9));
      expect(repository.drafts, hasLength(1));
      fake.elapse(const Duration(seconds: 1));
      expect(repository.drafts, hasLength(2));
      recorder.dispose();
    });
  });

  test('a second pause saves no draft', () {
    fakeAsync((fake) {
      final start = now;
      final run = startRun();
      fake.elapse(const Duration(seconds: 5));
      now = start.add(const Duration(seconds: 5));
      run.pause(const Duration(seconds: 5));
      fake.flushMicrotasks();
      now = start.add(const Duration(seconds: 6));
      run.pause(const Duration(seconds: 6));
      fake.elapse(const Duration(seconds: 30));
      expect(repository.drafts, hasLength(1));
      recorder.dispose();
    });
  });

  test('a pause with a smaller elapsed saves no draft', () {
    fakeAsync((fake) {
      final start = now;
      final run = startRun();
      fake.elapse(const Duration(seconds: 8));
      now = start.add(const Duration(seconds: 8));
      run.reconcile(const Duration(seconds: 8));
      run.pause(const Duration(seconds: 5));
      fake.flushMicrotasks();
      expect(repository.drafts, isEmpty);

      fake.elapse(const Duration(seconds: 2));
      expect(repository.drafts, hasLength(1));

      now = start.add(const Duration(seconds: 11));
      run.pause(const Duration(seconds: 11));
      fake.flushMicrotasks();
      expect(repository.drafts, hasLength(2));
      recorder.dispose();
    });
  });

  test('pause and resume after the finish do not restart the draft timer', () {
    fakeAsync((fake) {
      final start = now;
      final run = startRun();
      now = start.add(const Duration(seconds: 27));
      run.reconcile(const Duration(seconds: 27));
      fake.flushMicrotasks();
      expect(repository.drafts, hasLength(1));

      run.pause(const Duration(seconds: 27));
      run.resume();
      expect(fake.periodicTimerCount, 0);
      fake.elapse(const Duration(seconds: 60));
      expect(repository.drafts, hasLength(1));
      recorder.dispose();
    });
  });

  test('resume while not paused does not restart the timer', () {
    fakeAsync((fake) {
      final start = now;
      final run = startRun();
      fake.elapse(const Duration(seconds: 5));
      now = start.add(const Duration(seconds: 5));
      run.reconcile(const Duration(seconds: 5));
      run.resume();
      expect(fake.periodicTimerCount, 1);
      fake.elapse(const Duration(seconds: 5));
      expect(repository.drafts, hasLength(1));
      recorder.dispose();
    });
  });

  test('skips empty and unchanged drafts', () {
    fakeAsync((fake) {
      final start = now;
      final run = startRun();
      fake.elapse(const Duration(seconds: 1));
      now = start.add(const Duration(seconds: 1));
      run.reconcile(const Duration(seconds: 1));
      fake.elapse(const Duration(seconds: 9));
      expect(repository.drafts, isEmpty);

      now = start.add(const Duration(seconds: 11));
      run.reconcile(const Duration(seconds: 11));
      fake.elapse(const Duration(seconds: 10));
      expect(repository.drafts, hasLength(1));

      fake.elapse(const Duration(seconds: 10));
      expect(repository.drafts, hasLength(1));
      recorder.dispose();
    });
  });

  test('end writes only finishRun', () {
    fakeAsync((fake) {
      final start = now;
      final run = startRun();
      now = start.add(const Duration(seconds: 5));
      run.reconcile(const Duration(seconds: 5));
      fake.flushMicrotasks();
      final draftCount = repository.drafts.length;

      now = start.add(const Duration(seconds: 13));
      run.end(const Duration(seconds: 13));
      fake.flushMicrotasks();
      expect(repository.drafts, hasLength(draftCount));
      expect(repository.finishes, hasLength(1));

      fake.elapse(const Duration(seconds: 60));
      expect(repository.drafts, hasLength(draftCount));
      recorder.dispose();
    });
  });

  test('drafts wait for the session creation', () {
    fakeAsync((fake) {
      final start = now;
      repository.createGate = Completer<void>();
      final run = startRun();
      now = start.add(const Duration(seconds: 13));
      run.reconcile(const Duration(seconds: 13));
      fake.flushMicrotasks();
      expect(repository.drafts, isEmpty);

      repository.createGate?.complete();
      fake.flushMicrotasks();
      expect(repository.events, ['create', 'draft']);
      recorder.dispose();
    });
  });

  test('a newer write supersedes a waiting draft', () {
    fakeAsync((fake) {
      final start = now;
      repository.createGate = Completer<void>();
      final first = startRun();
      now = start.add(const Duration(seconds: 13));
      first.reconcile(const Duration(seconds: 13));
      now = start.add(const Duration(seconds: 27));
      first.reconcile(const Duration(seconds: 27));
      final second = startRun();
      second.reconcile(const Duration(seconds: 13));
      second.end(const Duration(seconds: 15));

      repository.createGate?.complete();
      fake.flushMicrotasks();
      expect(repository.drafts, hasLength(1));
      expect(repository.drafts.single.phases, hasLength(3));
      expect(repository.finishes, hasLength(1));
      recorder.dispose();
    });
  });

  test('a failed draft does not block a later finishRun', () {
    fakeAsync((fake) {
      final start = now;
      final failures = <Exception>[];
      recorder.failures.listen(failures.add);
      repository.failDraft = true;
      final run = startRun();
      now = start.add(const Duration(seconds: 13));
      run.reconcile(const Duration(seconds: 13));
      fake.flushMicrotasks();
      expect(repository.drafts, hasLength(1));
      expect(failures, hasLength(1));
      expect(repository.finishes, isEmpty);

      run.end(const Duration(seconds: 15));
      fake.flushMicrotasks();
      expect(repository.finishes, hasLength(1));
      expect(repository.drafts, hasLength(1));
      expect(failures, hasLength(1));
      recorder.dispose();
    });
  });

  test('a failed draft in flight is dropped when a write waits behind it', () {
    fakeAsync((fake) {
      final start = now;
      final failures = <Exception>[];
      recorder.failures.listen(failures.add);
      repository.failDraft = true;
      repository.draftGate = Completer<void>();
      final run = startRun();
      now = start.add(const Duration(seconds: 13));
      run.reconcile(const Duration(seconds: 13));
      fake.flushMicrotasks();
      expect(repository.drafts, hasLength(1));

      run.end(const Duration(seconds: 15));
      fake.flushMicrotasks();
      expect(repository.finishes, isEmpty);

      repository.draftGate?.complete();
      fake.flushMicrotasks();
      expect(failures, hasLength(1));
      expect(repository.finishes, hasLength(1));
      expect(repository.drafts, hasLength(1));
      recorder.dispose();
    });
  });
}
