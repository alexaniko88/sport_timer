# TASK UI 2.1: Move Templates navigation into the drawer

Story: [Access Templates from the drawer](index.md).

Epic: [UI refactor](../../index.md).

Status: Ready for planning.

## Goal

Deliver the complete navigation flow agreed in the parent story, with Home focused on Timer Setup and Statistics.

## Scope and exclusions

Replace the Templates bottom tab with a drawer destination above Timer styles. Give the separate page the Timer styles app-bar pattern and remove Start from Templates. Keep shared saved settings, apply-and-stay behavior and ordinary Back popping. Preserve existing selection state across navigation; computed highlighting and Custom remain separate Templates work. Do not redesign the drawer, tiles, Timer styles or Statistics.

## Dependencies

Completed [Templates Story 1](../../../templates/stories/done/01-template-set-and-tiles/index.md), verified in the implementation checkout. Independent of other pending UI and Templates stories.

## Acceptance criteria

- All parent-story acceptance criteria pass, including entry from both Home tabs and Back to the originating tab.
- Template application remains persisted across leaving/reopening the page; navigating without choosing does not change settings or clear an existing selection.
- Start is visible only on Timer Setup and launches the saved workout after a template is applied.
- Timer styles remains reachable and retains its existing selection/navigation behavior.

## Validation

Add or adapt focused navigation/widget checks for the changed flow: two Home tabs, drawer order and route, page controls, apply-and-stay, Back from both origins, preserved settings on reopening, and Start visibility/parameters. Follow existing test conventions. User manual validation covers English/Spanish, light/dark themes and accessibility; run applicable formatting and analysis checks during implementation.

## Implementation context

Verified entry points: `lib/presentation/home/home_page.dart`, `lib/presentation/home/templates_page.dart`, `lib/navigation.dart`, `lib/presentation/timer_styles/timer_styles_page.dart`, and `lib/features/settings/settings_view_model.dart`. Templates currently has no separate route and uses Home's shared Start button. Account for bottom-tab index changes and preserve the shared settings state. Read the parent story for the agreed behavior before orchestration.

## UI snapshot reference

Before planning, inspect the relevant current UI snapshots: [home_drawer](../../../../test/snapshots/goldens/home_drawer.png), [templates_selected](../../../../test/snapshots/goldens/templates_selected.png), [templates_custom](../../../../test/snapshots/goldens/templates_custom.png), [setup_template_selected](../../../../test/snapshots/goldens/setup_template_selected.png), [statistics](../../../../test/snapshots/goldens/statistics.png), [timer_styles](../../../../test/snapshots/goldens/timer_styles.png). See the [snapshot index](../../../../test/snapshots/README.md) for captured states, navigation and coverage limits. These are a baseline of the captured checkout, not an approved design for this task; check the implementation checkout and parent decisions for newer or intended behavior. For visible changes, refresh affected snapshots and the index as described there, including new meaningful states or navigation changes.
