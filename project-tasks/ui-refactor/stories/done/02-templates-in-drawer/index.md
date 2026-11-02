# STORY 2: Access Templates from the drawer

Epic: [UI refactor](../../../index.md).

Status: Done on branch `improve/templates-in-drawer` (implementation commit `a5e2438`; pending PR and merge).

## User outcome

As a user, I want Templates in the drawer so Home focuses on Timer Setup and Statistics.

## Agreed behavior and scope

- Home retains two bottom tabs: Timer Setup and Statistics, in that order. Remove Templates from the bottom navigation.
- Add a localized Templates drawer entry above Timer styles, opening a separate page like Timer styles. Close the drawer before opening it.
- Use a title and Back arrow, without the current menu button or account avatar. No bottom navigation or Start button appears on Templates.
- Start exists only on Timer Setup; preserve its current appearance and launch behavior.
- Tapping a template immediately applies and persists its settings and stays on Templates. It never starts the timer.
- Back simply pops the page to the previously selected Home tab, including Statistics. It neither resets nor rolls back the applied settings.
- Opening, closing and reopening Templates preserves the saved workout. If a template was already selected, navigation alone must not clear that selection. Visible matching-template highlighting and the Custom card remain owned by [Templates Story 2](../../../../templates/stories/done/02-selection-follows-settings/index.md); this move must preserve them wherever already available.
- Keep the drawer appearance and Timer styles behavior unchanged. Broader drawer redesign, Statistics implementation, template creation and tile redesign are excluded.

## Acceptance criteria

- Home shows only Timer Setup and Statistics; both remain reachable with correct content and Start visibility.
- Templates opens from either Home tab using the drawer entry above Timer styles.
- The Templates page has the agreed app bar and no Start or bottom navigation.
- Applying a template stays on the page and updates saved Setup values; Back and reopening do not undo or reset them.
- Back without choosing anything leaves settings unchanged and returns to the originating tab.
- Returning to Setup and starting uses the saved template values and existing timer style.
- Navigation remains usable in English/Spanish, light/dark themes and with screen readers.

## Tasks

1. [Move Templates navigation into the drawer](done/01-move-templates-navigation.md) — Done on branch `improve/templates-in-drawer`.

## Dependencies and open decisions

Use the completed compact Templates page from [Templates Story 1](../../../../templates/stories/done/01-template-set-and-tiles/index.md); verify it exists in the implementation checkout. No dependency on UI Story 1, picker restyling, Statistics data implementation or Templates selection highlighting. No product decisions remain. Route/state wiring belongs to implementation planning. Backlog agreement does not approve application code changes.
