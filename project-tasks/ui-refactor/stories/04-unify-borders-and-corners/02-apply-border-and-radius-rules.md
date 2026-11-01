# TASK UI 4.2: Apply shared border and radius rules app-wide

Story: [Unify borders and corner radii](index.md).

Epic: [UI refactor](../../index.md).

Status: Blocked by UI 4.1.

## Goal

Make all existing app screens and overlays follow the agreed shared border-width and corner-radius rules.

## Scope and exclusions

- Use the definitions and component/state mapping agreed in UI 4.1, reusing existing theme facilities where suitable.
- Migrate local overrides and relevant theme defaults across the whole app, retaining only documented exceptions.
- Coordinate with already-delivered UI work and record the shared rules for pending stories. Do not implement pending layouts or unrelated styling changes.
- Preserve behavior, accessibility, theme support and meaningful state distinctions as required by the parent story.

## Dependencies

[UI 4.1](01-agree-border-and-radius-rules.md): approved inventory, values, exceptions and migration checklist. Verify which other UI changes exist in the implementation checkout.

## Acceptance criteria

- All parent-story acceptance criteria pass against the approved inventory.
- Shared definitions govern the agreed roles and states; no conflicting one-off radius or border-width values remain outside documented exceptions.
- Border state changes do not shift surrounding layout; rounded surfaces, ink effects and clipping remain aligned.
- Existing controls, navigation and timer flows retain their behavior.

## Validation

Check the migration against every inventory entry and search for remaining local overrides. Adapt focused existing widget tests where changed styling affects state visibility, dimensions or clipping; avoid tests that merely repeat constants. User visual validation covers the inventoried screens and overlays in light/dark themes and relevant states, including narrow layouts and large text. Run applicable formatting, analysis and touched-test checks during implementation.

## Implementation context

Start from the decision recorded by UI 4.1 and the parent story. Follow the applicable orchestration workflow; this ticket does not approve application code edits.
