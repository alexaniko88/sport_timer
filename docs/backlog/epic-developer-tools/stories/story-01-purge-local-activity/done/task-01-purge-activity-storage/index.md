---
id: DEV-01-01
status: done
type: feat
complexity: 9
depends-on: []
touches:
  - lib/features/statistics/domain/activity_repository.dart
  - lib/features/statistics/data/activity_access.dart
  - lib/features/statistics/data/sqflite_activity_repository.dart
  - test/features/statistics/data/activity_access_test.dart
  - test/features/statistics/fake_activity_repository.dart
  - test/features/statistics/presentation/statistics_view_model_test.dart
  - test/features/statistics/presentation/statistics_page_test.dart
  - test/features/statistics/presentation/day_details_view_model_test.dart
  - test/features/statistics/presentation/day_details_page_test.dart
  - test/features/timer/data/default_timer_activity_recorder_test.dart
  - test/snapshots/ui_snapshots_test.dart
  - pubspec.yaml
  - pubspec.lock
  - .github/workflows/ci.yml
skills: []
---

# Purge activity storage

Story: [Purge local activity](../../index.md)

Epic: [Developer tools](../../../../index.md)

## Goal

Add a storage operation that deletes all local activity (sessions and their phases) for every account on the device. Writes prepared before the purge never bring purged history back, and workouts after the purge record normally. Serves R2, R3 and R4. This task has no UI; the ViewModel in [Add the developer tools view model (DEV-01-02)](../../task-02-add-developer-tools-view-model/index.md) calls the operation.

## Context

- `lib/features/statistics/data/activity_database.dart` (`ActivityDatabase`, file `activity.db`) opens SQLite with `PRAGMA foreign_keys = ON`. Table `timer_sessions` holds sessions. Table `completed_phases` holds phases and references `timer_sessions(id)` with `ON DELETE RESTRICT`, so phases must be deleted before sessions. `ActivityDatabase({String? databasePath})` accepts a path, so tests can pass `inMemoryDatabasePath`.
- `lib/features/statistics/data/activity_access.dart` (`ActivityAccess`) does all reads and writes. Writes use capability objects it issues: private `_ActivitySessionCreation` (from `prepareSession`, implements the domain `ActivitySessionCreation`) and private `_ActivitySessionHandle` (from `createPreparedSession`, `createSession` and `openSession`, implements the domain `ActivitySessionHandle`). `addPhases` and `endSession` take a handle. It emits on `changes` through `_notifyChange()` after writes. `close()` sets `_closed`. Reads take `_generation` synchronously before their first `await`.
- `lib/features/statistics/data/sqflite_activity_repository.dart` (`SqfliteActivityRepository`) wraps `ActivityAccess` and turns exceptions and `StateError` into `Failure` through `_run`. `recordPhases` calls `ActivityAccess.addPhases`.
- `lib/features/statistics/domain/activity_repository.dart` is the `ActivityRepository` contract.
- `lib/features/timer/data/default_timer_activity_recorder.dart` keeps a queue of pending writes per run (`createPreparedSession`, then `recordPhases`, then `endSession`) and retries failures. A queued `createPreparedSession` that runs after a purge would insert the session row again; this task prevents that. The recorder itself does not change.
- `StatisticsViewModel` and `DayDetailsViewModel` already refresh when `ActivityRepository.changes` emits.
- There are no real-SQLite tests in `test/` today, and `sqflite_common_ffi` is not a dependency (`pubspec.yaml` has `sqflite: 2.4.5`). There is no `integration_test/` folder.
- `test/features/statistics/data/sqflite_activity_repository_test.dart` has the `FakeAccounts` (`ActivityAccountSource`) shape to copy.

## Contract

- `ActivityRepository.deleteAllActivity()` in `lib/features/statistics/domain/activity_repository.dart` — new here: `Future<Result<void>> deleteAllActivity();` with a short comment: it deletes every account's local activity, and writes prepared before the call are dropped. Used by `DeveloperToolsViewModel` in DEV-01-02.
- `SqfliteActivityRepository.deleteAllActivity()` — new here: delegates to `ActivityAccess.deleteAllActivity()` through `_run`, with no account check. A thrown error becomes `Failure`.
- `ActivityAccess.deleteAllActivity()` — new here: `Future<void> deleteAllActivity()`.
  - Throws `StateError('Activity access is closed')` when the access is closed. It needs no signed-in account.
  - Adds a private purge epoch counter `int _purgeEpoch = 0`, incremented synchronously at the start of the call, before any `await`. The epoch stays incremented even if the delete then fails, so writes queued before the attempt are always dropped.
  - In one `db.transaction`, runs `DELETE FROM completed_phases` and then `DELETE FROM timer_sessions`. If the transaction throws, SQLite rolls back, nothing is deleted and the error propagates.
  - After the transaction succeeds, emits on `changes` through `_notifyChange()`, also when the database was already empty.
  - Deletes only rows of these two tables. Settings (`SharedPreferences`) and authentication are not touched.
- Stale writes in `ActivityAccess` — new here:
  - `_ActivitySessionCreation` and `_ActivitySessionHandle` store the epoch at the moment they are issued. `prepareSession`, `createPreparedSession`, `createSession` and `openSession` read the epoch synchronously at the start, before any `await`, the same way reads take `_generation`. `openSession` reads it before its `db.query`, so a purge during the query yields a stale handle. `createPreparedSession` passes on the epoch of the creation it received.
  - `createPreparedSession` with a creation from an older epoch inserts nothing and returns a handle that carries that older epoch. `addPhases` and `endSession` with a handle from an older epoch write nothing and complete normally (no exception), so the repository returns `Success` and the recorder neither retries nor reports a failure.
  - The epoch comparison runs inside the write's `db.transaction` callback, because sqflite runs transactions one at a time. A write that ran before the purge transaction is simply deleted by it.
  - Stale writes do not emit on `changes`.
  - Creations and handles issued after `deleteAllActivity()` has completed carry the new epoch and work exactly as today.

## Decisions

- **Purge means purge:** anything queued before the purge is dropped silently and returns success, so nothing comes back and the recorder shows no failure. Chosen by the user.
- **Overlapping writes:** a creation or write issued while the purge call is still running (after the epoch bump, before the transaction) carries the new epoch and may still be removed by the purge transaction. This is accepted, because the purge is a developer action. Tests create post-purge data only after awaiting `deleteAllActivity()`, and no test relies on the overlapping case.
- **Not dependent on the delete statistics story:** this purge covers all accounts and is independent of the user-facing [Delete statistics story](../../../../../epic-statistics/stories/story-05-delete-statistics/index.md). Chosen by the user.
- **Real-SQLite unit tests with `sqflite_common_ffi`:** add it as a dev dependency, so the purge is tested against a real database with plain `flutter test`, locally and in CI, with no emulator and no integration tests. Chosen by the user.
- **In-memory test database:** every test opens `ActivityDatabase(databasePath: inMemoryDatabasePath)`, so nothing is written to disk, no test data is left behind and the tests stay fast. Chosen by the user over a temporary file.

## Out of scope

- The developer tools ViewModel (that is [Add the developer tools view model (DEV-01-02)](../../task-02-add-developer-tools-view-model/index.md)) and any UI, route or drawer change (that is [Add the developer page (DEV-01-03)](../../task-03-add-developer-page/index.md)).
- Account-scoped deletion (the delete statistics story), deleting single days or runs, deleting settings or signing out.
- Changing `DefaultTimerActivityRecorder`, the schema or the schema version.
- Adding an Android `integration_test/` suite.

## Files and tests

- New: `test/features/statistics/data/activity_access_test.dart` (unit tests on a real in-memory SQLite database).
  - `setUpAll`: `sqfliteFfiInit()` and `databaseFactory = databaseFactoryFfi`.
  - `setUp`: `ActivityDatabase(databasePath: inMemoryDatabasePath)` (`inMemoryDatabasePath` from `package:sqflite_common_ffi/sqflite_ffi.dart`), an `ActivityAccess` with a private hand-written fake `ActivityAccountSource` whose current account can be switched (like `FakeAccounts` in `test/features/statistics/data/sqflite_activity_repository_test.dart`), and a `SqfliteActivityRepository` on top of that access.
  - `tearDown`: close the access, then close the database, so the next test starts with a new empty in-memory database. No file is created.
  - Create data through the public `ActivityAccess` methods (`prepareSession`, `createPreparedSession`, `createSession`, `addPhases`, `endSession`). Check row counts with `SELECT COUNT(*)` on the database connection.
  - The case "deletes sessions and phases of every account" first asserts that both tables have 0 rows before it inserts anything.
- Test fakes: every fake that implements `ActivityRepository` gets a `deleteAllActivity()` that returns `const Success(null)`: `FakeEmptyActivityRepository` in `test/features/statistics/fake_activity_repository.dart`, and the private fakes in `test/features/statistics/presentation/statistics_view_model_test.dart`, `test/features/statistics/presentation/statistics_page_test.dart`, `test/features/statistics/presentation/day_details_view_model_test.dart`, `test/features/statistics/presentation/day_details_page_test.dart`, `test/features/timer/data/default_timer_activity_recorder_test.dart` and `test/snapshots/ui_snapshots_test.dart`.
- `pubspec.yaml` and `pubspec.lock`: add `sqflite_common_ffi` under `dev_dependencies`, pinned to the exact version `fvm flutter pub add --dev sqflite_common_ffi` resolves, written without `^` like every other entry.
- `.github/workflows/ci.yml`: add exactly one step, `- run: sudo apt-get update && sudo apt-get install -y libsqlite3-dev`, directly before `- run: flutter test`. `sqflite_common_ffi` loads the system SQLite library on Linux, and this step makes sure it exists on `ubuntu-latest`. Change nothing else in the file. No allowed check covers this file; the reviewer checks it in the diff.

## Acceptance

- [x] Given sessions and phases exist for two accounts, when `SqfliteActivityRepository.deleteAllActivity()` runs, then `timer_sessions` and `completed_phases` are both empty and it returns `Success`. Check: `test/features/statistics/data/activity_access_test.dart` "deletes sessions and phases of every account".
- [x] When a test starts, then its database is empty even if an earlier test inserted rows. Check: `test/features/statistics/data/activity_access_test.dart` "deletes sessions and phases of every account".
- [x] When the database is already empty and `deleteAllActivity()` runs, then it returns `Success`. Check: `test/features/statistics/data/activity_access_test.dart` "purges an empty database".
- [x] When `deleteAllActivity()` succeeds, then `changes` emits. Check: `test/features/statistics/data/activity_access_test.dart` "emits a change after a purge".
- [x] When the access is closed and `SqfliteActivityRepository.deleteAllActivity()` runs, then it returns `Failure` and the existing rows are still in the database. Check: `test/features/statistics/data/activity_access_test.dart` "returns a failure when the access is closed".
- [x] Given a creation from `prepareSession` was issued before the purge, when `createPreparedSession` runs after it, then no session row is inserted and the call succeeds, and `addPhases` and `endSession` with the returned handle also succeed and insert nothing. Check: `test/features/statistics/data/activity_access_test.dart` "drops a session prepared before the purge".
- [x] Given a handle was created before the purge, when `addPhases` or `endSession` runs after it, then nothing is inserted or updated, the call succeeds and `changes` does not emit. Check: `test/features/statistics/data/activity_access_test.dart` "drops writes through a handle from before the purge".
- [x] When a new session is created after the purge and phases are added, then they are stored and appear in `readDailyActivity()` for that account. Check: `test/features/statistics/data/activity_access_test.dart` "records new activity after the purge".
- [x] When the checks run, then they pass with the new fakes and the new dev dependency. Check: `fvm dart tool/agent_check.dart --skip-build`.
