---
id: STAT-06-03
status: ready
type: feat
complexity: 9
depends-on: [STAT-06-01, STAT-06-02, DEV-01-01]
touches:
  - lib/main.dart
  - lib/features/timer/data/default_timer_activity_recorder.dart
  - lib/features/statistics/domain/activity_repository.dart
  - lib/features/statistics/data/activity_access.dart
  - lib/features/statistics/data/activity_database.dart
  - lib/features/statistics/data/sqflite_activity_repository.dart
  - test/features/timer/**
  - test/features/statistics/**
skills: []
---

# Save drafts and recover a run after a forced close

Story: [Record partial activity](../index.md)

Epic: [Statistics](../../../index.md)

## Goal

While a workout runs, keep a hidden draft of the run in the database. If the OS kills the app, the next app start turns that draft into final records, so at most the time since the last draft is lost. Statistics never read drafts.

## Context

- Story rules: [Record partial activity](../index.md) (agreed behavior and decisions).
- After [STAT-06-02](../task-02-save-on-leaving-timer/index.md), `_RecordingRun` in `lib/features/timer/data/default_timer_activity_recorder.dart` uses `ActivityRunTracker` (`snapshot()`, `endInstant`) and writes the run once with `ActivityRepository.finishRun` when it ends. Writes go through its queue (`_enqueue`, `_drain`), which retries failures and reports them on `failures`.
- `lib/features/statistics/data/activity_database.dart`: `schemaVersion` is 2; `_migrate` creates `timer_sessions` (v1) and `completed_phases` (v2, `ON DELETE RESTRICT`). `PRAGMA foreign_keys = ON` is set in `onConfigure`.
- `lib/features/statistics/data/activity_access.dart`: reads are scoped to the current account (`_requireAccount`). After [DEV-01-01](../../../../epic-developer-tools/stories/story-01-purge-local-activity/task-01-purge-activity-storage/index.md) it has a purge epoch and `deleteAllActivity()`, which deletes `completed_phases` and then `timer_sessions` for all accounts.
- `lib/main.dart`: `main()` calls `configureDependencies()` and then `runApp`.
- Real-SQLite tests live in `test/features/statistics/data/activity_access_test.dart` (in-memory database, setup from DEV-01-01).

## Behavior

Schema (version 3, in `_migrate`, non-destructive):

- `ALTER TABLE timer_sessions ADD COLUMN checkpoint_at_utc_ms INTEGER` (null by default).
- `CREATE TABLE draft_phases` with the same columns and checks as `completed_phases`, except `session_id TEXT NOT NULL REFERENCES timer_sessions(id) ON DELETE CASCADE`. Keep `UNIQUE (session_id, schedule_position)`.
- A session has a draft when `ended_at_utc_ms IS NULL` and `checkpoint_at_utc_ms IS NOT NULL`. Old sessions have no checkpoint, so they are never recovered.

Repository (`ActivityRepository`, `ActivityAccess`, `SqfliteActivityRepository`):

- `Future<Result<void>> saveDraft({required ActivitySessionHandle session, required List<CompletedPhase> phases, required int checkpointAtUtcMs})`: one transaction. It verifies the handle like `addPhases` (phases from another session throw `StateError('Phase belongs to another session')`). A stale handle from before a purge writes nothing and returns normally, like the other handle writes. If the session already has an end, it writes nothing and returns normally. Otherwise it deletes the session's `draft_phases`, inserts `phases` (an empty list is allowed), and sets `checkpoint_at_utc_ms`. It does not emit on `changes`, because statistics do not read drafts.
- `finishRun` (from STAT-06-02) also deletes the session's `draft_phases` in its transaction.
- `Future<Result<void>> recoverUnfinishedRuns({required int startedBeforeUtcMs})`: works for all accounts, with no signed-in account needed (throws `StateError` only when the access is closed). It handles only sessions with a draft and `started_at_utc_ms < startedBeforeUtcMs`. Each session is recovered in its own transaction: insert its draft phases into `completed_phases` (same per-phase rule as `finishRun`), set `ended_at_utc_ms` to its `checkpoint_at_utc_ms`, delete its draft phases. If one session throws, only that session rolls back, the others are still tried, and the method then returns `Failure` with the first error. A session that failed keeps its draft and is tried again on the next start. It emits on `changes` once if at least one session was recovered. Each phase keeps its own stored local date.
- Statistics queries are not changed; they never read `draft_phases`.

Recorder:

- `_RecordingRun` saves a draft of `tracker.snapshot()` with `checkpointAtUtcMs` from `tracker.endInstant` at these moments:
  - **Periodic:** a `Timer.periodic(Duration(seconds: 10))` started in `begin`. It is cancelled in `pause`, started again (a fresh 10 s period) in `resume`, and cancelled for good when `tracker.isFinished` becomes true, in `end` and in `dispose`. Each firing saves a draft of the snapshot as of the last `reconcile`; the timer does not reconcile by itself.
  - **Phase change:** in `reconcile`, when at least one phase completed. This covers the finish.
  - **Pause:** in `pause`, after the tracker paused.
- No draft is saved:
  - when the snapshot is empty (for example during preparation);
  - when the snapshot and `endInstant` are equal to the last draft enqueued (for example the periodic timer firing with no new `reconcile`);
  - from `end`: `end` reconciles to its elapsed without enqueuing a draft, then enqueues only `finishRun`;
  - after the finish draft: once `tracker.isFinished` is true and its phase-change draft was enqueued, the periodic timer is cancelled and no further draft is saved.
- Drafts are enqueued after the session creation write, like every write, so they wait while the session is not created yet.
- **Queue rule:** drafts go through the same queue, but a draft can be superseded. When a new draft or the `finishRun` is enqueued, every draft in the queue that is not being written right now is removed first. This includes a failed draft at the head of a blocked queue: removing it cancels the retry timer, clears the blocked state, resets `_failedAttempts` to 0 and lets the queue drain at once. A draft that is being written right now is left to finish. If that draft then fails while anything is already waiting behind it, the failed draft is reported on `failures` and dropped at once (no block, no retry timer, `_failedAttempts` reset to 0), and the queue goes on draining. A failed draft with nothing behind it is reported on `failures`, stays at the head and counts toward the automatic retry limit until something is enqueued. Because a later draft or `finishRun` always removes a failed draft, a failing draft can never block `finishRun`.

Startup:

- In `lib/main.dart`, after `configureDependencies()`, start `getIt<ActivityRepository>().recoverUnfinishedRuns(startedBeforeUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch)` without awaiting it (`unawaited`), and log a `Failure` with `debugPrint`. `runApp` is not delayed.

## Decisions

- **Keep the draft safety net:** the user keeps the final save on leaving as the only normal save. The draft is used only after a kill.
- **Draft moments:** every 10 s while running, at each phase change (including finish) and on pause. No "app went to background" trigger, because the foreground service keeps ticks running and the recorder stays free of Flutter lifecycle code. Chosen by the user.
- **Separate `draft_phases` table with cascade delete:** chosen by the user. Deleting a session (the purge in DEV-01-01, or [Delete statistics](../../story-05-delete-statistics/index.md)) removes its draft, so deleted history cannot come back.
- **Recovered under the original account:** the draft's session already stores its `account_id`, so recovery does not depend on who is signed in.
- **Only sessions started before recovery began (planner choice):** so recovery never touches a workout started right after the app opens.

## Out of scope

- Restoring the timer screen or continuing the interrupted workout.
- Any Statistics UI change.
- Integration tests. The integration test setup does not exist yet.

## Files and tests

- Changed: `lib/features/statistics/data/activity_database.dart` (version 3), `lib/features/statistics/domain/activity_repository.dart`, `lib/features/statistics/data/activity_access.dart`, `lib/features/statistics/data/sqflite_activity_repository.dart`, `lib/features/timer/data/default_timer_activity_recorder.dart`, `lib/main.dart`.
- Only the `_Repository` fake in `test/features/timer/data/default_timer_activity_recorder_test.dart` needs `saveDraft` (recording each call) and `recoverUnfinishedRuns`. The other `ActivityRepository` fakes use `noSuchMethod` and need no change.
- `test/features/timer/data/default_timer_activity_recorder_test.dart`: draft moments with `fakeAsync` (drive the run by calling `reconcile`, `pause` and `resume` directly), the superseding rule, and a failed draft followed by a successful `finishRun`.
- `test/features/statistics/data/activity_access_test.dart`: `saveDraft`, `finishRun` removing drafts, recovery, account ownership, deletion and the version 2 to 3 upgrade. For the upgrade test only, use a temporary file (an in-memory database is lost when it closes): create a folder with `Directory.systemTemp.createTemp`, open a version 2 database there with `databaseFactory.openDatabase` and the version 2 SQL copied from `_migrate`, insert a session and phases, close it, then open the same path with `ActivityDatabase(databasePath: ...)`. Delete the folder with `addTearDown`. All other tests keep the in-memory database.
- In `notes.md`, also record a manual Android check: start a workout, kill the app from recents mid-round, reopen it and confirm Statistics.

## Acceptance

- [ ] When a run is active, then a draft is saved every 10 s while running, when a phase completes (including finish) and on pause, and no draft is saved while paused, from `end`, or after the finish draft. Check: `fvm flutter test test/features/timer/data/default_timer_activity_recorder_test.dart`.
- [ ] When a draft is waiting in the queue and a new draft or `finishRun` is enqueued, then the waiting draft is never written. Check: same test file.
- [ ] When the user leaves the timer page, then `finishRun` writes the final records and removes the session's draft in the same transaction. Check: `fvm flutter test test/features/statistics/data/activity_access_test.dart`.
- [ ] When the app starts and finds a draft, then `recoverUnfinishedRuns` saves its phases as completed phases, sets the session's end to `checkpoint_at_utc_ms`, and removes the draft. Check: same test file.
- [ ] When `recoverUnfinishedRuns` runs twice, then the second call changes nothing. Check: same test file.
- [ ] When the draft belongs to account B and account A is signed in, then it is saved under B and never appears in A's `readDailyActivity`. Check: same test file.
- [ ] When sessions with drafts are deleted (`deleteAllActivity`), then their draft rows are gone and recovery adds nothing back. Check: same test file.
- [ ] When a session with a draft has `started_at_utc_ms` equal to or later than `startedBeforeUtcMs`, then recovery leaves it alone. Check: same test file.
- [ ] When one session's draft conflicts with an existing completed phase and another session's draft is fine, then the good one is recovered, the bad one keeps its draft, and the call returns `Failure`. Check: same test file.
- [ ] When a version 2 database with history is opened, then it upgrades to version 3, keeps all sessions and phases, and has the `draft_phases` table. Check: same test file.
- [ ] When a draft save fails, whether `finishRun` was enqueued before or after the failure, then the failure is reported on `failures` and `finishRun` still runs without a manual retry. Check: `fvm flutter test test/features/timer/data/default_timer_activity_recorder_test.dart`.
- [ ] When the app starts, then `main.dart` starts recovery once after `configureDependencies()`. Check: `grep -n "recoverUnfinishedRuns" lib/main.dart`.
- [ ] When the whole suite runs, then it passes. Check: `fvm flutter test` and `fvm dart tool/agent_check.dart`.
