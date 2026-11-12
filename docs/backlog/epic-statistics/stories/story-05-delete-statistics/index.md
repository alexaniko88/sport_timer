# STORY 5: Delete statistics

Epic: [Statistics](../../index.md)

A signed-in user can delete all their recorded statistics on this device and keep recording new workouts.

## Scope

- In: a ⋮ menu in the Statistics app bar with "Delete statistics", a confirmation dialog, deletion of the signed-in account's local history (sessions, phases and drafts), feedback, and refreshed views.
- Out: deleting single days or runs, editing history, turning recording off, deleting on other devices, deleting other accounts' data (the all-accounts purge is the developer tools story).

## Requirements

- R1: The Statistics app bar has a ⋮ menu (before the avatar) with one item, "Delete statistics", only when there is activity to delete. With no activity, while loading or on error, there is no ⋮. The item is disabled while a delete runs — STAT-05-02.
- R2: The item opens a dialog that says all statistics of this account on this device will be deleted and cannot be undone. Cancel or dismiss changes nothing — STAT-05-02.
- R3: Confirming deletes every session, phase and draft of the signed-in account, also when there is none, then shows "Statistics deleted"; the list and charts refresh to their empty state — STAT-05-01, STAT-05-02.
- R4: A failure shows an error snackbar and never claims success; nothing is deleted — STAT-05-01, STAT-05-02.
- R5: Writes for that account issued before the delete (a session being created, a run being finished, a draft) write nothing afterwards and return success, so deleted history never comes back; recovery after a forced close restores nothing deleted. New workouts after the delete record normally — STAT-05-01.
- R6: Other accounts' data and their pending writes are untouched. If the signed-in account changes while the delete runs, nothing is deleted and it fails — STAT-05-01.
- R7: Texts in English and Spanish ("Eliminar"), screen reader labels, both themes, larger text — STAT-05-02.
- R8: With no activity at all, the Statistics screen shows only "No completed activity yet." centered, without the List/Charts switcher or chart controls — STAT-05-02.

## Mockup

[mockup.html](mockup.html), approved.

## Tasks

1. [Delete local statistics](task-01-delete-local-statistics/index.md)
2. [Add the delete action to Statistics](task-02-add-delete-action/index.md)

## Shared contracts

- `ActivityRepository.deleteAccountActivity()` — new in STAT-05-01: `Future<Result<void>> deleteAccountActivity();` deletes the signed-in account's local activity. `Failure` when there is no signed-in account, the account changed during the call, or the database fails. Used by `StatisticsViewModel.deleteStatistics()` in STAT-05-02.

## Dependencies

Runs after [Purge activity storage (DEV-01-01)](../../../epic-developer-tools/stories/story-01-purge-local-activity/task-01-purge-activity-storage/index.md) (global purge epoch, real-SQLite tests) and [Store drafts and recover unfinished runs (STAT-06-03)](../story-06-record-partial-activity/task-03-store-drafts-and-recover/index.md) (`finishRun`, `saveDraft`, `draft_phases` with cascade, recovery). Views refresh through `ActivityRepository.changes`. Visual references: [statistics](../../../../../test/snapshots/goldens/statistics.png), [empty](../../../../../test/snapshots/goldens/statistics_empty.png), [error](../../../../../test/snapshots/goldens/statistics_error.png).
