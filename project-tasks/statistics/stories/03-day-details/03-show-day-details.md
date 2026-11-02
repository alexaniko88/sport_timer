# TASK 3.3: Add navigation and the agreed detail view

Story: [Story 3 overview](index.md)

Epic: [Statistics](../../index.md)

Status: Provisional; refine before implementation.

## Dependencies

[Previous task](02-query-day-activity.md).

## Goal

Add navigation and the agreed detail view. Read the parent story for the shared behavior, exclusions, and acceptance criteria.

## Work and acceptance criteria

Each item below is a completion requirement for this task:

- Open details from a daily tile and show the agreed run information.
- Handle loading, empty/missing data, errors, and account changes according to app patterns.
- Keep the parent day's summary consistent with the activity displayed.
- Scope and screen behavior are confirmed through the first task before implementation proceeds.

## Orchestration

Read the story and epic before starting. Inspect current code and propose small substeps for approval. Complete one approved file or concern per turn and wait for user validation before continuing. Include relevant tests and scoped checks with implementation; a later verification task does not defer required validation.

## UI snapshot reference

Before planning, inspect the relevant current UI snapshots: [statistics](../../../../test/snapshots/goldens/statistics.png), [templates_selected](../../../../test/snapshots/goldens/templates_selected.png). See the [snapshot index](../../../../test/snapshots/README.md) for captured states, navigation and coverage limits. These are a baseline of the captured checkout, not an approved design for this task; check the implementation checkout and parent decisions for newer or intended behavior. The Statistics snapshot is a placeholder, not a day-detail design; inspect the completed daily list when available. For visible changes, refresh affected snapshots and the index as described there, including new meaningful states or navigation changes.
