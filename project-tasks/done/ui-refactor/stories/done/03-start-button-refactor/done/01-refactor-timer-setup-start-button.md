# TASK UI 3.1: Replace Timer Setup's floating Start button

Story: [Refactor the Start button](../index.md).

Epic: [UI refactor](../../../../index.md).

Status: Done.

## Goal

Deliver the parent story's fixed, wide Start action on Timer Setup without changing timer-launch behavior.

## Scope and exclusions

- Replace Timer Setup's floating Start presentation with the agreed primary filled button, play icon, localized label and card-matching corners.
- Reserve layout space above bottom navigation; allow settings to scroll independently with no content hidden behind Start.
- Preserve settings saving and the current launch parameters/flow. Do not introduce new launch behavior or alter unrelated uses of shared button widgets.
- Preserve Templates as supplied by the checkout, including its existing Start button if UI 2.1 has not shipped. Removing that button remains UI 2.1 scope.
- Exclude navigation changes, wheel restyling, setting-card redesign and active-timer controls.

## Dependencies

No pending implementation prerequisite. Verify the available Home/Setup layout and theme treatment before planning. Coordinate with [UI 1.1](../../01-timer-setup-refactor/done/01-build-timer-setup-grid.md) and [UI 2.1](../../02-templates-in-drawer/done/01-move-templates-navigation.md) wherever already delivered, following the parent story's boundaries. Do not require provisional wheel styling.

## Acceptance criteria

- All parent-story acceptance criteria pass, including one fixed Start action on Timer Setup and independently scrollable settings.
- Activation launches the current preparation, work, rest, rounds and timer style through the existing save/launch flow.
- Light/dark themes, English/Spanish, narrow layouts, large text and accessible activation remain usable.
- Templates' existing navigation and Start behavior are preserved; Statistics gains no Start button.

## Validation

Add or adapt focused widget checks for fixed placement during settings scrolling, final-setting clearance, theme styling, localized labels, large-text/narrow layouts and accessible activation. Verify launch parameters and existing save behavior, plus Start visibility on the other available Home tabs. Reuse existing button and Templates integration tests without changing unrelated button expectations. User manual validation covers visual fit in both themes/languages, settings scrolling and timer launch. Run applicable formatting and analysis checks during implementation.

## Implementation context

- `lib/presentation/home/home_page.dart`: current shared floating Start, bottom navigation and timer launch from settings state.
- `lib/presentation/home/timer_setup_page.dart`: settings content and layout to keep clear of the fixed action.
- `lib/presentation/widgets/app_button.dart`: current extended FAB and shared button variants.
- `lib/presentation/widgets/template_tile.dart`: existing corner treatment; use the delivered setting-card treatment if UI 1.1 is available.
- `lib/theme/sport_theme.dart`: current theme and FAB sizing; avoid changing unrelated FABs as part of this task.
- `test/presentation/widgets/app_button_test.dart` and `test/presentation/home/templates_page_test.dart`: existing button and settings/launch coverage to inspect during planning.

Read the parent story and follow the applicable orchestration workflow. This ticket records agreed scope, not approval to edit application code.
