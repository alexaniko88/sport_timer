# IMP-01: Unify styles across the app

Improvements: [Improvements](index.md)


Status: Provisional.

## Current behavior and limitation

The app has shared building blocks for its look: spacing, corner radius, timer colors and a common button widget. The Setup page uses them. Other screens (Statistics, Timer styles, Login, and the old Templates tab) mix in their own gradients, colors and borders, so the app does not look like one product.

## Desired change

Review every screen against the shared building blocks, list the differences, and bring the screens to one consistent look. The goal is a more polished, uniform app.

## Benefit

A consistent look, and less one-off styling code to maintain.

## Scope and exclusions

- Timer Setup's grid, Start button refactor and provisional wheel styling are tracked in [UI refactor](../ui-refactor/index.md). Keep this proposal for remaining app-wide scope; do not duplicate those tasks here.
- App-wide corner radii and border widths are owned by [UI refactor Story 4](../ui-refactor/stories/04-unify-borders-and-corners/index.md), including Templates. Exclude that work from this broader proposal.
- The Templates tab is excluded: [Epic Templates](../templates/index.md) restyles it first, and its tile may become a shared pattern.
- No behavior changes and no new features.

## Dependencies

Best planned after Templates Story 1, so that any shared tile or token it adds is reused.

## Open decisions

- Which screens are in scope, and whether new shared widgets (tile, section header) are needed.
- Whether light and dark theme need a color review at the same time.

## Acceptance criteria

To be written when the improvement is agreed. At minimum: the agreed screens use only shared tokens and widgets, and look correct in both themes.

## Validation

Manual check of each screen in light and dark theme, plus the existing tests and `fvm flutter analyze`.

## Implementation context

Shared pieces: `lib/shared/presentation/` (widgets and theme) and the feature widgets under `lib/features/*/presentation/widgets/`. Reading and agreeing the plan comes first; this entry does not authorize code changes.

## UI snapshot reference

Before planning, inspect the relevant current UI snapshots: [setup_custom](../../test/snapshots/goldens/setup_custom.png), [templates_selected](../../test/snapshots/goldens/templates_selected.png), [statistics](../../test/snapshots/goldens/statistics.png), [timer_styles](../../test/snapshots/goldens/timer_styles.png), [login](../../test/snapshots/goldens/login.png), [home_drawer](../../test/snapshots/goldens/home_drawer.png), [account_sheet](../../test/snapshots/goldens/account_sheet.png), [account_sign_out_dialog](../../test/snapshots/goldens/account_sign_out_dialog.png), [timer_ring_round](../../test/snapshots/goldens/timer_ring_round.png), [timer_full_color_round](../../test/snapshots/goldens/timer_full_color_round.png), [timer_rounds_strip_round](../../test/snapshots/goldens/timer_rounds_strip_round.png). See the [snapshot index](../../test/snapshots/README.md) for captured states, navigation and coverage limits. These are a baseline of the captured checkout, not an approved design for this task; check the implementation checkout and parent decisions for newer or intended behavior. For visible changes, refresh affected snapshots and the index as described there, including new meaningful states or navigation changes.
