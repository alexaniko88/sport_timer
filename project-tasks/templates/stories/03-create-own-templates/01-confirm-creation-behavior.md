# TASK 3.1: Confirm the creation behavior

Story: [Story 3 overview](index.md)

Epic: [Templates](../../index.md)

Status: Provisional; refine before implementation.

## Goal

Agree what creating, editing and deleting a template does, and where it lives in the app, before any code is written.

## Scope

- Reopen the open decisions in the [story](index.md) with the user, after looking at the finished Templates tab.
- Decide the entry points (the app bar "+", and whether the Custom card offers saving), the naming and icon choice, editing and deleting, ordering, limits and storage.
- Finalize the story's acceptance criteria and split Tasks 3.2 and 3.3 if needed.
- A research and decision task: no application code.

## Dependencies

[Story 1](../01-template-set-and-tiles/index.md) and [Story 2](../02-selection-follows-settings/index.md) completed.

## Acceptance criteria

- The approved behavior and the storage choice are written down in the story, and Tasks 3.2 and 3.3 are updated to match.

## Validation

User approval of the written decision. For storage choices that depend on a library, check the library's official documentation first.

## Implementation context

`lib/features/settings/settings_repository.dart` shows how settings are stored today in `SharedPreferences`. Read the parent indexes and follow `.agents/skills/skill-orchestrator/SKILL.md`.
