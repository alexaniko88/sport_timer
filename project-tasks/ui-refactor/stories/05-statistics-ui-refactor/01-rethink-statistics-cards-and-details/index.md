---
id: UI-05-01
status: draft
type: feat
depends-on: []
---

# Rethink statistics cards and details

Story: [Rethink statistics cards and day details](../index.md)

Epic: [UI refactor](../../../index.md)

## Goal

Refactor the statistics UI so daily activity and individual runs are clear and pleasant to review.

## Current behavior

Daily cards show a date, rounds, work, rest and total. Tapping a card opens a day-details page with the daily total and one card per run; each run card separates activity on that day from its original configuration. The captured layouts present these values as compact text lists.

## Scope and exclusions

- Reconsider the visual hierarchy and layout of the daily cards, daily total and run details as one coherent experience.
- Preserve the existing meaning and availability of the statistics, including selected-day values versus whole-run configuration; discuss any proposed change to displayed fields or navigation first.
- Do not change activity recording, calculations, storage or introduce charts and calendar in this task. The [visual activity story](../../../../statistics/stories/04-visualize-activity/index.md) owns its separately agreed scope.

## Dependencies

None. Inspect the current checkout and the visual activity story when planning to avoid conflicting UI changes.

## Open decisions

- Which information should stand out on a daily card and on each run card?
- What layout and visual treatment should the details page use, and should navigation change?
- How should the design handle long values, multiple runs, empty and error states, and accessibility?

## Acceptance criteria

- The user has agreed the design and information hierarchy before implementation.
- Daily cards and day details use the agreed design in light and dark themes, and a user can open a day and return to the list.
- Daily totals and separate runs remain understandable, with selected-day activity clearly distinguished from original run settings.
- The changed UI remains usable with long content, larger text and assistive technology; applicable loading, empty and error states remain usable.

## Validation

Check the agreed design against representative daily and multi-run data, including a run spanning days. Run relevant widget and accessibility tests. Refresh affected UI snapshots and update the snapshot index for changed states or navigation, following the [snapshot reference](../../../../../test/snapshots/README.md).

## Implementation context and visual reference

Check the implementation checkout before planning. Current presentation entry points include `lib/features/statistics/presentation/statistics_page.dart`, `day_details_page.dart`, `widgets/daily_activity_tile.dart` and `widgets/run_activity_summary_tile.dart`.

Inspect [daily cards](../../../../../test/snapshots/goldens/statistics.png), [day details](../../../../../test/snapshots/goldens/day_details.png), and their [empty](../../../../../test/snapshots/goldens/statistics_empty.png) and [error](../../../../../test/snapshots/goldens/statistics_error.png) list states and [empty](../../../../../test/snapshots/goldens/day_details_empty.png) and [error](../../../../../test/snapshots/goldens/day_details_error.png) detail states. These capture light and dark themes at one phone size in English; they do not establish larger-text or screen-reader coverage. They are a baseline, not an approved redesign. This task does not authorize application code changes.
