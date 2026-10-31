# STORY 1: New template set and tile redesign

Epic: [Templates](../../index.md)

Status: Partially complete — Tasks 1.1 and 1.2 Done; Task 1.3 ready for planning where Task 1.2 is available.

## User outcome

As a user, I want a short list of good-looking, ready-made workouts so that I can fill in my timer with one tap, without using the wheels.

## Scope

- The 5 templates, their values, names, icons and en/es texts, as listed in the [epic](../../index.md).
- The compact tile with a summary line, the total time and the phase bar, built on shared app tokens.
- The rebuilt Templates page: app bar title kept, subtitle removed, list of tiles, clear of the Start button.
- Tapping a tile applies its values to the saved settings and stays on the page.

Out of scope: the computed selected state and the Custom card ([Story 2](../02-selection-follows-settings/index.md)), and creating templates ([Story 3](../03-create-own-templates/index.md)). In this story the page may show no selection at all.

## Acceptance criteria

- The Templates tab shows exactly 5 rows in this order: Default, Full Abs, Hyrox, Stretching, Strength. The 5 rows fit on a normal phone screen, and the last row is not hidden by the Start button.
- Each row shows the correct icon, name, summary line and total time, and its phase bar proportions follow the real durations.
- Tapping a row saves its values; the Setup tab then shows them and the Start button runs them.
- The tiles use the same spacing, radius and phase colors as the Setup page and the timer, in light and dark theme, and no per-template accent colors remain.
- All names and summaries are available in English and Spanish, and long Spanish text does not overflow.
- The old card code, the CrossFit template and the unused texts are removed.

## Tasks

1. [Move templates into a feature folder](01-move-templates-to-feature.md).
2. [Build the compact template tile](done/02-build-template-tile.md).
3. [Rebuild the Templates page](03-rebuild-templates-page.md).

## Dependencies and open decisions

None open. The three new template values are starting numbers and may be tuned during planning.
