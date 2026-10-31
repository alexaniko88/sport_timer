# TASK 2.2: Show the selection and the Custom card

Story: [Story 2 overview](index.md)

Epic: [Templates](../../index.md)

Status: Blocked by Task 2.1.

## Goal

The Templates page highlights the matching row, or shows the Custom card when nothing matches.

## Scope

- Read the state from the `TemplatesViewModel` and highlight the selected row (theme color and a check icon).
- Show the Custom card first in the list when no template matches. It has a distinct custom icon and a slightly different provisional color taken from the existing timer colors, shows the current values and the phase bar, and is not tappable.
- Add the "Custom" label and its screen reader text in English and Spanish.
- Both highlight and Custom card look right in light and dark theme.
- Out of scope: a save action or a "+" button (Story 3).

## Dependencies

[Task 2.1](01-add-templates-view-model.md) and [Task 1.3](../done/01-template-set-and-tiles/done/03-rebuild-templates-page.md).

## Acceptance criteria

- All acceptance criteria of [Story 2](index.md) hold in the running app.
- The Custom card cannot be mistaken for one of the 5 templates, and the list does not jump or flicker when it appears or disappears.
- Screen readers announce the selected state and the custom state.

## Validation

Widget tests: the highlight follows the state, the Custom card appears and disappears, and tapping it changes nothing. Then a manual check of the Story 2 criteria on a device or simulator, in both themes and both languages. Run only the touched tests, plus `fvm flutter analyze`.

## Implementation context

`lib/presentation/home/templates_page.dart`, the tile from Task 1.2, and the timer colors extension. Read the parent indexes and follow `.agents/skills/skill-orchestrator/SKILL.md`.
