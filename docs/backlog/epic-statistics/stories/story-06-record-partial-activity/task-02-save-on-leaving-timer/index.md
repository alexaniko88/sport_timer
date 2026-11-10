---
id: STAT-06-02
status: ready
type: feat
complexity: 9
depends-on: [STAT-06-01, DEV-01-01]
touches:
  - lib/features/timer/data/default_timer_activity_recorder.dart
  - lib/features/timer/data/activity_run_tracker.dart
  - lib/features/timer/domain/timer_activity_recorder.dart
  - lib/features/timer/presentation/timer_view_model.dart
  - lib/features/statistics/domain/activity_repository.dart
  - lib/features/statistics/data/activity_access.dart
  - lib/features/statistics/data/sqflite_activity_repository.dart
  - test/features/timer/**
  - test/features/statistics/**
skills: []
---

# Save the run once when leaving the timer

Story: [Record partial activity](../index.md)

Epic: [Statistics](../../../index.md)

## Goal

Stop writing each phase as it completes. Keep the run in memory and write it once, in one transaction, when the user leaves the timer page, including the partial phase. The statistics queries then count partial time and apply the 5 s round rule.

## Context

- Story rules: [Record partial activity](../index.md) (agreed behavior and decisions).
- [STAT-06-01](../task-01-count-partial-progress/index.md) adds `ActivityRunTracker` (`lib/features/timer/data/activity_run_tracker.dart`) with `snapshot()` and `endInstant`.
- [DEV-01-01](../../../../epic-developer-tools/stories/story-01-purge-local-activity/task-01-purge-activity-storage/index.md) adds a purge epoch to `ActivityAccess` (writes with a handle from before a purge write nothing and succeed), `sqflite_common_ffi` as a dev dependency, and the real-SQLite test file `test/features/statistics/data/activity_access_test.dart`.
- `lib/features/timer/data/default_timer_activity_recorder.dart`: `_RecordingRun` queues writes (`createPreparedSession` at start, `recordPhases` on each completion, `endSession` at `end`) and retries failures with the same values.
- `lib/features/timer/presentation/timer_view_model.dart`: `_tick` calls `_activityRun?.end(elapsed)` and clears `_activityRun` when the timer finishes; `dispose` calls `_activityRun?.end(_elapsed)`. The timer page disposes the ViewModel when the user leaves.
- `lib/features/statistics/data/activity_access.dart`: `addPhases` (idempotent per phase ID and schedule position, inside a transaction), `endSession`, `readDailyActivity` and `readDayActivity` (round count is `SUM(CASE WHEN p.type = 'work' THEN 1 ELSE 0 END)`).
- `lib/features/statistics/domain/activity_repository.dart`: `recordPhases` and `endSession`.
- Chart data and day details are built from `readDailyActivity` and `readDayActivity`, so they follow the queries.

## Behavior

Recorder:

- `_RecordingRun.reconcile` no longer enqueues any write. It only updates the tracker.
- `_RecordingRun.end(elapsed)` reconciles to `elapsed`, takes `tracker.snapshot()` and `tracker.endInstant`, and enqueues one write: `finishRun(session, phases, endedAtUtcMs)`. The values are captured once, so a retry sends the same IDs and values. `end` is still ignored after the first call.
- Session creation at `start` is unchanged (the session row is written right away; a session with no phases does not appear in statistics).
- Update the comments on `TimerActivityRun` in `lib/features/timer/domain/timer_activity_recorder.dart` so they say the run is written once, at `end`.

ViewModel:

- When the timer finishes, `_tick` no longer calls `end` and keeps `_activityRun`. The run is ended only in `dispose`, so leaving the page writes it, whether the timer finished, is running or is paused.
- Between finishing and leaving, the finished run is only in memory. That is accepted here; [STAT-06-03](../task-03-checkpoint-and-recover/index.md) saves a draft at the finish for the kill case.

Repository and storage:

- On `ActivityRepository`, replace `recordPhases` and `endSession` with `Future<Result<void>> finishRun({required ActivitySessionHandle session, required List<CompletedPhase> phases, required int endedAtUtcMs})`. Remove `recordPhases` and `endSession` from `ActivityRepository` and `SqfliteActivityRepository`.
- Keep `ActivityAccess.addPhases`, `addPhase` and `endSession`: tests (including DEV-01-01's `activity_access_test.dart`) build data with them. Move their per-phase insert check and their end-time update into private helpers that take the transaction, and reuse those helpers in `finishRun`, so the rules stay in one place.
- `ActivityAccess.finishRun` runs in one `db.transaction`: it verifies the handle the same way `addPhases` does (`_verifyHandle`, phases must belong to the session), checks the session exists for the handle's account, inserts each phase with the `addPhases` rule (same ID and values is skipped, a different row at the same ID or position throws `StateError('Conflicting completed phase')`), and sets `ended_at_utc_ms` with the `endSession` rule (a different existing end throws `StateError('Conflicting session end')`). If anything throws, the transaction rolls back and nothing is kept. With an empty `phases` list it still sets the end time and emits. Purge epoch (from DEV-01-01): the stale-handle check is the first step inside the transaction, before the session existence check. A stale handle writes nothing, returns normally (so the repository returns `Success`) and does not emit, also with an empty `phases` list. Otherwise it emits on `changes` once after success.
- A failed `finishRun` goes through the recorder queue's existing retry rules (5 automatic tries, then a manual `retryPendingWrites`). No new retry rule.
- No schema change and no schema version change.

Round rule in the queries:

- In `readDailyActivity` and `readDayActivity`, a work row counts as a round when `p.duration_ms >= 5000 OR p.duration_ms >= s.work_duration_ms`. Work and rest sums stay as they are.
- A full phase always has `duration_ms` equal to the session's `work_duration_ms`, so existing history keeps the same totals.

## Decisions

- **Write once, on leaving the page:** agreed by the user. Finishing or pausing does not write final records.
- **Round rule:** a partial work phase counts as a round from 5 s. A work phase that runs to its end always counts, even when it is set shorter than 5 s. Chosen by the user.
- **Round rule in SQL with no new column (planner choice):** comparing with `timer_sessions.work_duration_ms` tells full phases from partial ones without migrating `completed_phases`.
- **Depends on DEV-01-01:** it brings the real-SQLite test setup and the purge epoch that the new write must respect.

## Out of scope

- Drafts and recovery after a forced close ([STAT-06-03](../task-03-checkpoint-and-recover/index.md)).
- Any Statistics UI change or golden refresh.
- Changing session creation at start.

## Files and tests

- Changed: `lib/features/timer/data/default_timer_activity_recorder.dart`, `lib/features/timer/domain/timer_activity_recorder.dart` (comments), `lib/features/timer/presentation/timer_view_model.dart`, `lib/features/statistics/domain/activity_repository.dart`, `lib/features/statistics/data/activity_access.dart`, `lib/features/statistics/data/sqflite_activity_repository.dart`. Change `activity_run_tracker.dart` only if a small fix is needed.
- Only the `_Repository` fake in `test/features/timer/data/default_timer_activity_recorder_test.dart` defines `recordPhases` and `endSession`; swap them for `finishRun` there. The other `ActivityRepository` fakes (`test/features/statistics/fake_activity_repository.dart`, the presentation tests, `test/snapshots/ui_snapshots_test.dart`) use `noSuchMethod` and need no change.
- `test/features/timer/data/default_timer_activity_recorder_test.dart`: rewrite the existing tests that read `repository.batches` and `repository.ends` so they read the single `finishRun` call instead. The tests that assert the old behavior (for example "pause excludes paused time and stop excludes incomplete work" and the loop "ending at ...ms records only completed phases") change to expect the partial phase in whole seconds. Add: leave while running, while paused, after finish and during preparation; a failed `finishRun` retried with the same values.
- `test/features/timer/presentation/timer_view_model_test.dart`: reuse its `_FakeActivityRun` (it records `ends`). Update the tests that expect `end` on finish (for example "reconciles a delayed lifecycle update and finishes a run only once"), so `ends` stays empty after finish and has one entry after `dispose`.
- `test/features/statistics/data/activity_access_test.dart` (real SQLite, in-memory, setup from DEV-01-01): `finishRun`, its rollback, a repeated call, and the round rule in both queries.

## Acceptance

- [ ] When the user leaves 2:30 into round 2 with 3:00 rounds, then round 1's work and rest are saved at full length, round 2's work is saved with `duration_ms` 150000, and the session has its end time. Check: `fvm flutter test test/features/timer/data/default_timer_activity_recorder_test.dart` and `fvm flutter test test/features/statistics/data/activity_access_test.dart`.
- [ ] When the user leaves while paused, then the time up to the pause is saved and nothing after it. Check: `fvm flutter test test/features/timer/data/default_timer_activity_recorder_test.dart`.
- [ ] When the user leaves during preparation, then no phases are saved and `readDailyActivity` has no entry for that day. Check: same recorder test and `fvm flutter test test/features/statistics/data/activity_access_test.dart`.
- [ ] When the timer finishes, then nothing is written until the ViewModel is disposed, and then `end` is called once and one `finishRun` is written. Check: `fvm flutter test test/features/timer`.
- [ ] When `finishRun` gets a valid first phase and a second phase that conflicts with an existing row, then it fails, the first phase is not stored and the session has no end time. Check: `fvm flutter test test/features/statistics/data/activity_access_test.dart`.
- [ ] When `finishRun` runs twice with the same values, then both calls succeed and the database holds exactly one copy of the run's phases and one end time. Check: same test file.
- [ ] When `finishRun` fails in the recorder's fake repository and the queue retries it, then the retry sends the same phase IDs, values and end time. Check: `fvm flutter test test/features/timer/data/default_timer_activity_recorder_test.dart`.
- [ ] When a day has a full 3 s work phase from a session set to 3 s, a partial 5 s work phase and a partial 4 s work phase (both from sessions set to 60 s), all three in separate sessions on the same day, then `readDailyActivity` shows 2 rounds and 12 s of work for that day, and the sums of `activity.roundCount` and `activity.workDurationMs` over the `readDayActivity` summaries for that day are also 2 and 12000. Check: same test file.
- [ ] When `finishRun` runs with a handle created before `deleteAllActivity()`, then it returns `Success`, writes nothing and does not emit on `changes`. Check: same test file.
- [ ] When older history has only full phases, then its totals stay the same. Check: `fvm flutter test test/features/statistics`.
- [ ] When the whole suite runs, then it passes. Check: `fvm flutter test` and `fvm dart tool/agent_check.dart`.
