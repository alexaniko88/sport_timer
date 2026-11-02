# EPIC: UI refactor

Status: Timer setup grid, Templates navigation, Start button refactor and app-wide border/radius scope agreed; Timer tab icon and naming agreed after the Start refactor; wheel styling remains provisional.

Progress: [Project task status](../status.md).

## Goal

Make the app feel consistent with the current Templates page while allowing Timer Setup to have its own grid layout.

## Agreed behavior and boundaries

- Use the current Templates tile surfaces, border treatment and corner radius as the visual reference. Preserve the existing light and dark themes; do not hard-code the dark mockup's colors.
- Timer Setup retains its four existing settings, selectors, persistence and timer launch behavior.
- Story 1 preserves the current Start presentation. Story 2 owns its removal from Templates; Story 3 owns its redesign on Timer Setup.
- The first delivery is the centered timer setup grid. Wheel styling is separate provisional work.
- Other screens, active timer layouts, navigation changes and new features are outside the timer setup grid delivery. Templates navigation is separately agreed in Story 2. App-wide border widths and corner radii belong to Story 4. Remaining app consistency stays in [IMP-01](../improvements/01-unify-styles-app-wide.md); do not duplicate work between these entries.

- Home will retain Timer Setup and Statistics; Templates moves to a separate drawer destination under Story 2. Start then exists only on Timer Setup, superseding the shared-Start requirement for that delivery.

## Stories

1. [Timer setup refactor](stories/01-timer-setup-refactor/index.md) — grid task archived; wheel styling provisional; timer tab icon and label blocked by UI 3.1.

2. [Access Templates from the drawer](stories/02-templates-in-drawer/index.md) — Ready for planning; one navigation task.
3. [Refactor the Start button](stories/03-start-button-refactor/index.md) — Ready for planning; one UI task for a fixed, wide primary action on Timer Setup.
4. [Unify borders and corner radii across the app](stories/04-unify-borders-and-corners/index.md) — audit and rule decision ready for planning; app-wide migration blocked by that decision.

## Delivery order

Deliver Story 1 Task 1.1 as a usable grid connected to existing selectors. Confirm the remaining wheel design before planning Task 1.2. Backlog agreement does not approve application code changes.

Story 2 is independent of Story 1 and the provisional wheel task. Its Start visibility change applies when Story 2 is delivered; Story 1 alone preserves the current shared Start.

Story 3 can be planned independently of the other pending stories. It changes only Timer Setup's Start presentation and preserves the navigation and Templates Start visibility available in its implementation checkout. Settings scroll above the fixed button; timer-launch behavior stays unchanged.

Story 4 can audit the current app independently. Agree shared values and exceptions in UI 4.1 before UI 4.2 migrates the app. Coordinate those rules with pending UI stories without taking on their layout or behavior changes.

UI 1.3 replaces the Home house icon with outlined/filled timer icons and renames its label, tooltip and accessible name to Timer / Temporizador. Deliver after UI 3.1 changes Start to play. This does not change navigation behavior or require wheel styling or the Templates drawer move.
