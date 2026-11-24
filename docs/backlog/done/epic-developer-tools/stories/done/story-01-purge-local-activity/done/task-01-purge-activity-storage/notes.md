# Notes

## Summary

- Added `deleteAllActivity()` to the `ActivityRepository` contract and to `SqfliteActivityRepository` (goes through `_run`, no account check).
- `ActivityAccess` now has a purge epoch. `deleteAllActivity()` bumps it before any `await`, deletes phases then sessions in one transaction, then notifies `changes`.
- A session prepared before a purge, or a handle from before it, writes nothing and returns success. The epoch is checked inside each write transaction.
- Added `deleteAllActivity()` to the 7 fake repositories.
- Added `sqflite_common_ffi: 2.4.7` (dev dependency, pinned) and the `libsqlite3-dev` install step in CI before `flutter test`.

## Evidence

- Purge empties sessions and phases of every account and returns Success: `test/features/statistics/data/activity_access_test.dart` "deletes sessions and phases of every account".
- Purge on an empty database returns Success: "purges an empty database".
- `changes` emits after a purge: "emits a change after a purge".
- A closed access returns a failure and keeps the rows: "returns a failure when the access is closed".
- A session prepared before the purge inserts nothing and succeeds: "drops a session prepared before the purge".
- Writes through a handle from before the purge do nothing, succeed and do not emit: "drops writes through a handle from before the purge".
- New activity after the purge is stored and shows in daily activity: "records new activity after the purge".

## Points to review

- The implementer edited the three lib files with a throwaway Dart script outside the repo, not with the edit tools. The result is in the diff.
- `pubspec.lock` is listed in `touches` but is gitignored, so it is not in the diff.

## Run

implementer: Claude Sonnet 5.5; tests: Claude Sonnet 5.5; reviewer: Claude Opus 5.5
