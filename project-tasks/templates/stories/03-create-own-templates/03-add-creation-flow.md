# TASK 3.3: Add the creation flow

Story: [Story 3 overview](index.md)

Epic: [Templates](../../index.md)

Status: Provisional; blocked by Task 3.2.

## Goal

The user can create (and, if approved, edit and delete) a template from the Templates tab, and own templates appear in the list next to the 5 built-in ones.

## Scope

- The "+" icon in the Templates app bar, shown only now that the feature exists.
- The creation screen or sheet, and any save action on the Custom card, as approved in Task 3.1.
- Own templates use the same tile and the same computed selection as the built-in ones.
- Texts in English and Spanish.

## Dependencies

[Task 3.2](02-store-custom-templates.md).

## Acceptance criteria

To be written after Task 3.1. At minimum: a created template appears, can be applied with one tap, is highlighted when it matches, and is still there after an app restart.

## Validation

Widget and ViewModel tests, plus a manual check on a device, to be defined with the approved behavior.

## Implementation context

`lib/presentation/home/templates_page.dart` and the templates view model from Story 2. Read the parent indexes and follow `.agents/skills/skill-orchestrator/SKILL.md`.
