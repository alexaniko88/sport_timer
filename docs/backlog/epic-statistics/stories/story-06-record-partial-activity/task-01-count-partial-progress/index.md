---
id: STAT-06-01
status: ready
type: feat
complexity: 6
depends-on: []
touches:
  - lib/features/timer/data/activity_run_tracker.dart
  - lib/features/timer/data/default_timer_activity_recorder.dart
  - test/features/timer/data/activity_run_tracker_test.dart
  - test/features/timer/data/default_timer_activity_recorder_test.dart
skills: []
---

# Count partial progress in whole seconds

Story: [Record partial activity](../index.md)

Epic: [Statistics](../../../index.md)

## Goal

Move the phase counting out of the recorder's private run into a small, testable tracker, and teach it to report the phase in progress in whole seconds. What gets written to the database does not change in this task; [STAT-06-02](../task-02-save-on-leaving-timer/index.md) and [STAT-06-03](../task-03-checkpoint-and-recover/index.md) use the new snapshot to write.

## Context

- Story rules: [Record partial activity](../index.md) (agreed behavior and decisions).
- `lib/features/timer/data/default_timer_activity_recorder.dart`: `_RecordingRun` holds the counting today. `reconcile(elapsed)` walks `_schedule.stages` from `_nextStage`, builds a `CompletedPhase` for each finished `TimerStatus.round` or `TimerStatus.rest` stage (full `lengthSeconds`), and corrects its wall-clock projection when the observed clock differs by more than `_clockTolerance` (1 s). `pause`, `resume` and `end` keep `_segmentStart`, `_segmentElapsed`, `_lastElapsed`, `_lastInstant` and `_finishedAt`.
- `lib/features/timer/domain/timer_schedule.dart`: `TimerSchedule.stages` (`TimerStage` with `type`, `round`, `startSeconds`, `lengthSeconds`, `endSeconds`). Stages with length 0 are skipped, so there is no rest after the last round.
- `lib/features/statistics/domain/completed_phase.dart`: `CompletedPhase` and `CompletedPhaseType`. It is not changed.
- `lib/core/extensions/date_time_extension.dart`: `asIsoDate`, used for `localCompletionDate`.
- New code goes in the timer feature's data layer, next to the recorder.

## Behavior

Create `ActivityRunTracker` in `lib/features/timer/data/activity_run_tracker.dart`. It is plain Dart (no Flutter import) and owns the counting state that `_RecordingRun` has today.

- Constructor takes: `TimerSchedule schedule`, `String sessionId`, `DateTime startedAt`, `ActivityWallClock clock` and `ActivityIdGenerator newId`. Move the `ActivityWallClock` and `ActivityIdGenerator` typedefs from the recorder file into the tracker file; the recorder imports the tracker file.
- The tracker owns the counting state: `_segmentStart`, `_segmentElapsed`, `_lastElapsed`, `_lastInstant`, `_finishedAt`, `_nextStage` and `_paused`. `_RecordingRun` keeps only `_ended` and the write queue.
- `List<CompletedPhase> reconcile(Duration elapsed)`: exactly the rules of `_RecordingRun.reconcile` today (ignore an elapsed smaller than the last one; while paused, only `_lastElapsed` moves; clock correction unchanged). It returns the phases that completed during this call, at full length.
- `Duration get lastElapsed`: the last accepted elapsed, so `_RecordingRun.end` can keep its guard.
- The tracker stores each completed `CompletedPhase` object when it completes (it does not rebuild them later), so a later clock correction never changes a stored phase.
- `List<CompletedPhase> pause(Duration elapsed)`: like `_RecordingRun.pause` today, it reconciles to `elapsed` first, then pauses. It returns the phases that completed during that reconcile, so the recorder can write them as it does today. It is ignored (returns an empty list) when already paused or when `elapsed` is smaller than the last one.
- `void resume()`: same rules as `_RecordingRun.resume` today.
- `List<CompletedPhase> snapshot()`: all completed phases so far (full length, in schedule order), plus the current partial phase when there is one:
  - The current stage is the stage at the next index not yet completed. Its active elapsed is the elapsed at the moment of `pause` while paused, otherwise `lastElapsed`. It is partial only when it is a work or rest stage and `floor((activeElapsed - stage.startSeconds) / 1 s)` is at least 1. Milliseconds never count. Example: 83.8 s into a work stage gives `durationMs` 83000.
  - Its `completedAtUtcMs`: while paused, the instant held at the moment of `pause` (the `_lastInstant` value then). Otherwise `_segmentStart + (lastElapsed - _segmentElapsed)`, which is the same value `_lastInstant` holds today, including the clock correction. So right after `resume()` it is the resume wall time, and after resuming and reconciling 5 s more it is the resume wall time plus 5 s. `localCompletionDate` and `utcOffsetMinutes` come from that instant in local time, like completed phases.
  - Its `schedulePosition`, `type` and `roundNumber` follow the same rules as a completed phase of that stage.
  - During preparation, or when less than 1 whole second of the current stage has passed, no partial phase is added.
- **Stable IDs:** keep a map from stage index to phase ID. A stage's ID is generated once, the first time the tracker needs it (in `snapshot()` or when the stage completes), and reused afterwards. So a stage that is first reported as partial and later completes keeps the same ID, and two snapshots with no new progress are equal. As long as `snapshot()` is not called, IDs are generated in completion order, exactly as today, so the existing recorder tests (which use a counting `newId`) keep their expected IDs.
- `snapshot()` keeps working after the recorder's run has ended; the tracker has no ended state of its own.
- `DateTime get endInstant`: the end time `_RecordingRun.end` uses today (`_finishedAt`, else the clock when paused, else the current instant).
- `bool get isFinished`: true when every stage has completed (also true from the start for a schedule with no stages).
- `roundNumber` of a partial rest is `stage.round`, the same rule as a completed rest.

Update `_RecordingRun` to delegate to the tracker. Its writes stay exactly as today:

- `reconcile` and `pause`: when the tracker returns completed phases, enqueue `recordPhases` with them.
- `end(elapsed)`: return early when `_ended` or `elapsed < tracker.lastElapsed`. Otherwise call `tracker.reconcile(elapsed)`, enqueue `recordPhases` if it returned phases, set `_ended`, and enqueue `endSession` with `tracker.endInstant`.
- `snapshot()` has no caller in `lib/` yet.

## Decisions

- **Whole seconds, rounded down, for work and rest:** agreed in the story; milliseconds never count.
- **No partial phase under 1 s:** `completed_phases.duration_ms` must be greater than 0, and 0 whole seconds is no activity.
- **The 5 s round rule is not in the tracker:** it is applied by the statistics queries in [STAT-06-02](../task-02-save-on-leaving-timer/index.md), so the tracker reports raw seconds only.
- **Tracker in the data layer (planner choice):** it needs a wall clock and ID generator, like the recorder, and only the recorder uses it.

## Out of scope

- Any change to when or what the recorder writes (STAT-06-02).
- Drafts and recovery (STAT-06-03).
- The round rule and statistics queries.

## Files and tests

- New `lib/features/timer/data/activity_run_tracker.dart`.
- Changed `lib/features/timer/data/default_timer_activity_recorder.dart`: `_RecordingRun` uses the tracker; write behavior unchanged.
- New `test/features/timer/data/activity_run_tracker_test.dart`: unit tests with a hand-written clock function and a counting ID generator, structured like `test/features/timer/data/default_timer_activity_recorder_test.dart`. Use a schedule from `TimerSchedule.fromParams` with preparation, rounds and rest.
- For the midnight test, start the run at a local time such as `DateTime(2026, 3, 1, 23, 59, 50)` and compute the expected date from the partial instant with `.toLocal().asIsoDate`, the way the existing recorder tests do, so the test works in any timezone.
- `test/features/timer/data/default_timer_activity_recorder_test.dart` must pass without changes to its expectations.

## Acceptance

- [ ] When 83.8 s of a work phase have passed, then `snapshot()` has that work phase with `durationMs` 83000. Check: `fvm flutter test test/features/timer/data/activity_run_tracker_test.dart`.
- [ ] When 12.4 s of a rest phase have passed, then `snapshot()` has that rest phase with `durationMs` 12000. Check: same test file.
- [ ] When less than 1 whole second of the current work or rest phase has passed, then `snapshot()` has no partial phase. Check: same test file.
- [ ] When the run is still in preparation, then `snapshot()` is empty. Check: same test file.
- [ ] When the run pauses for 30 s in the middle of a phase and then resumes, then the paused time adds nothing to the partial `durationMs`; while paused, `completedAtUtcMs` is the pause instant; after resuming and reconciling 5 s more, it is the resume wall time plus 5 s. Check: same test file.
- [ ] When `reconcile` is called with a larger elapsed while paused, then `snapshot()` is unchanged. Check: same test file.
- [ ] When one late `reconcile` crosses several phase ends, then `snapshot()` lists every finished work and rest phase at full length, plus the current partial phase. Check: same test file.
- [ ] When a phase is first reported as partial and later completes, then both versions have the same `id`. Check: same test file.
- [ ] When a partial phase's instant falls after local midnight, then its `localCompletionDate` is the new day. Check: same test file.
- [ ] When the existing recorder tests run, then they pass unchanged. Check: `fvm flutter test test/features/timer`.
