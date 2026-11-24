# STORY 3: Explore a day's activity

Epic: [Statistics](../../../index.md)

## User outcome

As a person reviewing a training day, I want to tap its daily tile and see the separate timer runs so that runs with different round/rest settings are understandable.

Example: one day contains three runs with 5, 10, and 20 completed rounds, each using different work/rest durations.

## Preparation already covered by Story 1

- Stable run identifiers group completed phases.
- Original run settings preserve the configured durations and round count.
- Completed records preserve actual completed activity, timestamps, and assigned dates.
- Stopped runs retain completed phases; empty runs do not appear.

These records enable this story without collecting partial phases as completed activity.

## Agreed behavior

- Tapping a daily tile opens a dedicated page showing the selected date and its daily totals.
- Show one card per run, newest first. Each card shows completed rounds, work, rest and total for the selected day, alongside the original configured work duration, rest duration and round count. Distinguish selected-day activity from the whole-run configuration.
- A run spanning midnight appears on each day with completed activity, but each day's values include only phases assigned to that date.
- Do not expand individual phases or display pause details for now. Do not label a run stopped or completed unless the stored data supports that conclusion reliably.
- This is the agreed initial scope; the layout can be revisited later.

## Tasks

1. [Confirm day-detail behavior and layout](done/task-01-confirm-day-details/index.md).
2. [Query activity for a selected day](done/task-02-query-day-activity/index.md).
3. [Add navigation and the agreed detail view](done/task-03-show-day-details/index.md).
4. [Verify navigation and grouping](done/task-04-verify-day-details/index.md).

## Acceptance criteria

- A day can be opened from its daily tile on a dedicated page showing the selected date and its daily totals.
- Its completed activity is grouped by the original timer runs.
- Run cards appear newest first and show selected-day completed rounds, work, rest and total alongside the original work/rest durations and configured rounds.
- Selected-day activity is distinguishable from the original run configuration, so different configurations remain understandable.
- An unfinished final phase never appears as completed activity.
- A run spanning midnight appears on each day with completed activity, and neither day's totals include phases assigned to the other day.
- Individual phase expansion and pause details are excluded for now; termination labels are shown only if reliably supported.

## Dependencies and exclusions

Depends on [Story 1](../story-01-record-activity/index.md) and [Story 2](../story-02-daily-list/index.md).

Backup, cross-device sync, editing, deletion, and charts require separate scope unless explicitly agreed later.
