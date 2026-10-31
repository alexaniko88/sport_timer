# TASK 3.2: Store custom templates

Story: [Story 3 overview](index.md)

Epic: [Templates](../../index.md)

Status: Provisional; blocked by Task 3.1.

## Goal

Own templates can be saved, listed and removed through a repository, using the storage approved in Task 3.1.

## Scope

- A repository returning `Result` from the methods that can fail, following the project rules.
- Out of scope until Task 3.1 is approved: the exact fields, the storage engine and the account separation.

## Dependencies

[Task 3.1](01-confirm-creation-behavior.md).

## Acceptance criteria

To be written after Task 3.1. At minimum: saved templates survive an app restart, and failures return a `Failure` instead of throwing.

## Validation

Unit tests with hand-written fakes, to be defined with the approved storage.

## Implementation context

Existing repository patterns are in `lib/features/settings/` and `lib/features/user/`. Read the parent indexes and follow `.agents/skills/skill-orchestrator/SKILL.md`.
