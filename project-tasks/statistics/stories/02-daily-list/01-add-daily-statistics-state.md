# TASK 2.1: Add daily statistics loading/state

Story: [Story 2 overview](index.md)

Epic: [Statistics](../../index.md)

Status: Not started.

## Dependencies

[Story 1: Record completed activity](../01-record-activity/index.md).

## Goal

Add daily statistics loading/state. Read the parent story for the shared behavior, exclusions, and acceptance criteria.

## Work and acceptance criteria

Each item below is a completion requirement for this task:

- Reuse the activity repository from Story 1 and follow existing state-management patterns.
- Load only the current account's records, grouped by the stored completion date and ordered newest first.
- Count work records as rounds; sum work and rest durations separately. Derive total from those two sums.
- Refresh when new completed activity is committed or when returning to Statistics; choose an approach supported by the approved storage integration.
- Clear displayed state on account changes so another account's history never remains visible.
- Represent loading, content, empty, and recoverable error states.

## Orchestration

Read the story and epic before starting. Inspect current code and propose small substeps for approval. Complete one approved file or concern per turn and wait for user validation before continuing. Include relevant tests and scoped checks with implementation; a later verification task does not defer required validation.
