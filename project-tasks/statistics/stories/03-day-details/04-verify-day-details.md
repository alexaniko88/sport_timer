# TASK 3.4: Verify navigation and grouping

Story: [Story 3 overview](index.md)

Epic: [Statistics](../../index.md)

## Dependencies

[Previous task](03-show-day-details.md).

## Goal

Verify navigation and grouping. Read the parent story for the shared behavior, exclusions, and acceptance criteria.

## Work and acceptance criteria

Each item below is a completion requirement for this task:

- Verify several runs with different settings, stopped runs, and a run spanning midnight.
- Verify selected-date totals agree with the daily tile and account isolation holds.
- Add only relevant tests for changed code and run required scoped checks.

## Orchestration

Read the story and epic before starting. Inspect current code and propose small substeps for approval. Complete one approved file or concern per turn and wait for user validation before continuing. Include relevant tests and scoped checks with implementation; a later verification task does not defer required validation.

## UI snapshot reference

Before planning, inspect the relevant current UI snapshots: [statistics](../../../../test/snapshots/goldens/statistics.png). See the [snapshot index](../../../../test/snapshots/README.md) for captured states, navigation and coverage limits. These are a baseline of the captured checkout, not an approved day-detail design; check the implementation checkout and agreed story behavior. For visible changes, refresh affected snapshots and the index as described there, including new meaningful states or navigation changes.
