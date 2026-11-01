# EPIC: UI refactor

Status: Timer setup grid and Templates navigation scope agreed; wheel styling remains provisional.

Progress: [Project task status](../status.md).

## Goal

Make the app feel consistent with the current Templates page while allowing Timer Setup to have its own grid layout.

## Agreed behavior and boundaries

- Use the current Templates tile surfaces, border treatment and corner radius as the visual reference. Preserve the existing light and dark themes; do not hard-code the dark mockup's colors.
- Timer Setup retains its four existing settings, selectors, persistence and timer launch behavior.
- Preserve the current shared floating Start button on both Timer Setup and Templates, including appearance and placement.
- The first delivery is the centered timer setup grid. Wheel styling is separate provisional work.
- Other screens, active timer layouts, navigation changes and new features are outside the timer setup grid delivery. Templates navigation is separately agreed in Story 2. Broader app consistency remains in [IMP-01](../improvements/01-unify-styles-app-wide.md); do not duplicate work between these entries.

- Home will retain Timer Setup and Statistics; Templates moves to a separate drawer destination under Story 2. Start then exists only on Timer Setup, superseding the shared-Start requirement for that delivery.

## Stories

1. [Timer setup refactor](stories/01-timer-setup-refactor/index.md) — grid ready for planning; wheel styling provisional.

2. [Access Templates from the drawer](stories/02-templates-in-drawer/index.md) — Ready for planning; one navigation task.

## Delivery order

Deliver Story 1 Task 1.1 as a usable grid connected to existing selectors. Confirm the remaining wheel design before planning Task 1.2. Backlog agreement does not approve application code changes.

Story 2 is independent of Story 1 and the provisional wheel task. Its Start visibility change applies when Story 2 is delivered; Story 1 alone preserves the current shared Start.
