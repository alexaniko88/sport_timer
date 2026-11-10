# STORY 3: Refactor the Start button

Epic: [UI refactor](../../../index.md).

## User outcome

As a user, I want a clear Start action below my timer settings so I can launch the workout without the button covering those settings.

## Agreed design and scope

- On Timer Setup, replace the floating Start button with a wide button fixed above the bottom navigation, outside the settings scroll area.
- Use the current theme's primary filled-button style, rounded corners matching the setting cards, a play icon and the existing localized Start label. Support both light and dark themes without hard-coded mockup colors.
- Keep settings scrollable with space reserved for Start and bottom navigation. All settings and the button remain reachable on small screens and with large text.
- Preserve current timer-launch behavior, current settings and timer-style parameters, and the existing save flow. This is a UI refactor only; new confirmation, loading, debounce or launch rules are outside scope.
- This story changes Start only on Timer Setup. Removing Start from Templates belongs to [Story 2](../story-02-templates-in-drawer/index.md). If that story is still pending, preserve Templates' current floating button. If it has shipped, preserve the separate Templates page without Start.
- Exclude navigation changes, picker styling, setting-card redesign and active-timer controls.

## Acceptance criteria

- Timer Setup shows one wide primary Start button with a play icon and localized label, fixed above bottom navigation.
- The button uses the agreed theme and corner treatment in both themes.
- Scrolling settings does not move Start; the final setting remains fully reachable without being covered by Start or navigation.
- Small screens, large text and English/Spanish labels remain usable without clipped button content.
- Accessible activation exposes one clearly labeled Start action and launches the timer with current settings and timer style, preserving the existing save/launch flow.
- Templates' Start visibility and navigation remain as supplied by the implementation checkout; this story neither removes nor adds its Start action.

## Tasks

1. [Replace Timer Setup's floating Start button](done/task-01-refactor-timer-setup-start-button/index.md) — Done.

## Dependencies and open decisions

No product decisions remain. This story can be planned independently of the grid, wheel and Templates navigation tasks. Verify the implementation checkout: [Story 1](../story-01-timer-setup-refactor/index.md) preserves Start during grid delivery, while Story 2 separately controls Templates navigation and Start visibility. Preserve whichever work is already available and ensure the fixed button fits the existing rows or delivered grid. Exact sizing, spacing and widget ownership belong to implementation planning. Backlog agreement does not approve application code changes.
