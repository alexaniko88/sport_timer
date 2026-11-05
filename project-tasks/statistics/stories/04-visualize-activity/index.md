# STORY 4: Visualize activity

Epic: [Statistics](../../index.md)

## User outcome

See patterns in recorded timer activity and explore exact values without a crowded screen.

## Agreed behavior

- Statistics has a visible List / Charts switch. On a fresh app launch, List is selected; switching to Charts initially shows Work time for the current week. Remember view, perspective and period during the app session, including when leaving and returning to Statistics.
- Show one visualization at a time, selected by a clearly labelled control: Work time, Rounds, Work vs rest, Total time, or Consistency. Week / Month / Year controls stay visible.
- Periods are calendar weeks, months and years. Respect the locale's first weekday. Arrows navigate past periods and stop at the current period. Week and month bar charts group by day; year groups by month. Labels remain readable on small screens.
- Show a period summary and chart at a glance. Selecting a bar highlights it and replaces the summary with the selected date and exact value; selecting it again restores the period summary. Changing period or perspective clears selection. For work vs rest, stacked bars show both values on selection; distinguish the parts without relying only on color.
- Past days with no recorded activity are zero; future days are visually distinct. If a whole period has no recorded activity, show a clear empty message and retain navigation.
- Consistency highlights days with at least one completed work round. Week and month views show days; the year overview shows all months and may scroll to keep days readable. Selecting a month opens its month view. Selecting an active day shows work time and completed rounds in the summary; selecting an inactive past day says no activity was recorded.
- Use the existing account-scoped, on-device records and their recorded local dates. Only completed phases count; preparation, pauses and unfinished phases do not. Work plus rest equals total time. Charts describe timer activity, not fitness, workout completion, or activity outside the app.
- Keep the main information visible without interaction. Exact values must also be accessible to screen readers and keyboard users; support large text and light and dark themes.

## Boundaries and decisions

No goals, streaks, inferred fitness, additional measurements, editing, sync, or new workout tracking are agreed. Day-detail navigation is a separate provisional story. Calendar visual details and dense month interaction need design validation, not new product commitments. The project-local `skill-fl-chart` guides applicable chart widgets; evaluate its fit and accessibility during planning, and use a suitable calendar presentation. Validate dependency versions and capabilities before choosing a package.

## Acceptance criteria

- All five perspectives and all three periods present the correct account's existing activity using the rules above.
- Selection, navigation, empty/error states and session restoration behave as described; the daily list remains usable.
- Charts and calendar are legible and operable with touch, keyboard and screen readers in both themes and at larger text sizes.
- Existing recording and date assignment are preserved, and relevant tests and UI snapshots cover the change.

## Tasks

1. [Prepare chart data and periods](done/01-prepare-chart-data/index.md).
2. [Add chart view and controls](done/02-chart-view-and-controls/index.md).
3. [Show activity perspectives](done/03-activity-perspectives/index.md).
4. [Show consistency calendar](done/04-consistency-calendar/index.md).

## Dependencies and visual context

[Recording](../01-record-activity/index.md) and the [daily list](../02-daily-list/index.md) are completed; verify their availability in the implementation checkout. [Day details](../03-day-details/index.md) is independent and completed on its feature branch, pending merge.

Current references: [daily list](../../../../test/snapshots/goldens/statistics.png), [empty](../../../../test/snapshots/goldens/statistics_empty.png), [error](../../../../test/snapshots/goldens/statistics_error.png), and [snapshot flow index](../../../../test/snapshots/README.md). These capture the existing list in both themes, not charts, calendar, selection, or period navigation; add appropriate coverage as the UI is built.
