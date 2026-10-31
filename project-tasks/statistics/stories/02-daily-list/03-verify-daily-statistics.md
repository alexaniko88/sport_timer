# TASK 2.3: Verify summaries and screen states

Story: [Story 2 overview](index.md)

Epic: [Statistics](../../index.md)

Status: Not started.

## Dependencies

[Previous task](02-show-daily-tiles.md).

## Goal

Verify summaries and screen states. Read the parent story for the shared behavior, exclusions, and acceptance criteria.

## Work and acceptance criteria

Each item below is a completion requirement for this task:

- Follow nearby test conventions and focus on changed aggregation/state/UI behavior.
- Verify several runs with different settings combine into one date with correct totals.
- Verify different dates remain separate, sorting is correct, and rest-only activity contributes no completed work rounds.
- Verify incomplete phases, preparation, and pauses do not change totals.
- Verify loading, empty, error/retry, newly saved activity, and account switching.
- Check the tile remains readable with long dates, long durations, and larger text.
- Run required format/analyze checks and relevant tests for changed files.

## Orchestration

Read the story and epic before starting. Inspect current code and propose small substeps for approval. Complete one approved file or concern per turn and wait for user validation before continuing. Include relevant tests and scoped checks with implementation; a later verification task does not defer required validation.
