# EPIC: UI refactor

Status: Timer setup grid scope agreed; other UI work remains provisional.

Progress: [Project task status](../status.md).

## Goal

Make the app feel consistent with the current Templates page while allowing Timer Setup to have its own grid layout.

## Agreed behavior and boundaries

- Use the current Templates tile surfaces, border treatment and corner radius as the visual reference. Preserve the existing light and dark themes; do not hard-code the dark mockup's colors.
- Timer Setup retains its four existing settings, selectors, persistence and timer launch behavior.
- Preserve the current shared floating Start button on both Timer Setup and Templates, including appearance and placement.
- The first delivery is the centered timer setup grid. Wheel styling is separate provisional work.
- Other screens, active timer layouts, navigation changes and new features are outside the agreed first delivery. Broader app consistency remains in [IMP-01](../improvements/01-unify-styles-app-wide.md); do not duplicate work between these entries.

## Stories

1. [Timer setup refactor](stories/01-timer-setup-refactor/index.md) — grid ready for planning; wheel styling provisional.

## Delivery order

Deliver Story 1 Task 1.1 as a usable grid connected to existing selectors. Confirm the remaining wheel design before planning Task 1.2. Backlog agreement does not approve application code changes.
