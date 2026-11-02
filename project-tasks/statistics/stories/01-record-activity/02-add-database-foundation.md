# TASK 1.2: Add the database foundation

Story: [Story 1 overview](index.md)

Epic: [Statistics](../../index.md)

Status: Not started.

## Dependencies

[Previous task](done/01-verify-serverpod-integration.md).

## Goal

Add the database foundation. Read the parent story for the shared behavior, exclusions, and acceptance criteria.

## Work and acceptance criteria

Each item below is a completion requirement for this task:

- Add compatible, exactly pinned `sqflite`, `path`, and UUID dependencies as needed; no generated companion package or backend is required.
- Define run and completed-phase models, their relationship, indexes, and uniqueness constraints.
- Open one appropriate database through the app's existing dependency setup, enable foreign keys in `onConfigure`, and manage its lifecycle.
- Provide numbered, non-destructive `onUpgrade` migrations that preserve existing records.
- Ensure account ownership is enforced by the data access layer, including after sign-out/sign-in.
- Verify package resolution and native compatibility for Android and iOS. The macOS scaffold is incomplete; do not claim a macOS app build without restoring it in separately agreed scope.
- Test schema creation, foreign keys and uniqueness, transaction rollback, reopening persisted records, and an upgrade from an older database without data loss. Validate the actual `sqflite` integration rather than treating package documentation as a runtime test.

## Orchestration

Read the story and epic before starting. Inspect current code and propose small substeps for approval. Complete one approved file or concern per turn and wait for user validation before continuing. Include relevant tests and scoped checks with implementation; a later verification task does not defer required validation.
