# STORY 1: Timer setup refactor

Epic: [UI refactor](../../index.md).

All three tasks are archived; the Timer tab update is pending PR and merge.

## User outcome

As a user, I want clearly readable, tappable settings in a grid that matches Templates and follows the app's current light and dark themes.

## Agreed design and scope

- Follow the selected [Centered design reference](../../references/centered-grid.png): icon, label and value stacked vertically and centered in each card. The image describes composition; current theme tokens, localized labels and value formatting take precedence over illustrative details.
- Show the four current options in reading order: preparation, work, rest, rounds. Default to a two-column grid with square cards.
- Reuse the normal Templates tile surface, corner radius and border treatment, currently a neutral surface, 12px corners and subtle 1px outline. Do not introduce a separate border style for the grid or restyle unrelated screens.
- Icons retain the existing option icons and semantic phase colors: preparation yellow, work red, rest blue, rounds orange, using the appropriate theme variants. Text uses theme text colors.
- Each whole card works as a button and opens its existing selector. Preserve current limits, immediate updates and persistence.
- Allow taller cards or one column on narrow screens or with large text, and scrolling when needed. Content must remain readable and reachable without covering the Start button.
- Keep the shared Start button on Timer Setup and Templates unchanged.
- Wheel restyling is a separate task; the grid uses the existing wheel initially.
- Task UI 1.3 replaces the Home tab house with outlined/filled timer icons and renames its label, tooltip and accessible name to Timer / Temporizador. Delivered after UI 3.1 changed Start to play; navigation behavior is preserved.

## Acceptance criteria

- The four settings appear as centered grid cards with the agreed order and adaptive layout.
- Cards match Templates' visual treatment in light and dark themes and expose their label, value and button action accessibly.
- Each card opens the correct existing selector; edits update the displayed setting and continue to be saved.
- Start remains available on both existing tabs and launches the current settings.
- Small screens, large text and English/Spanish labels remain usable.
- Task UI 1.3 makes the Timer Setup destination recognizable with timer icons and Timer / Temporizador naming, after Start uses play. This is separate from the grid delivery.
- Provisional wheel criteria belong to Task 1.2 and are not required for the grid delivery.

## Tasks

1. [Build the timer setup grid widget](done/01-build-timer-setup-grid/index.md) — archived; final decisions and evidence are in the saved plan.
2. [Align picker wheel styling](done/02-align-picker-wheel-styling/index.md) — archived.
3. [Replace the Home tab icon and label](done/03-replace-home-tab-icon/index.md) — archived; implemented on `improve/timer-tab-label`.

## Dependencies and open decisions

The current checkout contains `TemplateTile` and the compact Templates page. Verify their availability in the implementation checkout. No product decisions remain for Task 1.1; exact adaptive breakpoints, component API and shared styling approach are implementation planning choices. Wheel styling decisions and validation are in the saved plan.

UI 1.3 icon and naming agreed on 2026-11-01. No product decisions remain; UI 3.1 was delivered first so Timer Setup uses a timer destination icon and a play Start action.
