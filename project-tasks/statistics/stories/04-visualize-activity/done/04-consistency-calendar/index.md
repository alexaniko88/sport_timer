---
id: STAT-04-04
status: done
type: feat
depends-on: [STAT-04-01, STAT-04-02]
---

# Show consistency calendar

Story: [Visualize activity](../../index.md)

Epic: [Statistics](../../../../index.md)

## Goal and scope

Add the Consistency perspective and its week, month and year views as described in the [story](../../index.md). Do not introduce streaks or goals.

## Dependencies

[Task 4.1](../01-prepare-chart-data/index.md) and [Task 4.2](../02-chart-view-and-controls/index.md); independent of Task 4.3.

## Acceptance criteria

- Days with completed work rounds are highlighted; past inactive and future days are distinguishable. Week and month show individual days with locale-aware ordering.
- Year shows all months, scrolling where necessary for readability; selecting a month opens that month. Selecting an active day shows work time and rounds; selecting an inactive past day shows no activity recorded.
- Empty periods, navigation and accessible interaction follow the story, including keyboard and screen-reader access to days and values.

## Validation and context

Test date boundaries, leap years, active/inactive/future days, month navigation, selection and accessibility. Check small screens, large text and both themes. Refresh affected UI snapshots and update their index; see [visual context](../../index.md#dependencies-and-visual-context).

## Completion evidence

Week, month and year consistency calendars show completed work days, allow day selection and month navigation, and support localized, accessible interaction. Rest-only periods and year-view selection were corrected during review.

Validation: 442 Flutter tests passed, including date, selection, accessibility and layout coverage; 40 snapshot tests passed; Flutter analysis reported no issues. Review passed.
