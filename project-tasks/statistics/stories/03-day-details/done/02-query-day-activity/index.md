---
id: STAT-03-02
status: done
type: feat
depends-on: [STAT-03-01]
---

# Query activity for a selected day

Story: [Story 3 overview](../../index.md)

Epic: [Statistics](../../../../index.md)

## Dependencies

[Previous task](../01-confirm-day-details/index.md).

## Goal

Query activity for a selected day. Read the parent story for the shared behavior, exclusions, and acceptance criteria.

## Work and acceptance criteria

Each item below is a completion requirement for this task:

- Use the account-scoped repository to obtain the selected date's completed phases grouped by run.
- Include the original work and rest durations and configured round count.
- Keep selected-day values separate from whole-run values when a run crosses midnight.

## Orchestration

Read the story and epic before starting. Inspect current code and propose small substeps for approval. Complete one approved file or concern per turn and wait for user validation before continuing. Include relevant tests and scoped checks with implementation; a later verification task does not defer required validation.

## Completion evidence

- Implemented an account-scoped selected-day query grouped by run, preserving original settings and separating phases by their stored completion date.
- Focused repository tests passed (8); the full Flutter test suite passed (396); formatting and scoped analysis passed. SQLite integration coverage was added but could not run because no Android device was available.
- Review passed without findings. Completed on `feat/query-day-activity`; merge is pending.
