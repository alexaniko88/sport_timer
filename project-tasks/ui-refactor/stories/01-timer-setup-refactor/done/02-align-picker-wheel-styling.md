# TASK 1.2: Align picker wheel styling

Story: [Timer setup refactor](../index.md).

Epic: [UI refactor](../../../index.md).

Archived after implementation and PR approval. See the saved plan for decisions and validation.

## Goal

Bring the existing time and rounds wheels closer to Templates' theme while retaining phase colors and existing interaction.

## Recorded direction

- Follow existing light and dark themes and the shared Templates visual language.
- Retain the current preparation/work/rest/rounds color mapping.
- Use 1px wheel value borders, including selected values, instead of the current thicker selected border.
- Preserve immediate setting updates, current limits and persistence; cards continue to open the existing modal selectors.

## Scope and exclusions

Cover the time and rounds selectors. Exclude grid implementation, new confirmation actions, Start changes and navigation changes.

## Dependencies and open decisions

Intended after [Task 1.1](01-build-timer-setup-grid.md), so the wheel can be assessed alongside the delivered grid. Confirm how much phase tint remains on the sheet and how selection is distinguished with a uniform 1px border. This is not ready for implementation planning until those details are agreed.

## Provisional acceptance criteria

- Both selector types use 1px value borders and remain legible in both themes.
- Selected values remain clearly distinguishable while retaining the current phase colors.
- Scrolling, bounds, immediate updates and dismissal keep their existing behavior.

## Validation and implementation context

When agreed, include focused selected/unselected styling and interaction checks, plus user visual validation across phase colors and both themes. Current entry point: `lib/presentation/widgets/timer_settings_picker_wheel.dart`.
