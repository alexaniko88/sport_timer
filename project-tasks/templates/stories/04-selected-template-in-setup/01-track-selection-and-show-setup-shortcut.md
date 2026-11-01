# TASK 4.1: Track explicit selection and show the Setup shortcut

Story: [Show the selected template in Timer Setup](index.md)

Epic: [Templates](../../index.md)

Status: Ready for planning where Task 2.1 is available; implementation requires the applicable orchestration workflow and plan approval.

## Goal

Confirm an explicitly selected template on Timer Setup with a tappable name that opens Templates, preserving valid selection across restarts and clearing it when timer values diverge.

## Scope

- Deliver the [story's agreed behavior and acceptance criteria](index.md), including explicit selection tracking, persistence, invalidation, the localized Setup label and navigation to the existing Templates page.
- Keep the computed settings match separate from the explicit choice. Reuse the shared settings/template flow without changing Templates-page matching semantics.
- Include focused validation for the state, persistence, label and navigation behavior changed by this task.

Exclusions are listed in the parent story. This is one cohesive deliverable; file-level implementation steps belong to later planning.

## Dependencies

- [Task 2.1: Add a templates view model](../02-selection-follows-settings/done/01-add-templates-view-model.md), marked Done; verify its output exists in the implementation checkout.
- Existing built-in templates and Templates page from [Story 1](../done/01-template-set-and-tiles/index.md).
- No dependency on Task 2.2 or provisional custom-template creation.

## Acceptance criteria

- An explicit selection, including a tap on an already matching template, produces the correct named Setup label. Automatic matching alone never produces it.
- The label opens the existing Templates page. Choosing a template keeps the user there and updates the name shown on the next visit to Setup.
- A divergent edit clears selection; restoring values or revisiting Templates does not recreate it. Unchanged values and timer style changes preserve it.
- A valid persisted selection survives restart. Missing, unknown or mismatched persisted selection produces no label, including on upgrades with settings only.
- The hidden state leaves access through the existing navigation entry. The visible state is localized, readable in both themes and accessible as a navigation action.
- Existing computed matching, timer settings application and Start behavior continue to work independently of the Setup label.

## Validation

Follow existing test conventions for changed logic and UI. Cover explicit selection versus automatic match, reselecting identical values, clearing and non-restoration, valid restart restoration, absent/unknown/mismatched stored selection, and navigation to the existing Templates page. Include focused checks for localized visibility, accessibility and preserving the existing selection navigation behavior. Plan storage failure/loading checks around the chosen persistence design so interrupted or failed saves cannot restore a misleading selection. Manual verification should check both themes, English/Spanish text, placement, tapping and an app restart.

## Implementation context

Verified entry points: `lib/presentation/home/timer_setup_page.dart`, `lib/presentation/home/templates_page.dart`, `lib/presentation/home/home_page.dart`, `lib/features/templates/templates_view_model.dart`, `lib/features/templates/templates_state.dart`, and `lib/features/settings/`.

The existing templates view model derives a match from all four current settings, including unsaved edits. Only settings and timer style are currently persisted; the Setup page has no template indicator. Plan the ownership and persistence extension before editing code, retaining the distinction between a matching template and an explicit selection. Do not treat recorded completion evidence as proof that another checkout contains the prerequisite code.

Follow the parent story’s navigation integration note when the separate drawer refactor is present. This task must not reintroduce a removed tab or implement that refactor as extra scope.
