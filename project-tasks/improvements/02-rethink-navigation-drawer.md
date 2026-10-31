# IMP-02: Rethink the navigation drawer

Improvements: [Improvements](index.md)

Progress: [Project task status](../status.md)

Status: Provisional.

## Current behavior and limitation

The drawer opened from the menu button has a single item, "Timer styles", which opens a separate page. With only one entry it feels out of place, and it hides what could be a simple setting.

## Desired change

Decide what the drawer is for and whether it is worth keeping. Ideas, none approved: keep it for secondary things (timer styles, language, theme, about), replace it with a settings page, or put the one item somewhere more visible.

## Benefit

A clearer, more discoverable place for secondary options.

## Scope and exclusions

- Templates stay in the bottom tab and do not move into the drawer. That was decided in [Epic Templates](../templates/index.md).
- No change to how timer styles work.

## Dependencies

None. Easier to judge once more secondary options exist.

## Open decisions

- Keep, replace or remove the drawer.
- Which items belong in it.

## Acceptance criteria

To be written when the change is agreed.

## Validation

Manual check of navigation on a device, plus the existing tests and `fvm flutter analyze`.

## Implementation context

`lib/presentation/home/home_page.dart` (the `NavigationDrawer`). This entry does not authorize code changes.
