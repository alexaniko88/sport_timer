# STORY 5: Rethink statistics cards and day details

Epic: [UI refactor](../../index.md)

## User outcome

As a user reviewing my training, I want each day's card to show its totals at a glance and to open in place to show that day's sessions, so I can read my activity without leaving the list.

## Scope

The daily cards on the Statistics `List` tab and the day details. The cards get a compact total, a colored rounds · work · rest line and a work/rest bar. A card expands in place (one at a time) to list the day's sessions as flat rows, each with a template tag; the separate `/day-details` page is removed. The original run configuration is no longer shown. Recorded data, calculations, the `Charts` view and the calendar are not changed.

## Acceptance criteria

- The daily cards and the expanded sessions follow the [approved mockup](task-01-rethink-statistics-cards-and-details/mockup.html) in light and dark themes, English and Spanish.
- A user can open a day in place, see each session with its template (or `Custom`), and close it again; only one day is open at a time.
- Loading, empty and error states of a day, screen reader labels with full words, and large text on narrow screens work.

## Tasks

1. [Rethink statistics cards and details](task-01-rethink-statistics-cards-and-details/index.md).

## Dependencies and open decisions

Task 1 depends on [IMP-05](../../../improvements/task-05-add-shared-app-tag/index.md), which adds the shared `AppTag` used in the session rows. No open decisions. Charts and the calendar belong to the separate [visual activity story](../../../epic-statistics/stories/done/story-04-visualize-activity/index.md).
