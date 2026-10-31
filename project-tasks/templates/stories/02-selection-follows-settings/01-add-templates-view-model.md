# TASK 2.1: Add a templates view model

Story: [Story 2 overview](index.md)

Epic: [Templates](../../index.md)

Status: Blocked by Story 1.

## Goal

The matching logic lives in a ViewModel that exposes which template is selected, or custom, from the saved settings.

## Scope

- A `TemplatesViewModel` in the templates feature, with a `ValueListenable` state following the project's MVVM and `ValueNotifier` rules (immutable state class with `copyWith`, `==` and `hashCode`; `dispose()`).
- It listens to the saved timer settings and compares all four values (preparation, round, rest, rounds) with each template. The state holds the selected template id, or none (custom) together with the current values.
- A method to apply a template, which saves its values through the existing settings flow.
- The page creates and disposes it, as the other pages do. It is not registered in `get_it`.
- Out of scope: any widget change.

## Dependencies

[Task 1.1](../01-template-set-and-tiles/done/01-move-templates-to-feature.md) and Story 1 completed.

## Acceptance criteria

- Each of the 5 templates' values yields that template as selected.
- Changing any single field gives no selection and the current values.
- A settings change while the view model is alive updates its state, and nothing is set after `dispose()`.

## Validation

Unit tests with a hand-written fake settings repository, under `test/features/templates/`: each template matches, each single-field change is custom, going back to a template matches again, and dispose. Run only these files, plus `fvm flutter analyze`.

## Implementation context

See `lib/features/settings/settings_view_model.dart` and `settings_state.dart` for the shared settings state, and an existing ViewModel test for structure. Read the parent indexes and follow `.agents/skills/skill-orchestrator/SKILL.md`.
