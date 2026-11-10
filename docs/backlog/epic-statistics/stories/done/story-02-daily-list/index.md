# STORY 2: Show daily statistics

Epic: [Statistics](../../../index.md)

## User outcome

As a person reviewing my training, I want one list tile per day combining all completed activity so that I can see how much I trained regardless of how often I restarted the timer.

## Scope

Replace the existing Statistics placeholder with account-scoped daily totals from the local database. This first screen is for viewing history only.

Each tile shows:

- Date.
- Number of completed work rounds.
- Combined work duration.
- Combined rest duration.
- Total duration: work plus rest.

Example: `31 October · 12 rounds · 24 min work · 6 min rest · 30 min total`.

The example illustrates content, not a fixed layout. Choose readable formatting within the existing app design, preserving seconds when needed and handling long durations without losing meaning.

## Tasks

1. [Add daily statistics loading/state](done/task-01-add-daily-statistics-state/index.md).
2. [Replace placeholder content with daily tiles](done/task-02-show-daily-tiles/index.md).
3. [Verify summaries and screen states](done/task-03-verify-daily-statistics/index.md).

## Acceptance criteria

- The Statistics section displays real persisted history instead of placeholder entries.
- Each recorded date appears exactly once, newest first, for the current account only.
- Several starts/stops on the same date combine into the same tile.
- Round count includes completed work phases only; work/rest totals include completed phases only.
- Total time equals work time plus rest time.
- Freshly committed activity appears without restarting the app.
- No-history and failed-load states are understandable, and retry can recover a failed load.
- Switching accounts removes the previous account's visible history.
- Opening day details, editing, deletion, charts, backup, and filters are outside this story.

## Dependencies

- [Story 1: Record completed activity](../story-01-record-activity/index.md).
- [Story 3: Day details](../story-03-day-details/index.md) may later make the tiles navigable; it must not block this daily-list release.
