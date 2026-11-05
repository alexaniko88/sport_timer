# TASK 6.3: Checkpoint the run and recover it after a forced close

Story: [Record partial activity](index.md)

Epic: [Statistics](../../index.md)

Status: Ready for planning. Depends on Task 6.2.

## Goal

If the OS kills the app during a workout, the next app start saves that run up to its last checkpoint, so only a few seconds are lost.

## Scope

- While a run is active, write a draft checkpoint of the in-memory run. Recommended moments: each phase change, the app going to the background, and every ~10 s while running (to confirm during planning).
- The draft keeps the owning account, the session, and the phase values from [Task 6.1](01-count-partial-progress.md), with stable IDs.
- On the final write from [Task 6.2](02-save-on-leaving-timer.md), the draft is replaced by final records in the same transaction.
- On the next app start, turn any leftover draft into final records under its original account. The end time and partial phase date come from the last checkpoint. Then remove the draft. Recovery is idempotent.
- Deleting statistics or the developer purge must also remove drafts for the affected account.
- Excluded: restoring the timer screen or continuing the interrupted workout.

## Dependencies

[Task 6.2](02-save-on-leaving-timer.md). Coordinate with [Delete statistics](../05-delete-statistics/index.md) and the developer purge in [developer tools](../../../developer-tools/index.md), whichever exists in the implementation checkout.

## Acceptance criteria

- Killing the app while a workout runs, then opening it again, adds the run's activity up to the last checkpoint to statistics, under the account that started it.
- Recovery never runs twice for the same draft and never duplicates rows already saved by a final write.
- A draft from another account is recovered under its own account and never appears in the current account's statistics.
- Statistics deleted or purged after a kill cannot come back through recovery.
- Checkpoints do not block the timer, its sounds or its ticks. A failed checkpoint is logged and retried at the next checkpoint moment.

## Validation

Unit tests for checkpoint moments and recovery with fakes. Real-SQLite tests for draft write, replacement by the final write, idempotent recovery, account ownership and deletion. Manual check on an Android device: start a workout, kill the app from recents, reopen and confirm statistics.

## Implementation context

`lib/features/timer/data/default_timer_activity_recorder.dart`, `lib/features/statistics/data/activity_database.dart`, `lib/features/statistics/data/sqflite_activity_repository.dart`, `lib/di/di.dart` and `lib/main.dart` (where recovery can start after dependencies are configured). The app-lifecycle signal for "went to background" must stay out of the domain layer, following `CLAUDE.md`. The existing `BackgroundKeepAlive` keeps the process alive while the timer runs, but it cannot prevent a kill.
