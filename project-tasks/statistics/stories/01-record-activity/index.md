# STORY 1: Automatically record completed activity

Epic: [Statistics](../../index.md)

Status: Database foundation completed with iOS validation deferred; activity recording remains pending.

## User outcome

As a person training with the timer, I want every completed work round and rest saved automatically so that starting, pausing, or stopping the timer does not lose completed activity.

## Scope

Integrate local SQLite storage using `sqflite` and record completed activity for the account that owns each run. Prepare data for daily summaries and future run details. No statistics UI, cloud backup, backend deployment, or timer restoration is included.

## Storage model

Use application-generated UUIDs as text primary keys. Store UTC instants as integer epoch milliseconds and durations as integer milliseconds. A stable ID makes later synchronization possible but does not itself provide it.

### Timer run

- Run UUID and immutable Firebase UID captured at run start. Starting without an account fails closed; no shared anonymous owner is invented.
- Start timestamp in UTC and a snapshot of the original preparation, work and rest durations and configured round count.
- Nullable UTC end timestamp when reliably known.
- Paused time never contributes to activity totals. Pause metadata, end reason, timer style, and template identity are not stored in this version.
- Unknown termination must remain unknown; do not invent a completion time after a forced close.

### Completed phase

- Phase UUID, parent run UUID foreign key, and stable zero-based position in the generated schedule. Retain the same phase UUID across retries, including after an uncertain commit, or derive it deterministically from the run UUID and schedule position. The position counts preparation if present; zero-duration stages are omitted and do not consume a position. Preparation is never recorded.
- Phase type: work or rest, and one-based round number; a rest uses the number of the round just completed.
- Completed active duration, logical UTC completion instant, fixed local completion date (`YYYY-MM-DD`), and completion UTC offset in minutes east of UTC.
- A unique constraint on run UUID plus schedule position prevents duplicate recording. Enable SQLite foreign keys and retain history without cascading deletion.

Logical completion time means when the phase actually finished, excluding pauses, rather than when a delayed callback eventually wrote it. This distinction matters at midnight.

Index runs by account and phases by run and local date for owner-scoped daily queries. Aggregate completed phases by joining their runs, filtering the captured account, and grouping by stored local date. Use transactions for batches. An exact retry is idempotent; a conflicting duplicate must fail rather than replace history.

The repository hides SQLite, keeps pending writes tied to the run's original account, and scopes reads to the current account. Clear account-specific state on authentication changes. Capture the account or authentication generation when starting a read or subscription, and discard its result if authentication changes before delivery. After commits, explicitly refresh interested `ValueNotifier` state; `sqflite` does not supply query streams. Reconcile crossed boundaries on ticks, pauses, and exit, and drain ordered writes independently of the timer page. The existing background mechanism can allow progress while active; it cannot guarantee a write after process death.

## Tasks

1. [Choose local storage and define the data model](done/01-verify-serverpod-integration.md).
2. [Add the database foundation](done/02-add-database-foundation.md).
3. [Add the activity persistence interface](03-add-activity-repository.md).
4. [Connect recording to timer progress](04-connect-timer-recording.md).
5. [Verify persistence and timer integration](05-verify-recording.md).

## Acceptance criteria

- Each completed work/rest phase is committed once under its owning run and account.
- Stopping partway through the next phase preserves previous phases and adds no partial duration.
- Background progress and delayed updates account for every completed scheduled phase while the timer continues operating.
- Pausing adds no activity time and resuming creates no new run.
- A final work round is saved; no nonexistent final rest is recorded.
- Activity belongs to its logical local completion date and keeps that date after later timezone changes.
- Committed activity survives app restart. Forced-close recovery does not fabricate missing activity or restore the timer.
- Retrying an uncertain or failed save cannot double-count activity, and a failed transaction does not leave a partial batch.
- One account cannot read another account's history through the repository.
- Recording and querying work without connectivity or a deployed backend.
- The database can evolve through migrations without clearing training history.

## Dependencies and limits

This story precedes Story 2. A future backup design must address backend authentication, authorization, ownership mapping, retries, and conflict handling. The local database does not provide synchronization.
