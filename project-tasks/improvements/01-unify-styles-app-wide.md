# IMP-01: Unify styles across the app

Improvements: [Improvements](index.md)

Progress: [Project task status](../status.md)

Status: Provisional.

## Current behavior and limitation

The app has shared building blocks for its look: spacing, corner radius, timer colors and a common button widget. The Setup page uses them. Other screens (Statistics, Timer styles, Login, and the old Templates tab) mix in their own gradients, colors and borders, so the app does not look like one product.

## Desired change

Review every screen against the shared building blocks, list the differences, and bring the screens to one consistent look. The goal is a more polished, uniform app.

## Benefit

A consistent look, and less one-off styling code to maintain.

## Scope and exclusions

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

Shared pieces: `lib/presentation/widgets/` and the theme files. Reading and agreeing the plan comes first; this entry does not authorize code changes.
