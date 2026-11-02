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

[Story 1](../done/01-template-set-and-tiles/index.md) and [Story 2](../done/02-selection-follows-settings/index.md) completed.

## Acceptance criteria

- The approved behavior and the storage choice are written down in the story, and Tasks 3.2 and 3.3 are updated to match.

## Validation

User approval of the written decision. For storage choices that depend on a library, check the library's official documentation first.

## Implementation context

`lib/features/settings/settings_repository.dart` shows how settings are stored today in `SharedPreferences`. Read the parent indexes and follow `.agents/skills/skill-orchestrator/SKILL.md`.

## UI snapshot reference

Before planning, inspect the relevant current UI snapshots: [templates_selected](../../../../test/snapshots/goldens/templates_selected.png), [templates_custom](../../../../test/snapshots/goldens/templates_custom.png), [setup_template_selected](../../../../test/snapshots/goldens/setup_template_selected.png). See the [snapshot index](../../../../test/snapshots/README.md) for captured states, navigation and coverage limits. These are a baseline of the captured checkout, not an approved design for this task; check the implementation checkout and parent decisions for newer or intended behavior. Use the reference to inform the outstanding decisions without approving a layout or values in advance.
