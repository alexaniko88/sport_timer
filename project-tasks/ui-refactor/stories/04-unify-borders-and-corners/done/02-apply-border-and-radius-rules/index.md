---
id: UI-04-02
status: done
type: feat
depends-on: [UI-04-01]
---

# TASK UI 4.2: Apply shared border and radius rules app-wide

Story: [Unify borders and corner radii](../../index.md).

Epic: [UI refactor](../../../../index.md).

## Completion evidence

IMP-01 applied the shared rules in PR #42 (merge commit `17115f2`). This branch completed the audit and changed the drawer's trailing corners to the shared 20 radius, preserving its directional behavior. The drawer golden was refreshed, and its focused light/dark and LTR/RTL widget test passed. Touched-file analysis and the full Flutter suite passed (376 tests); review passed cleanly. The user approved the implementation and tests; this branch's PR is pending.

## Goal

Make all existing app screens and overlays follow the agreed shared border-width and corner-radius rules.

## Scope and exclusions

- Use the definitions and component/state mapping agreed in UI 4.1, reusing existing theme facilities where suitable.
- Migrate local overrides and relevant theme defaults across the whole app, retaining only documented exceptions.
- Coordinate with already-delivered UI work and record the shared rules for pending stories. Do not implement pending layouts or unrelated styling changes.
- Preserve behavior, accessibility, theme support and meaningful state distinctions as required by the parent story.

## Dependencies

[UI 4.1](../01-agree-border-and-radius-rules/index.md): approved inventory, values, exceptions and migration checklist. Verify which other UI changes exist in the implementation checkout.

## Acceptance criteria

- All parent-story acceptance criteria pass against the approved inventory.
- Shared definitions govern the agreed roles and states; no conflicting one-off radius or border-width values remain outside documented exceptions.
- Border state changes do not shift surrounding layout; rounded surfaces, ink effects and clipping remain aligned.
- Existing controls, navigation and timer flows retain their behavior.

## Validation

Check the migration against every inventory entry and search for remaining local overrides. Adapt focused existing widget tests where changed styling affects state visibility, dimensions or clipping; avoid tests that merely repeat constants. User visual validation covers the inventoried screens and overlays in light/dark themes and relevant states, including narrow layouts and large text. Run applicable formatting, analysis and touched-test checks during implementation.

## Implementation context

Start from the decision recorded by UI 4.1 and the parent story. Follow the applicable orchestration workflow; this ticket does not approve application code edits.

## UI snapshot reference

Before planning, inspect the relevant current UI snapshots: [templates_selected](../../../../../../test/snapshots/goldens/templates_selected.png), [setup_custom](../../../../../../test/snapshots/goldens/setup_custom.png), [setup_time_picker](../../../../../../test/snapshots/goldens/setup_time_picker.png), [home_drawer](../../../../../../test/snapshots/goldens/home_drawer.png), [account_sheet](../../../../../../test/snapshots/goldens/account_sheet.png), [account_sign_out_dialog](../../../../../../test/snapshots/goldens/account_sign_out_dialog.png), [statistics](../../../../../../test/snapshots/goldens/statistics.png), [timer_styles](../../../../../../test/snapshots/goldens/timer_styles.png), [login](../../../../../../test/snapshots/goldens/login.png), [timer_ring_round](../../../../../../test/snapshots/goldens/timer_ring_round.png), [timer_full_color_round](../../../../../../test/snapshots/goldens/timer_full_color_round.png), [timer_rounds_strip_round](../../../../../../test/snapshots/goldens/timer_rounds_strip_round.png). See the [snapshot index](../../../../../../test/snapshots/README.md) for captured states, navigation and coverage limits. These are a baseline of the captured checkout, not an approved design for this task; check the implementation checkout and parent decisions for newer or intended behavior. For visible changes, refresh affected snapshots and the index as described there, including new meaningful states or navigation changes.
