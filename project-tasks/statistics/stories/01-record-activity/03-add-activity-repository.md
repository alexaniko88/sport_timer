# TASK 1.3: Add the activity persistence interface

Story: [Story 1 overview](index.md)

Epic: [Statistics](../../index.md)

Status: Not started.

## Dependencies

[Previous task](done/02-add-database-foundation.md).

## Goal

Add the activity persistence interface. Read the parent story for the shared behavior, exclusions, and acceptance criteria.

## Work and acceptance criteria

Each item below is a completion requirement for this task:

- Follow existing repository and error-handling conventions.
- Support creating run metadata, recording completed phases transactionally, and updating known lifecycle metadata.
- Make exact repeated phase writes an idempotent success without changing the original values; retain or deterministically derive the same phase UUID when retrying an uncertain commit. Reject inconsistent duplicates instead of replacing history.
- Provide account-scoped daily aggregate queries and retain access to underlying run/phase records for future details.
- Define how failed writes are reported and retried while the process is alive. Advance the persisted completion checkpoint only after a successful commit.
- Scope reads to the current account and clear account-specific state when authentication changes. Capture the account or authentication generation for each query or subscription, and discard results if authentication changes before delivery. Keep pending writes bound to the run's original account and refresh interested state after a commit.

## Orchestration

Read the story and epic before starting. Inspect current code and propose small substeps for approval. Complete one approved file or concern per turn and wait for user validation before continuing. Include relevant tests and scoped checks with implementation; a later verification task does not defer required validation.
