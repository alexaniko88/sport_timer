# TASK 1.1: Build the timer setup grid widget

Type: Feature implementation within the UI refactor improvement.

Story: [Timer setup refactor](../index.md).

Epic: [UI refactor](../../../index.md).

Archived after implementation and PR approval. See the saved plan for final decisions and validation evidence.

## Goal

Replace Timer Setup's four full-width option rows with a working adaptive grid of reusable, centered setting cards matching Templates.

## Scope

- Build the reusable setting card and the grid containing the four current options, following the [story's agreed design](../index.md#agreed-design-and-scope).
- Integrate the grid with the current settings state and selector callbacks.
- Preserve localized labels, value formatting, phase icons/colors, picker limits, immediate updates, persistence and timer launch behavior.
- Keep current light/dark theme support and Templates border/surface conventions. Reuse existing theme tokens; decide any necessary shared styling extraction during planning without redesigning Templates.
- Include responsive layout, button interaction feedback and accessible activation/semantics.
- Exclude wheel restyling, Start button changes, navigation changes, new settings and other screen redesigns.

## Dependencies

Use the existing `TemplateTile` visual treatment and Timer Setup settings flow, both present in the planning checkout. Verify these in the implementation branch. This task does not depend on the provisional wheel task.

## Acceptance criteria

- Normal portrait layout shows four equal square cards in two columns: preparation/work, then rest/rounds.
- Each card centers its existing phase icon above its localized label and current value; only the icon uses its semantic phase color.
- Card surfaces, corner radius and borders follow normal Templates tiles in both themes; the default outline is 1px.
- Tapping anywhere on each card opens the appropriate existing time or rounds wheel. Keyboard/accessibility activation exposes the same action without duplicate buttons.
- Changing each setting updates its card immediately and preserves the current save behavior and allowed range.
- Narrow screens and large text can use taller cards or one column without clipped content; scrolling keeps all options reachable and clear of Start/navigation.
- The existing shared floating Start button remains unchanged on Setup and Templates and launches the latest settings.
- English and Spanish remain readable; illustrative mockup values and wording are not new requirements.

## Validation

Add focused widget coverage for all four card actions and value updates, light/dark styling, narrow/large-text layouts, accessible labels/actions and Start integration. Reuse existing relevant tests and follow repository test conventions. Run appropriate formatting and analysis checks during implementation. User manual validation covers visual fit in both themes, supported languages, selector behavior and Start on both tabs.

## Implementation context

- `lib/presentation/home/timer_setup_page.dart`: current four `_buildOption` calls and selector callbacks.
- `lib/presentation/widgets/app_button.dart`: current option button behavior.
- `lib/presentation/widgets/template_tile.dart`: canonical tile surfaces, corners and borders.
- `lib/presentation/home/home_page.dart`: shared Start button and bottom navigation.
- `lib/theme/timer_colors.dart`, `lib/theme/app_spacing.dart`, `lib/theme/sport_theme.dart`: existing theme support.
- `lib/presentation/widgets/timer_settings_picker_wheel.dart`: existing selector integration, unchanged in this task.

Proceed through the repository's applicable orchestration workflow; approval of this backlog is not implementation approval.
