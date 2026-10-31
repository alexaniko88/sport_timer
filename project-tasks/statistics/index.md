# EPIC: Statistics

Status: Agreed scope; implementation not started.

Progress and reusable outputs: [Project task status](../status.md).

## Goal

Automatically preserve completed training activity and show daily totals in the existing Statistics section. Starting and stopping several times on one day contributes to the same daily totals.

## Stories

1. [Record completed activity](stories/01-record-activity/index.md): integrate the local database and reliably record completed work rounds and rests.
2. [Show daily statistics](stories/02-daily-list/index.md): replace the Statistics placeholder with daily totals.
3. [Explore a day's activity](stories/03-day-details/index.md): provisional future scope; revisit before implementation.

Implement Story 1 before Story 2. Story 3 depends on both, but is not required for the first version.

## Agreed behavior

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
- Keep recorded history. Editing and deletion controls are outside the first version.
- Show newest dates first. Do not show empty days or individual timestamps in the daily list.

## Storage decision

Use Serverpod's client-side SQLite database. This choice supports the user's intended direction toward a possible Serverpod backend and backup later.

- First release: on-device storage only, separated by account.
- Keep existing authentication; adopting Serverpod storage does not authorize replacing it.
- Preserve run identifiers, account ownership, original timer settings, completion timestamps, durations, and fixed local dates for later detail views and potential backup.
- Compute daily totals from completed records rather than maintaining a second independent source of totals.
- Use database transactions, uniqueness constraints, and non-destructive migrations.
- Verify the exact Serverpod version, SDK compatibility, generation workflow, and local-only integration before choosing packages or changing project structure.
- Automatic backup, backend deployment, cross-device synchronization, authentication integration for a backend, and conflict handling need separate future scope.
- At planning time, Serverpod 4 documents automatic offline sync as experimental and not production-ready. Local database adoption does not imply that backup is already available.

## Current app constraints

- Statistics currently contains placeholder content; no historical activity exists to import.
- The timer schedule defines preparation, work, and rest boundaries. There is no rest after the final round, and zero-duration phases are omitted.
- A late timer tick can cross multiple boundaries. Recording must reconcile every completed phase rather than only observing the displayed phase.
- Pauses exclude paused time. Leaving the timer disposes it; no active-run restoration exists.
- Existing persistent settings use SharedPreferences; there is no existing history database.

## Delivery rules

Each story has its own folder under `stories/`, with an `index.md` overview and numbered task files for orchestration. Before implementation, inspect current code, validate the proposed approach, and present small substeps for approval. Complete one approved file or concern per turn and wait for user validation before continuing.

No application code is changed by these planning files. Story 3 remains a proposal until its behavior and screen design are discussed.

## References

- [Serverpod client-side database](https://docs.serverpod.dev/concepts/data-and-the-database/database/client-side-database)
- [Serverpod offline sync status](https://docs.serverpod.dev/concepts/data-and-the-database/database/client-side-database#sync-tables-with-the-server)
