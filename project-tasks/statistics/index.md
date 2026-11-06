---
abbr: STAT
---

# EPIC: Statistics


## Goal

Automatically preserve completed training activity and show daily totals in the existing Statistics section. Starting and stopping several times on one day contributes to the same daily totals.

## Stories

1. [Record completed activity](stories/01-record-activity/index.md): integrate the local database and reliably record completed work rounds and rests.
2. [Show daily statistics](stories/02-daily-list/index.md): replace the Statistics placeholder with daily totals.
3. [Explore a day's activity](stories/03-day-details/index.md): completed on the day-details branch; merge pending.
4. [Visualize activity](stories/04-visualize-activity/index.md): completed on the consistency calendar branch; merge pending.
5. [Delete statistics](stories/05-delete-statistics/index.md): clear the signed-in account's local history; ready for planning.
6. [Record partial activity](stories/06-record-partial-activity/index.md): count the seconds actually trained, save once when leaving the timer, and recover after a forced close.

Stories 1 and 2 provide the foundation for Stories 3 and 4. Story 4 does not depend on the day-details story.

## Agreed behavior

> Story 6 replaces the rules below about unfinished phases, saving at each completion, and forced closes. Until Story 6 is done, the rules below describe the current app.

- A fresh timer start creates a run. Pause/resume continues that run.
- A completed work round increments the round count and contributes its duration to work time.
- A completed rest contributes its duration to rest time.
- Total time is completed work time plus completed rest time.
- Preparation, pauses, and unfinished phases do not contribute to these totals.
- Save activity at each work/rest completion, including while the timer operates in the background.
- Stopping preserves completed activity and discards the unfinished phase from statistics.
- A forced close preserves committed records. Restoring the interrupted timer or reconstructing unsaved progress after process death is outside this version.
- Each completed phase belongs to its local finish date, even when the phase started before midnight.
- Store that date and completion offset explicitly. Later timezone changes must not regroup historical activity.
- Each day combines activity from all runs for the signed-in account on this device.
- Runs without completed activity do not appear in statistics.
- Keep recorded history by default. Deletion is covered by Story 5; editing remains outside the agreed scope.
- Show newest dates first. Do not show empty days or individual timestamps in the daily list.

## Storage decision

Use SQLite through `sqflite` for local storage. Keep database access behind an activity repository so timer and statistics logic can be reused if synchronization is added later.

- First release: on-device storage only, separated by account.
- Keep existing Firebase authentication and capture the account at the start of each run.
- Preserve run identifiers, account ownership, original timer settings, completion timestamps, durations, and fixed local dates for later detail views and potential backup.
- Compute daily totals from completed records rather than maintaining a second independent source of totals.
- Use database transactions, uniqueness constraints, and non-destructive migrations.
- Resolve and pin compatible versions when the database foundation is implemented; no Serverpod generator or runtime backend is required.
- Automatic backup, backend deployment, cross-device synchronization, authentication integration for a backend, and conflict handling need separate future scope. Serverpod remains one possible future backend, not a commitment.

## Current app constraints

- Statistics shows account-scoped daily activity stored on this device; it has no chart or period selector yet.
- The timer schedule defines preparation, work, and rest boundaries. There is no rest after the final round, and zero-duration phases are omitted.
- A late timer tick can cross multiple boundaries. Recording must reconcile every completed phase rather than only observing the displayed phase.
- Pauses exclude paused time. Leaving the timer disposes it; no active-run restoration exists.
- Activity history is stored in the local SQLite database; existing settings use SharedPreferences.

## Delivery rules

Each story has its own folder under `stories/`, with an `index.md` overview and numbered task files for orchestration. Before implementation, inspect the current checkout and follow the repository’s current orchestration workflow.

No application code is changed by these planning files.

## References

- [sqflite package](https://pub.dev/packages/sqflite)
- [Flutter SQLite guide](https://docs.flutter.dev/cookbook/persistence/sqlite)
