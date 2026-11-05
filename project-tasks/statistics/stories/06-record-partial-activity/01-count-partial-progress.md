# TASK 6.1: Count partial progress in whole seconds

Story: [Record partial activity](index.md)

Epic: [Statistics](../../index.md)

Status: Ready for planning.

## Goal

The recording run keeps an in-memory view of the run that includes the phase in progress, using the agreed counting rules. Later tasks write this view to the database.

## Scope

- Track completed phases (full durations) and the current partial work or rest phase (whole seconds that actually ran, rounded down).
- Apply the 5-second round rule to a partial work phase. Preparation and paused time never count.
- Give each phase, including a partial one, a stable ID, schedule position, type, round number, logical completion instant, local date and UTC offset, so later writes can be retried with the same values.
- Excluded: any change to when or how data is written to the database (Tasks [6.2](02-save-on-leaving-timer.md) and [6.3](03-checkpoint-and-recover.md)).

## Dependencies

None inside this story. Uses the existing recorder and timer schedule.

## Acceptance criteria

- At any active elapsed time, the run reports completed phases plus the partial phase with whole seconds only. Example: 1:23.8 into a round reports 83 s.
- A partial work phase reports as a round only when it reaches 5 s.
- Elapsed time during preparation or a pause adds nothing. Several boundaries crossed by one late tick are all accounted for.
- The partial phase's completion instant excludes paused time and follows the same clock-correction rules as completed phases.

## Validation

Unit tests with a fake clock: partial work and rest, the 4 s / 5 s round edge, pause and resume, preparation, a late tick across several phases, the final round with no final rest, and a phase crossing local midnight.

## Implementation context

`lib/features/timer/data/default_timer_activity_recorder.dart` (`_RecordingRun.reconcile`), `lib/features/timer/domain/timer_activity_recorder.dart`, `lib/features/timer/domain/timer_schedule.dart` and `lib/features/statistics/domain/completed_phase.dart`. Pure counting logic belongs in the timer domain or data layer, following `CLAUDE.md`. Read the [story](index.md) for the agreed rules.
