---
id: IMP-02
status: draft
type: improve
depends-on: []
---

# Rethink the navigation drawer

Improvements: [Improvements](../index.md)


## Current behavior and limitation

The drawer opened from the menu button has a single item, "Timer styles", which opens a separate page. With only one entry it feels out of place, and it hides what could be a simple setting.

## Desired change

Decide what the drawer is for and whether it is worth keeping. Ideas, none approved: keep it for secondary things (timer styles, language, theme, about), replace it with a settings page, or put the one item somewhere more visible.

## Benefit

A clearer, more discoverable place for secondary options.

## Scope and exclusions

- Moving Templates into the drawer is agreed separately in [UI refactor Story 2](../../ui-refactor/stories/02-templates-in-drawer/index.md). This improvement covers only the remaining provisional drawer rethink and must not duplicate that work.
- No change to how timer styles work.

## Dependencies

None. Easier to judge once more secondary options exist.

## Open decisions

- Whether a broader drawer redesign is needed after the agreed Templates move.
- Which items belong in it.

## Acceptance criteria

To be written when the change is agreed.

## Validation

Manual check of navigation on a device, plus the existing tests and `fvm flutter analyze`.

## Implementation context

`lib/features/home/presentation/home_page.dart` (the `NavigationDrawer`). This entry does not authorize code changes.

## UI snapshot reference

Before planning, inspect the relevant current UI snapshots: [home_drawer](../../../test/snapshots/goldens/home_drawer.png), [timer_styles](../../../test/snapshots/goldens/timer_styles.png), [setup_custom](../../../test/snapshots/goldens/setup_custom.png). See the [snapshot index](../../../test/snapshots/README.md) for captured states, navigation and coverage limits. These are a baseline of the captured checkout, not an approved design for this task; check the implementation checkout and parent decisions for newer or intended behavior. For visible changes, refresh affected snapshots and the index as described there, including new meaningful states or navigation changes.
