# STORY 5: Rethink statistics cards and day details

Epic: [UI refactor](../../index.md)

As a user reviewing my training, I want each day's card to show its totals at a glance and to open in place to show that day's sessions, so I can read my activity without leaving the list.

## Scope

- In: the daily cards on the Statistics `List` tab and the day details. The cards get a compact total, a colored rounds · work · rest line and a work/rest bar. A card opens in place (one at a time) to list the day's sessions as flat rows, each with a template tag; the separate `/day-details` page is removed.
- Out: the original run configuration is no longer shown. Recorded data, calculations, the `Charts` view and the consistency calendar do not change; they belong to the separate [visual activity story](../../../epic-statistics/stories/done/story-04-visualize-activity/index.md).

## Requirements

- R1: Each daily card shows the date, a compact total, a colored rounds · work · rest line and a work/rest bar — UI-05-01 (compact durations), UI-05-02.
- R2: A card opens and closes in place to list that day's sessions as flat rows, each with its template tag (or `Custom`); only one day is open at a time, and all start closed — UI-05-01 (open-day state, template match), UI-05-02.
- R3: The separate day details page and its route are removed, and the original run configuration is no longer shown — UI-05-02.
- R4: An open day handles loading, empty and error states, with Retry — UI-05-01 (state rules), UI-05-02.
- R5: The cards and sessions follow the [approved mockup](mockup.html) in light and dark themes, English and Spanish; screen reader labels use full words; large text on narrow screens does not overflow — UI-05-02.

## Tasks

1. [Prepare the statistics card state](task-01-prepare-statistics-card-state/index.md)
2. [Rethink statistics cards and details](task-02-rethink-statistics-cards-and-details/index.md)

## Shared contracts

- Prepare the statistics card state (UI-05-01) provides `compactStatisticsDuration`, `TimerSession.matchingTemplateId`, the `StatisticsState` open-day fields and `StatisticsViewModel.toggleDay` / `retryDay`. It is unwired; Rethink statistics cards and details (UI-05-02) wires them into the cards and page.
- UI-05-02 also uses `AppTag` and `TemplateId.icon` from [Add a shared AppTag widget and use it on Timer Setup (IMP-05)](../../../improvements/task-05-add-shared-app-tag/index.md).
