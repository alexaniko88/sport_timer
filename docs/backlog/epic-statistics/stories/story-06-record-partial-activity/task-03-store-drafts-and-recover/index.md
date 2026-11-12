---
id: STAT-06-03
status: ready
type: feat
complexity: 7
depends-on: [STAT-06-02, DEV-01-01]
touches:
  - lib/main.dart
  - lib/features/statistics/domain/activity_repository.dart
  - lib/features/statistics/data/activity_access.dart
  - lib/features/statistics/data/activity_database.dart
  - lib/features/statistics/data/sqflite_activity_repository.dart
  - test/features/statistics/data/activity_access_test.dart
skills: []
---

# Store drafts and recover unfinished runs

Story: [Record partial activity](../index.md)

Epic: [Statistics](../../../index.md)

## Goal

Add hidden draft storage for a running workout and turn unfinished drafts into final records on the next app start, so a run killed by the OS keeps its time up to the last draft. Statistics never read drafts. This task is the storage half; [Save drafts while the timer runs (STAT-06-05)](../task-05-save-drafts-while-running/index.md) makes the recorder save the drafts. Serves R5, R6 and R7.

## Context

- Story rules: [Record partial activity](../index.md) (agreed behavior, decisions and shared contracts).
- `lib/features/statistics/data/activity_database.dart`: `schemaVersion` is 2; `_migrate` creates `timer_sessions` (v1) and `completed_phases` (v2, `ON DELETE RESTRICT`, `UNIQUE (session_id, schedule_position)`). `PRAGMA foreign_keys = ON` is set in `onConfigure`. The constructor takes an optional `databasePath`.
- `lib/features/statistics/data/activity_access.dart`: reads are scoped to the current account (`_requireAccount`); `_closed` is set by `close()`. After DEV-01-01 it has a purge epoch and `deleteAllActivity()`, which deletes `completed_phases` and then `timer_sessions` for all accounts. After STAT-06-02 it has `finishRun` and private helpers for the per-phase insert check and the end-time update.
- `lib/features/statistics/data/sqflite_activity_repository.dart`: `_run` turns exceptions and `StateError` into `Failure`.
- `lib/main.dart`: `main()` awaits `Firebase.initializeApp`, calls `configureDependencies()` and then `runApp`. It imports `package:flutter/material.dart` (which exports `debugPrint`) and `package:sport_timer/di/di.dart` (`getIt`); `dart:async` is needed for `unawaited`.

## Contract

- `ActivityRepository.finishRun` and `ActivityAccess.finishRun` — provided by [Save the run once when leaving the timer (STAT-06-02)](../task-02-save-on-leaving-timer/index.md). Changed here: its transaction also deletes the session's `draft_phases`.
- Purge epoch, `deleteAllActivity()` and the real-SQLite test setup in `test/features/statistics/data/activity_access_test.dart` — provided by [Purge activity storage (DEV-01-01)](../../../../epic-developer-tools/stories/story-01-purge-local-activity/done/task-01-purge-activity-storage/index.md).
- `saveDraft` — new here; its consumer is the recorder in STAT-06-05. Nothing in `lib/` calls it after this task.

Schema version 3 — new here, in `_migrate`, non-destructive (`schemaVersion` becomes 3):

- `ALTER TABLE timer_sessions ADD COLUMN checkpoint_at_utc_ms INTEGER` (null by default).
- `CREATE TABLE draft_phases` with the same columns and checks as `completed_phases`, except `session_id TEXT NOT NULL REFERENCES timer_sessions(id) ON DELETE CASCADE`. Keep `UNIQUE (session_id, schedule_position)`.
- A session has a draft when `ended_at_utc_ms IS NULL` and `checkpoint_at_utc_ms IS NOT NULL`. Old sessions have no checkpoint, so they are never recovered.
- Statistics queries are not changed; they never read `draft_phases`.

`saveDraft` — new here on `ActivityRepository`, `ActivityAccess` (returns `Future<void>`) and `SqfliteActivityRepository` (through `_run`):

- `Future<Result<void>> saveDraft({required ActivitySessionHandle session, required List<CompletedPhase> phases, required int checkpointAtUtcMs})`.
- Verifies the handle like `addPhases` (phases from another session throw `StateError('Phase belongs to another session')`).
- Then one transaction, with its checks in this order:
  1. Stale handle (the purge epoch changed since the handle was issued): write nothing and return normally, like the other handle writes.
  2. No session row for the handle's account: throw `StateError('Session not found')`, like `finishRun`.
  3. Session already has an end: write nothing and return normally.
  4. Otherwise delete the session's `draft_phases`, insert `phases` (an empty list is allowed) and set `checkpoint_at_utc_ms`.
- It does not emit on `changes`, because statistics do not read drafts.

`recoverUnfinishedRuns` — new here on `ActivityRepository`, `ActivityAccess` (returns `Future<void>`, throws the first error) and `SqfliteActivityRepository` (through `_run`, with no account check):

- `Future<Result<void>> recoverUnfinishedRuns({required int startedBeforeUtcMs})`.
- Works for all accounts, with no signed-in account needed. Throws `StateError('Activity access is closed')` only when the access is closed.
- Handles only sessions with a draft and `started_at_utc_ms < startedBeforeUtcMs`.
- Each session is recovered in its own transaction: insert its draft phases into `completed_phases` (same per-phase rule as `finishRun`), set `ended_at_utc_ms` to its `checkpoint_at_utc_ms`, delete its draft phases. Each phase keeps its own stored local date and offset.
- If one session throws, only that session rolls back, the others are still tried, and the call then fails with the first error (`Failure` from the repository). A session that failed keeps its draft and is tried again on the next start.
- Emits on `changes` once if at least one session was recovered.

Startup — changed in `lib/main.dart`: after `configureDependencies()`, start `getIt<ActivityRepository>().recoverUnfinishedRuns(startedBeforeUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch)` once, without awaiting it (`unawaited`), and log a `Failure` with `debugPrint`. `runApp` is not delayed.

## Decisions

- **Separate `draft_phases` table with cascade delete:** chosen by the user. Deleting a session (the purge in DEV-01-01, or [Delete statistics](../../story-05-delete-statistics/index.md)) removes its draft, so deleted history cannot come back.
- **Recovered under the original account:** the draft's session already stores its `account_id`, so recovery does not depend on who is signed in.
- **Recovered end time:** the session's end and the date of its last partial phase come from the last draft, not from when the app opens again.
- **Only sessions started before recovery began (planner choice):** so recovery never touches a workout started right after the app opens.

## Out of scope

- Saving drafts from the recorder, the draft moments and the queue rules (STAT-06-05).
- Restoring the timer screen or continuing the interrupted workout.
- Any Statistics UI change.
- Integration tests and device runs. The integration test setup does not exist yet.

## Files and tests

- Fakes: every `ActivityRepository` fake overrides `noSuchMethod`, so the new methods need no change in any of them: `FakeEmptyActivityRepository` in `test/features/statistics/fake_activity_repository.dart`, `_Repository` in `test/features/statistics/presentation/day_details_page_test.dart`, `_Repository` in `test/features/statistics/presentation/day_details_view_model_test.dart`, `_FakeActivityRepository` in `test/features/statistics/presentation/statistics_page_test.dart`, `FakeActivityRepository` in `test/features/statistics/presentation/statistics_view_model_test.dart`, `_FakeActivityRepository` in `test/snapshots/ui_snapshots_test.dart` and `_Repository` in `test/features/timer/data/default_timer_activity_recorder_test.dart` (STAT-06-05 gives that one a recording `saveDraft`). `DelayedAccess` in `test/features/statistics/data/sqflite_activity_repository_test.dart` extends `ActivityAccess` and inherits the new methods.
- `test/features/statistics/data/activity_access_test.dart` (unit, real in-memory SQLite from DEV-01-01). For the upgrade test only, use a temporary file (an in-memory database is lost when it closes): create a folder with `Directory.systemTemp.createTemp`, open a version 2 database there with `databaseFactory.openDatabase` and the version 2 SQL copied from `_migrate`, insert a session and phases, close it, then open the same path with `ActivityDatabase(databasePath: ...)`. Delete the folder with `addTearDown`. All other tests keep the in-memory database.
- `lib/main.dart` has no test (it initializes Firebase); its change is the three-line startup call above.

## Acceptance

- [ ] When `saveDraft` runs twice for a session, then `draft_phases` holds only the second list, `checkpoint_at_utc_ms` is the second value, `changes` does not emit and `readDailyActivity` does not include the draft. Check: `test/features/statistics/data/activity_access_test.dart` "saveDraft replaces the draft and statistics ignore it".
- [ ] When `saveDraft` runs for a session that already has an end, or with a handle from before `deleteAllActivity()`, then it returns `Success` and writes nothing. Check: `test/features/statistics/data/activity_access_test.dart` "saveDraft writes nothing for an ended session or a stale handle".
- [ ] When `saveDraft` gets a phase from another session, then it returns `Failure` and writes nothing. Check: `test/features/statistics/data/activity_access_test.dart` "saveDraft rejects a phase from another session".
- [ ] When `saveDraft` runs with a valid, current handle whose session row no longer exists for the handle's account (the test removes it with a raw `DELETE FROM timer_sessions` on the database connection, without a purge), then the repository returns `Failure` (from `StateError('Session not found')`) and no draft row is written. Check: `test/features/statistics/data/activity_access_test.dart` "saveDraft fails when the session is missing".
- [ ] When `finishRun` runs for a session with a draft, then it writes the final records and removes the session's draft in the same transaction. Check: `test/features/statistics/data/activity_access_test.dart` "finishRun removes the draft".
- [ ] When the app starts and finds a draft, then `recoverUnfinishedRuns` saves its phases as completed phases with their stored local dates, sets the session's end to `checkpoint_at_utc_ms`, removes the draft and emits on `changes` once. Check: `test/features/statistics/data/activity_access_test.dart` "recovery turns a draft into completed phases".
- [ ] When `recoverUnfinishedRuns` runs twice, then the second call changes nothing and does not emit. Check: `test/features/statistics/data/activity_access_test.dart` "recovery runs only once per draft".
- [ ] When the draft belongs to account B and account A is signed in, or no account is signed in, then it is saved under B and never appears in A's `readDailyActivity`. Check: `test/features/statistics/data/activity_access_test.dart` "recovery keeps the account that started the run".
- [ ] When sessions with drafts are deleted (`deleteAllActivity`), then their draft rows are gone and recovery adds nothing back. Check: `test/features/statistics/data/activity_access_test.dart` "deleted sessions lose their drafts and stay deleted".
- [ ] When a session with a draft has `started_at_utc_ms` equal to or later than `startedBeforeUtcMs`, then recovery leaves it alone. Check: `test/features/statistics/data/activity_access_test.dart` "recovery skips sessions started after it began".
- [ ] When one session's draft conflicts with an existing completed phase and another session's draft is fine, then the good one is recovered, the bad one keeps its draft, and the repository returns `Failure`. Check: `test/features/statistics/data/activity_access_test.dart` "recovery keeps going after one session fails".
- [ ] When the access is closed, then `recoverUnfinishedRuns` returns `Failure`. Check: `test/features/statistics/data/activity_access_test.dart` "recovery fails when the access is closed".
- [ ] When a version 2 database with history is opened, then it upgrades to version 3, keeps all sessions and phases, and has the `draft_phases` table and the `checkpoint_at_utc_ms` column. Check: `test/features/statistics/data/activity_access_test.dart` "upgrades a version 2 database to version 3".
- [ ] When all changed files are checked, then format, analyze (including `lib/main.dart`), the mirrored tests and the boundary test pass. Check: `fvm dart tool/agent_check.dart --skip-build`.
