---
id: STAT-01-05
status: done
type: feat
depends-on: [STAT-01-04]
---

# Verify persistence and timer integration

Story: [Story 1 overview](../../index.md)

Epic: [Statistics](../../../../index.md)

## Completion evidence

Branch `improve/verify-activity-recording`, commit `aec2211`, adds recorder and SQLite integration tests. Analysis and 304 tests passed; 14 existing SQLite integration tests and the new recording integration test passed on Android. A short real-service background and lock check passed on an Android 12 phone. iOS, long-term background survival, and process-death recovery were not validated.

## Dependencies

[Previous task](../04-connect-timer-recording/index.md).

## Goal

Verify persistence and timer integration. Read the parent story for the shared behavior, exclusions, and acceptance criteria.

## Work and acceptance criteria

Each item below is a completion requirement for this task:

- Add focused tests following existing test conventions; inspect changed methods before selecting cases.
- Verify uniqueness, account isolation, aggregate accuracy, atomic writes, failure/retry behavior, and reopening stored data.
- Verify an account switch while a query or subscription result is outstanding cannot expose the old account's result, and retrying an uncertain successful commit uses the same phase ID without duplicating or replacing the record.
- Verify a normal run, early stop, pause/resume, several crossed boundaries, final-round completion, and leaving near a completion boundary.
- Verify midnight attribution, including a callback delayed until the following day and paused time spanning midnight.
- Verify numbered SQLite migrations preserve existing records when schema changes are introduced.
- Validate background/lock behavior on supported devices or simulators and record any platform limits.
- Run format/analyze and only the relevant tests for changed files according to project rules.

## Orchestration

Read the story and epic before starting. Inspect current code and propose small substeps for approval. Complete one approved file or concern per turn and wait for user validation before continuing. Include relevant tests and scoped checks with implementation; a later verification task does not defer required validation.
