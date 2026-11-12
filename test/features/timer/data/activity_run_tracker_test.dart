import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/extensions/date_time_extension.dart';
import 'package:sport_timer/features/settings/domain/timer_style.dart';
import 'package:sport_timer/features/statistics/domain/completed_phase.dart';
import 'package:sport_timer/features/timer/data/activity_run_tracker.dart';
import 'package:sport_timer/features/timer/domain/timer_params.dart';
import 'package:sport_timer/features/timer/domain/timer_schedule.dart';

void main() {
  // Stages: preparation 0-10, work 1 10-130, rest 1 130-160, work 2 160-280.
  const params = TimerParams(
    preparationTime: Duration(seconds: 10),
    roundTime: Duration(seconds: 120),
    restTime: Duration(seconds: 30),
    rounds: 2,
    style: TimerStyle.ring,
  );

  late DateTime startedAt;
  late DateTime now;
  late int nextId;
  late ActivityRunTracker tracker;

  ActivityRunTracker buildTracker(TimerParams value) => ActivityRunTracker(
        schedule: TimerSchedule.fromParams(value),
        sessionId: 'run-1',
        startedAt: startedAt,
        clock: () => now,
        newId: () => 'id-${nextId++}',
      );

  // Moves the wall clock together with the elapsed time, so no clock correction happens.
  List<CompletedPhase> reconcileAt(Duration elapsed) {
    now = startedAt.add(elapsed);
    return tracker.reconcile(elapsed);
  }

  setUp(() {
    startedAt = DateTime(2026, 3, 1, 12);
    now = startedAt;
    nextId = 0;
    tracker = buildTracker(params);
  });

  test('partial work counts whole seconds', () {
    reconcileAt(const Duration(milliseconds: 93800));

    final phase = tracker.snapshot().single;
    expect(phase.type, CompletedPhaseType.work);
    expect(phase.durationMs, 83000);
    expect(phase.roundNumber, 1);
    expect(phase.schedulePosition, 1);
  });

  test('partial rest counts whole seconds', () {
    reconcileAt(const Duration(milliseconds: 142400));

    final snapshot = tracker.snapshot();
    expect(snapshot, hasLength(2));
    expect(snapshot.first.type, CompletedPhaseType.work);
    expect(snapshot.first.durationMs, 120000);
    expect(snapshot.last.type, CompletedPhaseType.rest);
    expect(snapshot.last.durationMs, 12000);
    expect(snapshot.last.roundNumber, 1);
  });

  test('no partial phase under one second', () {
    reconcileAt(const Duration(milliseconds: 10900));
    expect(tracker.snapshot(), isEmpty);

    reconcileAt(const Duration(milliseconds: 130999));
    expect(tracker.snapshot().map((phase) => phase.type), [CompletedPhaseType.work]);
  });

  test('snapshot is empty during preparation', () {
    reconcileAt(const Duration(seconds: 5));

    expect(tracker.snapshot(), isEmpty);
  });

  test('pause excludes paused time from the partial phase', () {
    reconcileAt(const Duration(seconds: 40));
    final pausedAt = now.toUtc();
    tracker.pause(const Duration(seconds: 40));
    now = now.add(const Duration(seconds: 30));

    final paused = tracker.snapshot().single;
    expect(paused.durationMs, 30000);
    expect(paused.completedAtUtcMs, pausedAt.millisecondsSinceEpoch);

    final resumedAt = now.toUtc();
    tracker.resume();
    final resumed = tracker.snapshot().single;
    expect(resumed.durationMs, 30000);
    expect(resumed.completedAtUtcMs, resumedAt.millisecondsSinceEpoch);

    now = now.add(const Duration(seconds: 5));
    tracker.reconcile(const Duration(seconds: 45));
    final later = tracker.snapshot().single;
    expect(later.durationMs, 35000);
    expect(
      later.completedAtUtcMs,
      resumedAt.add(const Duration(seconds: 5)).millisecondsSinceEpoch,
    );
  });

  test('reconcile while paused does not change the snapshot', () {
    reconcileAt(const Duration(seconds: 40));
    tracker.pause(const Duration(seconds: 40));
    final before = tracker.snapshot();

    final completed = reconcileAt(const Duration(seconds: 60));

    expect(completed, isEmpty);
    expect(tracker.snapshot(), before);
  });

  test('pause returns the phases it completes', () {
    now = startedAt.add(const Duration(seconds: 135));
    final completed = tracker.pause(const Duration(seconds: 135));

    expect(completed, hasLength(1));
    expect(completed.single.type, CompletedPhaseType.work);
    expect(completed.single.durationMs, 120000);
    expect(tracker.pause(const Duration(seconds: 140)), isEmpty);

    tracker.resume();
    expect(tracker.pause(const Duration(seconds: 100)), isEmpty);
    expect(tracker.lastElapsed, const Duration(seconds: 135));
  });

  test('late reconcile lists every crossed phase and the partial one', () {
    final completed = reconcileAt(const Duration(seconds: 170));

    expect(completed.map((phase) => phase.schedulePosition), [1, 2]);
    final snapshot = tracker.snapshot();
    expect(snapshot.map((phase) => phase.schedulePosition), [1, 2, 3]);
    expect(snapshot.map((phase) => phase.durationMs), [120000, 30000, 10000]);
    expect(
      snapshot.map((phase) => phase.type),
      [CompletedPhaseType.work, CompletedPhaseType.rest, CompletedPhaseType.work],
    );
    expect(snapshot.last.roundNumber, 2);
  });

  test('a phase keeps its id from partial to completed', () {
    reconcileAt(const Duration(milliseconds: 93800));
    final partial = tracker.snapshot().single;

    final completed = reconcileAt(const Duration(seconds: 130));

    expect(completed.single.id, partial.id);
    expect(completed.single.durationMs, 120000);
  });

  test('snapshots without progress are equal', () {
    reconcileAt(const Duration(milliseconds: 93800));

    expect(tracker.snapshot(), tracker.snapshot());
  });

  test('partial phase after midnight belongs to the new day', () {
    startedAt = DateTime(2026, 3, 1, 23, 59, 50);
    now = startedAt;
    tracker = buildTracker(params);

    reconcileAt(const Duration(seconds: 40));

    final phase = tracker.snapshot().single;
    final instant = DateTime.fromMillisecondsSinceEpoch(phase.completedAtUtcMs, isUtc: true).toLocal();
    expect(phase.localCompletionDate, instant.asIsoDate);
    expect(phase.localCompletionDate, '2026-03-02');
    expect(phase.localCompletionDate, isNot(startedAt.asIsoDate));
  });

  test('isFinished and endInstant after the last stage', () {
    expect(tracker.isFinished, isFalse);

    reconcileAt(const Duration(seconds: 285));

    expect(tracker.isFinished, isTrue);
    expect(tracker.endInstant, startedAt.add(const Duration(seconds: 280)).toUtc());

    const emptyParams = TimerParams(
      preparationTime: Duration.zero,
      roundTime: Duration.zero,
      restTime: Duration.zero,
      rounds: 0,
      style: TimerStyle.ring,
    );
    expect(buildTracker(emptyParams).isFinished, isTrue);
  });

  test('endInstant while paused and while running', () {
    reconcileAt(const Duration(seconds: 50));
    expect(tracker.endInstant, startedAt.add(const Duration(seconds: 50)).toUtc());

    tracker.pause(const Duration(seconds: 50));
    now = now.add(const Duration(seconds: 20));
    expect(tracker.endInstant, now.toUtc());
  });
}
