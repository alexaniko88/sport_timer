# TASK 1.3: Rebuild the Templates page

Story: [Story 1 overview](index.md)

Epic: [Templates](../../index.md)

Status: Blocked by Task 1.2.

## Goal

The Templates tab shows the 5 new tiles, and tapping one applies it to the saved timer settings.

## Scope

- Replace the card list with the list of tiles from Task 1.2, in the order Default, Full Abs, Hyrox, Stretching, Strength.
- Keep the app bar title "Choose your template", the menu button and the account avatar. Remove the subtitle line.
- Tapping a tile calls the existing settings save and stays on the page. No snackbar, no navigation, no timer start.
- Keep the bottom space so the last tile is clear of the Start button.
- Delete the old card code, the accent enum and the texts nothing uses any more.
- Out of scope: the computed selected state and the Custom card (Story 2). In this task no row needs to be highlighted.

## Dependencies

[Task 1.2](02-build-template-tile.md).

## Acceptance criteria

- The tab shows exactly the 5 tiles, with the 5 rows fitting a normal phone screen and the last one clear of the Start button.
- After tapping a tile, the Setup tab shows that template's values, and pressing Start runs them.
- The old CrossFit template, accent colors and unused texts are gone, and `fvm flutter analyze` is clean.

## Validation

Widget test: tapping each tile saves the matching settings (use a hand-written fake settings repository, no mocking package). Then run the app on a device or simulator and check both themes and both languages by hand. Run only the touched tests, plus `fvm flutter analyze`.

## Implementation context

`lib/presentation/home/templates_page.dart` and `lib/presentation/home/home_page.dart` (the Start button and the shared `SettingsViewModel`). Read the parent indexes and follow `.agents/skills/skill-orchestrator/SKILL.md`.
