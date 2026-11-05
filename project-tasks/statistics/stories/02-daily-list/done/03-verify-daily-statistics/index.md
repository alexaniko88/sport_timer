---
id: STAT-02-03
status: done
type: feat
depends-on: [STAT-02-02]
---

# Verify summaries and screen states

Story: [Story 2 overview](../../index.md)

Epic: [Statistics](../../../../index.md)

## Dependencies

[Previous task](../02-show-daily-tiles/index.md).

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

## UI snapshot reference

Before planning, inspect the relevant current UI snapshots: [statistics](../../../../../../test/snapshots/goldens/statistics.png). See the [snapshot index](../../../../../../test/snapshots/README.md) for captured states, navigation and coverage limits. These are a baseline of the captured checkout, not an approved design for this task; check the implementation checkout and parent decisions for newer or intended behavior. The Statistics snapshot shows placeholder content, not the intended daily list. For visible changes, refresh affected snapshots and the index as described there, including new meaningful states or navigation changes.

## Completion evidence

Verified mixed settings and daily totals, date ordering, rest-only activity, live updates, account switching, and narrow layouts with larger text. Scoped analysis, the full Flutter suite (319 tests), and both activity integration test files on Android passed.
