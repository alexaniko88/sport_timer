# STORY 3: Explore a day's activity

Epic: [Statistics](../../index.md)

Status: Provisional future story. Discuss again before approving implementation.

## Proposed user outcome

As a person reviewing a training day, I want to tap its daily tile and see the separate timer runs so that runs with different round/rest settings are understandable.

Example: one day contains three runs with 5, 10, and 20 completed rounds, each using different work/rest durations.

## Preparation already covered by Story 1

- Stable run identifiers group completed phases.
- Original run settings preserve the configured durations and round count.
- Completed records preserve actual completed activity, timestamps, and assigned dates.
- Stopped runs retain completed phases; empty runs do not appear.

These records enable this story without committing to a particular screen design or collecting partial phases as completed activity.

## Decisions to revisit

- Dedicated screen, bottom sheet, or another presentation.
- Which run fields to display: completed versus configured rounds, work/rest durations, totals, termination information, and optional times.
- Whether users can expand a run into its individual completed phases.
- Ordering and labels for runs; session counts are not a primary statistic.
- How a run spanning midnight appears on both days. Day totals must remain based only on phases assigned to the selected date.
- Whether pause metadata is useful to display or remains internal.

## Proposed tasks

1. [Confirm day-detail behavior and layout](01-confirm-day-details.md).
2. [Query activity for a selected day](02-query-day-activity.md).
3. [Add navigation and the agreed detail view](03-show-day-details.md).
4. [Verify navigation and grouping](04-verify-day-details.md).

## Provisional acceptance criteria

- A day can be opened from its daily tile.
- Its completed activity is grouped by the original timer runs.
- Different work/rest configurations remain distinguishable.
- An unfinished final phase never appears as completed activity.
- A run spanning midnight cannot inflate either day's totals.
- The final layout and displayed fields require a new discussion before implementation.

## Dependencies and exclusions

Depends on [Story 1](../../stories/01-record-activity/index.md) and [Story 2](../../stories/02-daily-list/index.md).

Backup, cross-device sync, editing, deletion, and charts require separate scope unless explicitly agreed later.
