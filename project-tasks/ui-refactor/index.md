# EPIC: UI refactor

Status: Stories 1–4 completed; Story 5 is provisional.


## Goal

Make the app feel consistent and clear across its screens while allowing layouts suited to their content.

## Agreed behavior and boundaries

- Use the current Templates tile surfaces, border treatment and corner radius as the visual reference. Preserve the existing light and dark themes; do not hard-code the dark mockup's colors.
- Timer Setup retains its four existing settings, selectors, persistence and timer launch behavior.
- Story 1 preserves the current Start presentation. Story 2 owns its removal from Templates; Story 3 owns its redesign on Timer Setup.
- The first delivery is the centered timer setup grid. Wheel styling is separate provisional work.
- Other screens, active timer layouts, navigation changes and new features are outside the timer setup grid delivery. Templates navigation is separately agreed in Story 2. App-wide border widths and corner radii belong to Story 4. Remaining app consistency stays in [IMP-01](../improvements/done/01-unify-styles-app-wide.md); do not duplicate work between these entries.

- Home will retain Timer Setup and Statistics; Templates moves to a separate drawer destination under Story 2. Start then exists only on Timer Setup, superseding the shared-Start requirement for that delivery.

## Stories

1. [Timer setup refactor](stories/done/01-timer-setup-refactor/index.md) — all tasks archived; Timer tab update pending PR and merge.

2. [Access Templates from the drawer](stories/done/02-templates-in-drawer/index.md) — all tasks archived; Templates drawer navigation pending PR and merge.
3. [Refactor the Start button](stories/done/03-start-button-refactor/index.md) — Done; archived after the Start action and session overview were implemented.
4. [Unify borders and corner radii across the app](stories/done/04-unify-borders-and-corners/index.md) — Done; shared rules and drawer treatment completed.
5. [Rethink statistics cards and day details](stories/05-statistics-ui-refactor/index.md) — Provisional; design decisions remain open.

## Delivery order

Deliver Story 1 Task 1.1 as a usable grid connected to existing selectors. Task 1.2 has been completed and archived. Backlog agreement does not approve application code changes.

Story 2 is independent of Story 1 and the provisional wheel task. Its Start visibility change applies when Story 2 is delivered; Story 1 alone preserves the current shared Start.

Story 3 can be planned independently of the other pending stories. It changes only Timer Setup's Start presentation and preserves the navigation and Templates Start visibility available in its implementation checkout. Settings scroll above the fixed button; timer-launch behavior stays unchanged.

Story 4 documented the shared values and exceptions delivered in IMP-01 and completed the drawer treatment.

Story 5 can be discussed and planned independently, taking the current statistics checkout and the separately planned visualization story into account.

UI 1.3 replaces the Home house icon with outlined/filled timer icons and renames its label, tooltip and accessible name to Timer / Temporizador. Implemented after UI 3.1 changed Start to play; pending PR and merge. This does not change navigation behavior or require wheel styling or the Templates drawer move.
