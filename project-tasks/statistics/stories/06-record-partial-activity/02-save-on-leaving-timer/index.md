---
id: STAT-06-02
status: draft
type: feat
depends-on: [STAT-06-01]
---

# Save the run once when leaving the timer

Story: [Record partial activity](../index.md)

Epic: [Statistics](../../../index.md)

## Goal

Replace the write-at-every-completion behavior with a single final write of the whole run when the user leaves the timer page. Statistics then include partial time and follow the 5-second round rule.

## Scope

- Stop writing phases at each completion. Keep the run in memory until the timer page is left, then write the completed phases, the partial phase (if any), and the session end in one transaction.
- The same single write happens whether the timer finished, is running or is paused. Finishing the timer no longer writes by itself.
- Keep the existing retry queue behavior: the write runs independently of the disposed page and is retried with the same IDs and values.
- Update the schema (non-destructive migration) and the daily, day-details and chart queries so partial phases add their seconds and rounds follow the 5-second rule. Existing rows keep their current meaning.
- Excluded: draft checkpoints and recovery after a forced close (Task [6.3](../03-checkpoint-and-recover/index.md)).

## Dependencies

[Task 6.1](../01-count-partial-progress/index.md).

## Acceptance criteria

- Leaving partway through a phase saves earlier phases in full plus the partial phase's whole seconds. Leaving during preparation saves no phases, and the run does not appear in statistics.
- A finished timer is written once, on leaving, with no duplicate rows.
- A failed write leaves no partial batch. Retrying cannot double-count.
- Daily totals, round counts, chart data and day details include partial time and apply the 5-second round rule. Older history shows the same totals as before.
- The database upgrades from the current version without losing history.

## Validation

Unit tests for the recorder (leave while running, paused, finished, during preparation; write failure and retry). Real-SQLite tests for the migration, the transaction, and the updated aggregate queries with partial phases and the round rule. Run the existing statistics tests to confirm older history is unchanged.

## Implementation context

`lib/features/timer/data/default_timer_activity_recorder.dart`, `lib/features/timer/presentation/timer_view_model.dart` (`dispose` ends the run; `_tick` currently ends it on finish), `lib/features/statistics/domain/activity_repository.dart`, `lib/features/statistics/data/activity_database.dart` (schema version and `_migrate`) and `lib/features/statistics/data/activity_access.dart` (aggregate SQL). Decide the storage shape listed in the [story's open decisions](../index.md#dependencies-and-open-decisions) during planning.
