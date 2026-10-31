# TASK 3.2: Query activity for a selected day

Story: [Story 3 overview](index.md)

Epic: [Statistics](../../index.md)

Status: Provisional; refine before implementation.

## Dependencies

[Previous task](01-confirm-day-details.md).

## Goal

Query activity for a selected day. Read the parent story for the shared behavior, exclusions, and acceptance criteria.

## Work and acceptance criteria

Each item below is a completion requirement for this task:

- Use the account-scoped repository to obtain the selected date's completed phases grouped by run.
- Include original configuration and reliably known lifecycle metadata where needed.
- Keep selected-day values separate from whole-run values when a run crosses midnight.
- Scope and screen behavior are confirmed through the first task before implementation proceeds.

## Orchestration

Read the story and epic before starting. Inspect current code and propose small substeps for approval. Complete one approved file or concern per turn and wait for user validation before continuing. Include relevant tests and scoped checks with implementation; a later verification task does not defer required validation.
