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
  - test/features/timer/data/default_timer_activity_recorder_test.dart
  - test/features/timer/presentation/timer_view_model_test.dart
  - test/features/statistics/data/activity_access_test.dart
skills: []
---

# Save the run once when leaving the timer

Story: [Record partial activity](../index.md)

Epic: [Statistics](../../../index.md)

## Goal

Stop writing each phase as it completes. Keep the run in memory and write it once, in one transaction, when the user leaves the timer page, including the partial phase. The statistics queries then count partial time and apply the 5 s round rule. Serves R1, R2, R3, R4 and R8.

## Context

- Story rules: [Record partial activity](../index.md) (agreed behavior, decisions and shared contracts).
- `lib/features/timer/data/default_timer_activity_recorder.dart`: `_RecordingRun` queues writes (`createPreparedSession` at `begin`, `recordPhases` on each completion, `endSession` at `end`) and retries failures with the same values (`_enqueue`, `_drain`, 5 automatic tries with `_retryDelay` 5 s, then `retryPendingWrites`). After STAT-06-01 it delegates counting to `ActivityRunTracker`.
- `lib/features/timer/presentation/timer_view_model.dart`: `_tick` calls `_activityRun?.end(elapsed)` and sets `_activityRun = null` when the timer finishes; `dispose` calls `_activityRun?.end(_elapsed)`. The timer page disposes the ViewModel when the user leaves.
- `lib/features/statistics/data/activity_access.dart`: `addPhase`, `addPhases` (idempotent per phase ID and schedule position, inside a transaction, uses `_verifyHandle`), `endSession`, `readDailyActivity` and `readDayActivity` (round count is `SUM(CASE WHEN p.type = 'work' THEN 1 ELSE 0 END)`; both join `timer_sessions s`).
- `lib/features/statistics/domain/activity_repository.dart`: `recordPhases` and `endSession`. `lib/features/statistics/data/sqflite_activity_repository.dart` wraps each call in `_run`, which turns exceptions and `StateError` into `Failure`.
- `StatisticsViewModel` builds the daily list and chart data from `readDailyActivity`; `DayDetailsViewModel` uses `readDayActivity`. So they follow the queries.
- `lib/features/timer/domain/timer_activity_recorder.dart`: the comments on `TimerActivityRun` describe the current write moments.

## Contract

- `ActivityRunTracker` (`snapshot()`, `endInstant`, `lastElapsed`) — provided by [Count partial progress in whole seconds (STAT-06-01)](../task-01-count-partial-progress/index.md).
- Purge epoch in `ActivityAccess`, `deleteAllActivity()`, `sqflite_common_ffi` dev dependency and the real-SQLite test file `test/features/statistics/data/activity_access_test.dart` (in-memory database, `setUp`/`tearDown`) — provided by [Purge activity storage (DEV-01-01)](../../../../epic-developer-tools/stories/story-01-purge-local-activity/task-01-purge-activity-storage/index.md). A handle issued before a purge is stale: its writes write nothing, return normally and do not emit.
- `ActivityRepository.finishRun` — new here, replaces `recordPhases` and `endSession` on `ActivityRepository` and `SqfliteActivityRepository` (both removed). STAT-06-03 extends it to delete drafts.
  `Future<Result<void>> finishRun({required ActivitySessionHandle session, required List<CompletedPhase> phases, required int endedAtUtcMs})`.
- `ActivityAccess.finishRun` with the same named parameters, returning `Future<void>` — new here:
  1. Before the transaction, verify the handle the same way `addPhases` does (`_verifyHandle`; phases must belong to the session, else `StateError('Phase belongs to another session')`).
  2. Then, in one `db.transaction`, the stale handle check (DEV-01-01's epoch) comes first: a stale handle writes nothing, returns normally and does not emit, also with an empty `phases` list.
  3. Check the session exists for the handle's account (`StateError('Session not found')`).
  4. Insert each phase with the `addPhases` rule: same ID and values is skipped; a different row at the same ID or position throws `StateError('Conflicting completed phase')`.
  5. Set `ended_at_utc_ms` with the `endSession` rule: a different existing end throws `StateError('Conflicting session end')`.
  If anything throws, the transaction rolls back and nothing is kept. With an empty `phases` list it still sets the end time. After success it emits on `changes` once.
- `ActivityAccess.addPhases`, `addPhase` and `endSession` — existing, kept (tests, including DEV-01-01's, build data with them). Move their per-phase insert check and their end-time update into private helpers that take the transaction, and reuse those helpers in `finishRun`, so the rules stay in one place.
- `_RecordingRun` — changed:
  - `reconcile` and `pause` no longer enqueue any write; they only update the tracker.
  - `end(elapsed)` returns early when already ended or `elapsed < tracker.lastElapsed`. Otherwise it reconciles to `elapsed`, captures `tracker.snapshot()` and `tracker.endInstant` once, and enqueues one write: `finishRun(session, phases, endedAtUtcMs)`. A retry sends the same captured values.
  - Session creation at `begin` is unchanged: the session row is written right away; a session with no phases does not appear in statistics.
  - A failed `finishRun` follows the queue's existing retry rules. No new retry rule.
- `TimerViewModel` — changed: when the timer finishes, `_tick` no longer calls `end` and keeps `_activityRun`. The run is ended only in `dispose`, so leaving the page writes it whether the timer finished, is running or is paused.
- Round rule in `readDailyActivity` and `readDayActivity`: a work row counts as a round when `p.duration_ms >= 5000 OR p.duration_ms >= s.work_duration_ms`. Work and rest sums stay as they are. No schema change and no schema version change.

## Decisions

- **Write once, on leaving the page:** agreed by the user. Finishing or pausing does not write final records.
- **Finished run held in memory until leaving:** between finishing and leaving, the run is only in memory. That is accepted here; Save drafts while the timer runs (STAT-06-05) saves a draft at the finish for the kill case.
- **Round rule:** a partial work phase counts as a round from 5 s. A work phase that runs to its end always counts, even when it is set shorter than 5 s. Chosen by the user.
- **Round rule in SQL with no new column (planner choice):** a full phase always has `duration_ms` equal to its session's `work_duration_ms`, so comparing with `timer_sessions.work_duration_ms` tells full phases from partial ones, and existing history keeps the same totals without migrating `completed_phases`.
- **Depends on DEV-01-01:** it brings the real-SQLite test setup and the purge epoch that the new write must respect.

## Out of scope

- Drafts and recovery after a forced close ([Store drafts and recover unfinished runs (STAT-06-03)](../task-03-store-drafts-and-recover/index.md) and [Save drafts while the timer runs (STAT-06-05)](../task-05-save-drafts-while-running/index.md)).
- Any Statistics UI change or golden refresh.
- Changing session creation at start.

## Files and tests

- Update the comments on `TimerActivityRun` in `lib/features/timer/domain/timer_activity_recorder.dart` so they say the run is written once, at `end`. Change `lib/features/timer/data/activity_run_tracker.dart` only if a small fix is needed.
- Fakes: only the `_Repository` fake in `test/features/timer/data/default_timer_activity_recorder_test.dart` defines `recordPhases` and `endSession`; swap them for a `finishRun` that records each call (session, phases, end) and can be made to fail. The other `ActivityRepository` fakes (`test/features/statistics/fake_activity_repository.dart`, the statistics presentation tests, `test/snapshots/ui_snapshots_test.dart`) use `noSuchMethod` and need no change.
- `test/features/timer/data/default_timer_activity_recorder_test.dart` (unit): rewrite the existing tests that read `repository.batches` and `repository.ends` so they read the single `finishRun` call. The tests that assert the old behavior ("pause excludes paused time and stop excludes incomplete work" and the loop "ending at ${elapsed}ms records only completed phases") change to expect the partial phase in whole seconds; rename them to match.
- `test/features/timer/presentation/timer_view_model_test.dart` (unit, `fakeAsync`): reuse `_FakeActivityRun` (it records `ends`). Rewrite "reconciles a delayed lifecycle update and finishes a run only once" so `ends` stays empty after finish and has one entry after `dispose`.
- `test/features/statistics/data/activity_access_test.dart` (unit, real in-memory SQLite from DEV-01-01): add the `finishRun` and round rule cases below.

## Acceptance

- [ ] When the user leaves 2:30 into round 2 with 3:00 rounds, then the single `finishRun` has round 1's work and rest at full length, round 2's work with `durationMs` 150000, and the end instant of the moment of leaving. Check: `test/features/timer/data/default_timer_activity_recorder_test.dart` "leaving mid-round finishes the run with the partial work".
- [ ] When the user leaves while paused, then `finishRun` has the time up to the pause and nothing after it. Check: `test/features/timer/data/default_timer_activity_recorder_test.dart` "leaving while paused saves the time up to the pause".
- [ ] When the user leaves after the timer finished, then `finishRun` has every phase at full length and the finish instant as its end. Check: `test/features/timer/data/default_timer_activity_recorder_test.dart` "leaving after the finish saves every phase".
- [ ] When the user leaves during preparation, then `finishRun` is called with no phases. Check: `test/features/timer/data/default_timer_activity_recorder_test.dart` "leaving during preparation finishes the run with no phases".
- [ ] When `reconcile` and `pause` run before `end`, then nothing but the session creation is written until `end`, and a second `end` adds no write. Check: `test/features/timer/data/default_timer_activity_recorder_test.dart` "writes the run only once at end".
- [ ] When `finishRun` fails in the fake repository and the queue retries it, then the retry sends the same phase IDs, values and end time. Check: `test/features/timer/data/default_timer_activity_recorder_test.dart` "retries a failed finishRun with identical values".
- [ ] When the timer finishes, then `end` is not called; when the ViewModel is then disposed, `end` is called once. Check: `test/features/timer/presentation/timer_view_model_test.dart` "reconciles a delayed lifecycle update and ends the run only on dispose".
- [ ] When `finishRun` gets completed phases and a partial 150000 ms work phase, then every phase is stored, the session has its end time and `changes` emits once. Check: `test/features/statistics/data/activity_access_test.dart` "finishRun stores the phases and the end time".
- [ ] When `finishRun` runs with no phases, then the session gets its end time, `changes` emits, and `readDailyActivity` has no entry for that day. Check: `test/features/statistics/data/activity_access_test.dart` "finishRun with no phases ends the session and adds no day".
- [ ] When `finishRun` gets a valid first phase and a second phase that conflicts with an existing row, then it fails, the first phase is not stored and the session has no end time. Check: `test/features/statistics/data/activity_access_test.dart` "finishRun rolls back on a conflicting phase".
- [ ] When `finishRun` runs with an end time that differs from the session's existing end, then it fails and nothing is stored. Check: `test/features/statistics/data/activity_access_test.dart` "finishRun rolls back on a conflicting end".
- [ ] When `finishRun` runs twice with the same values, then both calls succeed and the database holds exactly one copy of the run's phases and one end time. Check: `test/features/statistics/data/activity_access_test.dart` "finishRun twice with the same values stores one copy".
- [ ] When `finishRun` runs with a handle created before `deleteAllActivity()`, with phases or with an empty list, then the repository returns `Success`, nothing is written and `changes` does not emit. Check: `test/features/statistics/data/activity_access_test.dart` "finishRun with a stale handle writes nothing".
- [ ] When a day has a full 3 s work phase from a session set to 3 s, a partial 5 s work phase and a partial 4 s work phase (both from sessions set to 60 s), all three in separate sessions on the same day, then `readDailyActivity` shows 2 rounds and 12 s of work for that day, and the sums of `activity.roundCount` and `activity.workDurationMs` over the `readDayActivity` summaries for that day are also 2 and 12000. Check: `test/features/statistics/data/activity_access_test.dart` "round rule counts full phases and partial phases from 5 s".
- [ ] When older history has only full-length phases written with `addPhases`, then `readDailyActivity` and `readDayActivity` show one round per work phase and the same work and rest totals as before. Check: `test/features/statistics/data/activity_access_test.dart` "full phases keep their totals under the round rule".
- [ ] When all changed files are checked, then format, analyze, the mirrored tests and the boundary test pass. Check: `fvm dart tool/agent_check.dart --skip-build`.
