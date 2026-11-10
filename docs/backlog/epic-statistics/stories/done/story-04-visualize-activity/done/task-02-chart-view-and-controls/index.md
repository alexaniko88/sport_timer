---
id: STAT-04-02
status: done
type: feat
depends-on: [STAT-04-01]
---

# Add chart view and controls

Story: [Visualize activity](../../index.md)

Epic: [Statistics](../../../../../index.md)

## Goal and scope

Provide the List / Charts switch and shared navigation, state and summary experience in the [story](../../index.md). Deliver a usable first Work time chart so controls can be checked independently; subsequent tasks add the remaining perspectives.

## Dependencies

[Task 4.1](../task-01-prepare-chart-data/index.md).

## Acceptance criteria

- Fresh-launch defaults and session restoration work as agreed; the daily list remains accessible and usable.
- A labelled perspective selector, Week / Month / Year controls and past-period navigation expose current selection and dates. Navigation cannot enter a wholly future period.
- Work time shows correct values; selecting and clearing a bar updates the shared summary, and changing period or perspective clears selection. Empty periods and errors provide clear feedback and usable controls.
- Controls and values work with touch, keyboard and screen readers, both themes and larger text, without relying on color alone.

## Validation and context

Test navigation, selection, session state, empty/error behavior and accessibility. Inspect `lib/features/statistics/presentation/` and the [visual references](../../index.md#dependencies-and-visual-context); update affected screen snapshots and their index. Use the project chart skill where applicable and confirm current package capabilities.

## Completion evidence

List and Work time chart views, period navigation, selection and session state are implemented. Chart controls and values support keyboard and screen readers, both themes and enlarged text; later tasks add the other perspectives.

Validation: full Flutter suite passed (423); touched-file analysis passed. Snapshots cover chart content, selection, empty and error states. Review passed after fixing a short-screen overflow. The existing Android integration suite passed before its removal at the user's request.
