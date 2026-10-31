# TASK 1.1: Verify Serverpod local integration and approve the data model

Story: [Story 1 overview](index.md)

Epic: [Statistics](../../index.md)

Status: Not started.

## Dependencies

[Story overview](index.md).

## Goal

Verify Serverpod local integration and approve the data model. Read the parent story for the shared behavior, exclusions, and acceptance criteria.

## Work and acceptance criteria

Each item below is a completion requirement for this task:

- Check the app's actual Flutter/Dart versions and target platforms against a supported Serverpod release.
- Verify how to generate client-only tables and migrations in this existing app, including whether a companion generator/server package is needed for development.
- Identify the minimal dependencies, generated files, migration assets, commands, and project layout. Distinguish build-time tooling from runtime backend requirements.
- Keep runtime reads/writes available without a network connection or deployed backend.
- Check transactions, unique constraints, relationships, daily aggregation, and available database-change notifications or explicit refresh hooks.
- Agree stable identifiers suitable for possible backup, account ownership, duration units, indexes, pause metadata, and termination metadata.
- Inspect background execution and account-change behavior. Bind ownership to the account at run start so later authentication changes cannot reassign records.
- If the proposed integration requires a material scope or authentication change, bring that concrete decision back to the user before proceeding.

## Orchestration

Read the story and epic before starting. Inspect current code and propose small substeps for approval. Complete one approved file or concern per turn and wait for user validation before continuing. Include relevant tests and scoped checks with implementation; a later verification task does not defer required validation.
