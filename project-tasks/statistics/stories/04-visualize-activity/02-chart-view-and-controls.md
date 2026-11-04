# TASK 4.2: Add chart view and controls

Story: [Visualize activity](index.md)

Epic: [Statistics](../../index.md)

Status: Blocked by [chart data and periods](done/01-prepare-chart-data.md).

## Goal and scope

Provide the List / Charts switch and shared navigation, state and summary experience in the [story](index.md). Deliver a usable first Work time chart so controls can be checked independently; subsequent tasks add the remaining perspectives.

## Dependencies

[Task 4.1](done/01-prepare-chart-data.md).

## Acceptance criteria

- Fresh-launch defaults and session restoration work as agreed; the daily list remains accessible and usable.
- A labelled perspective selector, Week / Month / Year controls and past-period navigation expose current selection and dates. Navigation cannot enter a wholly future period.
- Work time shows correct values; selecting and clearing a bar updates the shared summary, and changing period or perspective clears selection. Empty periods and errors provide clear feedback and usable controls.
- Controls and values work with touch, keyboard and screen readers, both themes and larger text, without relying on color alone.

## Validation and context

Test navigation, selection, session state, empty/error behavior and accessibility. Inspect `lib/features/statistics/presentation/` and the [visual references](index.md#dependencies-and-visual-context); update affected screen snapshots and their index. Use the project chart skill where applicable and confirm current package capabilities.
