# TASK 1.2: Add the database foundation

Story: [Story 1 overview](index.md)

Epic: [Statistics](../../index.md)

Status: Not started.

## Dependencies

[Previous task](01-verify-serverpod-integration.md).

## Goal

Add the database foundation. Read the parent story for the shared behavior, exclusions, and acceptance criteria.

## Work and acceptance criteria

Each item below is a completion requirement for this task:

- Add only the approved Serverpod packages and generation configuration.
- Define run and completed-phase models, their relationship, indexes, and uniqueness constraints.
- Open one appropriate database session through the app's existing dependency setup and manage its lifecycle.
- Provide a repeatable generation workflow and versioned migrations that preserve existing records.
- Ensure account ownership is enforced by the data access layer, including after sign-out/sign-in.

## Orchestration

Read the story and epic before starting. Inspect current code and propose small substeps for approval. Complete one approved file or concern per turn and wait for user validation before continuing. Include relevant tests and scoped checks with implementation; a later verification task does not defer required validation.
