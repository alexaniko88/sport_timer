# TASK 1.5: Verify persistence and timer integration

Story: [Story 1 overview](index.md)

Epic: [Statistics](../../index.md)

Status: Not started.

## Dependencies

[Previous task](04-connect-timer-recording.md).

## Goal

Verify persistence and timer integration. Read the parent story for the shared behavior, exclusions, and acceptance criteria.

## Work and acceptance criteria

Each item below is a completion requirement for this task:

- Add focused tests following existing test conventions; inspect changed methods before selecting cases.
- Verify uniqueness, account isolation, aggregate accuracy, atomic writes, failure/retry behavior, and reopening stored data.
- Verify a normal run, early stop, pause/resume, several crossed boundaries, final-round completion, and leaving near a completion boundary.
- Verify midnight attribution, including a callback delayed until the following day and paused time spanning midnight.
- Verify database migrations with the chosen Serverpod tooling when schema changes are introduced.
- Validate background/lock behavior on supported devices or simulators and record any platform limits.
- Run format/analyze and only the relevant tests for changed files according to project rules.

## Orchestration

Read the story and epic before starting. Inspect current code and propose small substeps for approval. Complete one approved file or concern per turn and wait for user validation before continuing. Include relevant tests and scoped checks with implementation; a later verification task does not defer required validation.
