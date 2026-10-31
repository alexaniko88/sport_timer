# TASK 2.2: Replace placeholder content with daily tiles

Story: [Story 2 overview](index.md)

Epic: [Statistics](../../index.md)

Status: Not started.

## Dependencies

[Previous task](01-add-daily-statistics-state.md).

## Goal

Replace placeholder content with daily tiles. Read the parent story for the shared behavior, exclusions, and acceptance criteria.

## Work and acceptance criteria

Each item below is a completion requirement for this task:

- Render one tile for each date with completed activity across all its runs.
- Show the five agreed fields using accessible labels, readable date/duration formatting, and existing styling/localization conventions.
- Do not show individual timestamps, session counts, runs with no completed activity, or days without activity.
- Provide understandable empty and error messages and a retry action where appropriate.
- Keep the tiles non-navigating until Story 3 is approved and implemented.
- Support a long history using a lazy list and appropriate query behavior; do not add date filters or charts.

## Orchestration

Read the story and epic before starting. Inspect current code and propose small substeps for approval. Complete one approved file or concern per turn and wait for user validation before continuing. Include relevant tests and scoped checks with implementation; a later verification task does not defer required validation.
