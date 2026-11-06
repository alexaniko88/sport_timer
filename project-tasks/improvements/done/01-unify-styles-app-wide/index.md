---
id: IMP-01
status: done
type: improve
depends-on: []
---

# Unify styles across the app

Improvements: [Improvements](../../index.md)

## Current behavior and limitation

The app had shared building blocks for its look (spacing, radius, timer colors, a button widget), but several screens drew the same tile by hand with small differences: five copies of one surface, a Timer styles tile with a strong pink outline in light mode and a constant 2 px border, mixed button shapes (pills and 12 radius rectangles), and repeated one-off text styles.

## Final scope and decisions

The audit found no gradients or hardcoded `Color(0x...)` values left in feature code, so the work was about shared surfaces, shapes and text roles. The user chose to include the corner radius and border width rules of [UI refactor Story 4](../../../ui-refactor/stories/04-unify-borders-and-corners/index.md) in this task.

- One shared tile, `AppSurface`: `surfaceContainer` fill, 12 radius, 1 px `outlineVariant` border, and a 2 px primary border when selected, with the padding shrunk so the size does not change.
- Radius scale 8, 12 and 20 (`AppRadius`) and border widths thin 1 and thick 2 (`AppBorderWidth`). Focus, disabled and error states change no border.
- Exceptions kept on purpose: circles, pills (phase chip, phase bar, rounds strip), the timer style preview frame, the picker items' phase-colored border, and the theme definitions.
- All rectangular buttons are 12 radius rectangles and dialogs are 20, both set once in `SportTheme`.
- Timer styles tiles match Templates. The template label on Timer setup uses the shared tile.
- Shared text roles in `AppTextThemeExtension` (`tileTitle`, `tileSecondary`, `tileValue`, `emphasizedLabel`); `AppAlpha` for repeated alpha values.
- Unused code removed: the card, input and FAB themes, `AppButton.fab` and `AppButton.option`, two text styles, two spacing values, unused palette colors and four `TimerColors` fields.
- The Statistics Retry button is now an `AppButton.primary` with a localized label.
- The repository rules were updated so every AI tool knows these rules: the `Styling and theme` section in `CLAUDE.md`, the orchestrator skill overrides and the Codex agent files.

Not included: the active timer screens (intentional phase colors and shapes), a separate light and dark color review (only the Timer styles border was a theme defect), and the untranslated Statistics text, which is recorded as [BUG-02](../../../bugs/done/02-untranslated-statistics-and-timer-strings/index.md).

## Acceptance evidence

- The agreed screens use the shared tile, tokens, button shapes and text roles. A search of `lib/` for radius, border width, alpha and color literals leaves only the documented exceptions.
- Light and dark themes were checked through the refreshed goldens: `account_sheet`, `account_sign_out_dialog`, `home_drawer`, `login`, `setup_custom`, `setup_template_selected`, `statistics`, `statistics_error` and `timer_styles`. They show no clipping, overflow or size jump on selection. The snapshot index needed no change.
- Review by `agent-pr-review` found no Critical issues. Its two General findings (template label tap target and the grid sizing coupling) and three minor ones were fixed.
- `fvm flutter analyze` reports no issues and the full `fvm flutter test` passes (306 tests, after the tests of the removed button variants were deleted).

## Validation notes

The visual check used the goldens only, as the user requested; no emulator or device was used. Visible changes: login and Retry buttons are rectangles instead of pills, the sign-out dialog corners are 20 instead of 28, the Timer styles tiles look like Templates tiles with bold names, and the Statistics tile lines are smaller and muted.

## Dependencies

None remaining. [UI refactor Story 4](../../../ui-refactor/stories/04-unify-borders-and-corners/index.md) overlaps with this work; see its note.
