---
id: DEV-01-01
status: ready
type: feat
complexity: 9
depends-on: []
touches:
  - lib/features/statistics/domain/activity_repository.dart
  - lib/features/statistics/data/activity_access.dart
  - lib/features/statistics/data/sqflite_activity_repository.dart
  - test/features/statistics/**
  - test/features/timer/data/default_timer_activity_recorder_test.dart
  - test/snapshots/ui_snapshots_test.dart
  - pubspec.yaml
  - pubspec.lock
  - .github/workflows/ci.yml
skills: []
---

# Purge activity storage

Story: [Purge local activity](../index.md)

Epic: [Developer tools](../../../index.md)

## Goal

Add a storage operation that deletes all local activity (sessions and their phases) for every account on the device. Writes that were prepared before the purge must never bring purged history back, and new workouts after the purge must record normally. The developer page in [DEV-01-02](../task-02-add-developer-page/index.md) calls this operation; this task has no UI.

## Context

- Story: [Purge local activity](../index.md). Epic: [Developer tools](../../../index.md).
- Activity is stored in SQLite by `lib/features/statistics/data/activity_database.dart` (file `activity.db`). Table `timer_sessions` holds sessions; table `completed_phases` holds phases and references `timer_sessions(id)` with `ON DELETE RESTRICT`, and `PRAGMA foreign_keys = ON` is set. So phases must be deleted before sessions.
- `lib/features/statistics/data/activity_access.dart` (`ActivityAccess`) does all reads and writes. Writes use capability objects it issues: `_ActivitySessionCreation` (from `prepareSession`) and `_ActivitySessionHandle` (from `createPreparedSession`, `createSession`, `openSession`). `addPhases` and `endSession` take a handle. It emits on `changes` after writes, and `close()` sets `_closed`.
- `lib/features/statistics/data/sqflite_activity_repository.dart` (`SqfliteActivityRepository`) wraps `ActivityAccess` and turns exceptions and `StateError` into `Failure` through `_run`.
- `lib/features/statistics/domain/activity_repository.dart` is the `ActivityRepository` contract.
- `lib/features/timer/data/default_timer_activity_recorder.dart` keeps a queue of pending writes per run (`createPreparedSession`, then `recordPhases`, then `endSession`) and retries failures. A queued `createPreparedSession` that runs after a purge would insert the session row again, which is the bug this task prevents. The recorder itself does not change.
- `StatisticsViewModel` and `DayDetailsViewModel` already refresh when `ActivityRepository.changes` emits.
- There are no real-SQLite tests in `test/` today, and `sqflite_common_ffi` is not a dependency. The old Android `integration_test/` files were removed in commit `b53811b`.

## Behavior

- New contract method on `ActivityRepository`: `Future<Result<void>> deleteAllActivity();` with a short comment: it deletes every account's local activity, and writes prepared before the call are dropped.
- `SqfliteActivityRepository.deleteAllActivity()` delegates to `ActivityAccess.deleteAllActivity()` through `_run` (no account check).
- `ActivityAccess.deleteAllActivity()`:
  - Throws `StateError('Activity access is closed')` when the access is closed. It does not need a signed-in account; it deletes all accounts.
  - Adds a private purge epoch counter (`int _purgeEpoch = 0`). It increments the epoch synchronously at the start of the call, before any `await`. The epoch stays incremented even if the delete then fails, so writes queued before the attempt are always dropped.
  - In one `db.transaction`, runs `DELETE FROM completed_phases` and then `DELETE FROM timer_sessions`. If the transaction throws, nothing is deleted (SQLite rollback) and the error propagates.
  - After the transaction succeeds, emits on `changes` (through `_notifyChange`). It works on an empty database and still emits.
- Stale writes:
  - `_ActivitySessionCreation` and `_ActivitySessionHandle` store the epoch at the moment they are issued (`prepareSession`, `createPreparedSession`, `createSession`, `openSession`). Read the epoch synchronously at the start of each of these methods, before any `await`, the same way `_generation` is read today. `openSession` reads it before its `db.query`, so a purge that runs during the query yields a stale handle whose writes are dropped. `createPreparedSession` passes on the epoch of the creation it received.
  - `createPreparedSession` with a creation from an older epoch inserts nothing and returns a handle that carries that older epoch. `addPhases` and `endSession` with a handle from an older epoch write nothing and complete normally (no exception), so the repository returns `Success` and the recorder does not retry or report a failure.
  - The epoch comparison is done inside the write's `db.transaction` callback, because sqflite runs transactions one at a time; a write that already ran before the purge transaction is simply deleted by it.
  - Stale writes do not emit on `changes`.
- Creations and handles issued after `deleteAllActivity()` has completed carry the new epoch and work exactly as today. A creation or write issued while the purge call is still running (after the epoch bump, before the transaction) carries the new epoch and may still be removed by the purge transaction; that is accepted, because the purge is a developer action and nothing guarantees writes that overlap it. Tests create post-purge data only after awaiting `deleteAllActivity()`, and no test relies on the overlapping case.
- Settings (`SharedPreferences`) and authentication are not touched: the purge only deletes rows in the two activity tables.

## Decisions

- **Purge means purge:** anything queued before the purge is dropped silently and returns success, so nothing comes back and the recorder shows no failure. Chosen by the user.
- **Not dependent on STAT-05:** this purge is all-accounts and independent of the user-facing [delete statistics story](../../../../epic-statistics/stories/story-05-delete-statistics/index.md). Chosen by the user.
- **Real-SQLite unit tests with `sqflite_common_ffi`:** add it as a dev dependency so the purge is tested against a real database with plain `fvm flutter test`, locally and in CI, with no emulator and no integration tests. Chosen by the user.
- **In-memory test database:** every test opens `ActivityDatabase(databasePath: inMemoryDatabasePath)`, so nothing is written to disk and no test data is left behind, and the tests stay fast. Chosen by the user over a temporary file.

## Out of scope

- Any UI, route or drawer change (that is [DEV-01-02](../task-02-add-developer-page/index.md)).
- Account-scoped deletion (STAT-05), deleting single days or runs, deleting settings or signing out.
- Changing `DefaultTimerActivityRecorder`, the schema or the schema version.
- Rebuilding the Android `integration_test/` suite.

## Files and tests

Changed:

- `lib/features/statistics/domain/activity_repository.dart`: add `deleteAllActivity()`.
- `lib/features/statistics/data/activity_access.dart`: purge epoch, `deleteAllActivity()`, epoch in creations and handles, stale-write checks.
- `lib/features/statistics/data/sqflite_activity_repository.dart`: implement `deleteAllActivity()`.
- Every test fake that implements `ActivityRepository` gets a `deleteAllActivity()` that returns `const Success(null)`: `test/features/statistics/fake_activity_repository.dart`, `test/features/statistics/presentation/statistics_view_model_test.dart`, `test/features/statistics/presentation/statistics_page_test.dart`, `test/features/statistics/presentation/day_details_view_model_test.dart`, `test/features/statistics/presentation/day_details_page_test.dart`, `test/features/timer/data/default_timer_activity_recorder_test.dart`, `test/snapshots/ui_snapshots_test.dart`.
- `pubspec.yaml` and `pubspec.lock`: add `sqflite_common_ffi` under `dev_dependencies`, pinned to the exact version `fvm flutter pub add --dev sqflite_common_ffi` resolves, written without `^` like every other entry.
- `.github/workflows/ci.yml`: always add one step, `- run: sudo apt-get update && sudo apt-get install -y libsqlite3-dev`, right before `- run: flutter test`. `sqflite_common_ffi` loads the system SQLite library on Linux, and the step makes sure it is there on `ubuntu-latest`. Change nothing else in the file.

New test `test/features/statistics/data/activity_access_test.dart`:

- `setUpAll`: `sqfliteFfiInit()` and `databaseFactory = databaseFactoryFfi`.
- `setUp`: `ActivityDatabase(databasePath: inMemoryDatabasePath)` (`inMemoryDatabasePath` comes from `package:sqflite_common_ffi/sqflite_ffi.dart`) and an `ActivityAccess` with a hand-written fake `ActivityAccountSource` whose current account can be switched (like `FakeAccounts` in `test/features/statistics/data/sqflite_activity_repository_test.dart`).
- `tearDown`: close the access, then close the database, so the next test starts with a new empty in-memory database. No file is created.
- Data is created through the public `ActivityAccess` methods (`createSession`, `addPhases`, `endSession`); row counts are checked with `SELECT COUNT(*)` on the database connection.
- The `Failure` mapping for a closed access is checked through `SqfliteActivityRepository` on top of the same real database.

## Acceptance

- [ ] When sessions and phases exist for two accounts and `deleteAllActivity()` runs, then `timer_sessions` and `completed_phases` are both empty and the repository returns `Success`. Check: `fvm flutter test test/features/statistics/data/activity_access_test.dart`.
- [ ] When the database is already empty and `deleteAllActivity()` runs, then it returns `Success`. Check: same test file.
- [ ] When `deleteAllActivity()` succeeds, then `changes` emits. Check: same test file.
- [ ] When the access is closed and `SqfliteActivityRepository.deleteAllActivity()` runs, then it returns `Failure` and the existing rows are still in the database. Check: same test file.
- [ ] When a creation from `prepareSession` was issued before the purge and `createPreparedSession` runs after it, then no session row is inserted, the call succeeds, and `addPhases` and `endSession` with the returned handle also succeed and insert nothing. Check: same test file.
- [ ] When a handle was created before the purge and `addPhases` or `endSession` runs after it, then nothing is inserted or updated and the call succeeds. Check: same test file.
- [ ] When a new session is created after the purge and phases are added, then they are stored and appear in `readDailyActivity()` for that account. Check: same test file.
- [ ] When a test starts, then its database is empty even if an earlier test inserted rows. Check: a first assertion in the multi-account test that both tables have 0 rows before inserting, in the same test file.
- [ ] When the whole suite runs, then it passes with the new fakes. Check: `fvm flutter test` and `fvm dart tool/agent_check.dart`.
- [ ] When CI runs, then the SQLite install step runs before `flutter test`. Check: `.github/workflows/ci.yml` contains the step from Files and tests, directly before `- run: flutter test`.
