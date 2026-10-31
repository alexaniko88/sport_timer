# STORY 1: Automatically record completed activity

Epic: [Statistics](../../index.md)

Status: Ready for implementation planning, subject to the integration decisions in Task 1.

## User outcome

As a person training with the timer, I want every completed work round and rest saved automatically so that starting, pausing, or stopping the timer does not lose completed activity.

## Scope

Integrate Serverpod's local SQLite storage and record completed activity for the account that owns each run. Prepare data for daily summaries and future run details. No statistics UI, cloud backup, backend deployment, or timer restoration is included.

## Proposed records

Finalize names and types during planning; preserve these meanings:

### Timer run

- Stable unique run identifier and owning account identifier.
- Start timestamp in UTC.
- Snapshot of the original timer configuration, including preparation, work/rest durations, and configured round count.
- End timestamp and end reason when reliably known, such as completed or stopped.
- Useful pause/resume metadata where reliably observable; agree its minimal representation during planning. Paused time never contributes to activity totals.
- Unknown termination must remain unknown; do not invent a completion time after a forced close.

### Completed phase

- Parent run identifier and stable phase position within its schedule.
- Phase type: work or rest; retain round position where useful for future details.
- Completed active duration in an integer unit, chosen consistently for storage and aggregation.
- Logical completion timestamp in UTC, local completion date, and UTC offset at completion.
- A unique constraint on run identifier plus phase position to prevent duplicate recording.

Logical completion time means when the phase actually finished, excluding pauses, rather than when a delayed callback eventually wrote it. This distinction matters at midnight.

## Tasks

1. [Verify Serverpod local integration and approve the data model](01-verify-serverpod-integration.md).
2. [Add the database foundation](02-add-database-foundation.md).
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
- Recording and querying work without connectivity or a deployed Serverpod backend.
- The database can evolve through migrations without clearing training history.

## Dependencies and limits

This story precedes Story 2. A future backup design must revisit backend authentication, authorization, ownership mapping, sync maturity, and conflict handling. A Serverpod client database alone provides none of those product guarantees.
