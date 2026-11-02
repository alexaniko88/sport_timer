# Timer Setup Start button plan

Branch: `improve/setup-start-button`; base: `aab8441` (`master`).

Replace Setup's floating Start with a fixed, wide themed action while preserving the existing save and launch flow and Templates' floating action. Settings must scroll independently and remain accessible in both supported languages and themes.

Decisions: keep launch ownership in Home and pass a callback to Setup; scope button shape locally instead of changing shared button APIs; preserve Templates layout. Alternatives were moving launch logic, changing shared styling, or changing Templates layout.

- [x] Extract and reuse the current launch callback in Home; show the floating button only on Templates.
- [x] Place a primary Start button below Setup's scrollable settings with card-matching corners and normal bottom spacing.
- [x] Add focused widget coverage for scrolling, clearance, themes, localization, narrow/large text, semantics, launch and other tabs; run existing relevant tests. Both relevant suites passed (59 tests); formatting and analysis passed for touched files.
- [x] Format and analyze touched files, obtain implementation approval, review and address findings. Review passed without findings; full Flutter analysis passed.
- [ ] Complete hand-off and obtain commit approval; offer PR.

Risk: safe-area and bottom-navigation spacing on small screens. Verify with widget geometry and manual validation.

## Scope expansion: session overview

The user selected concept 08: show a localized session length above Start in a themed fixed dock. Reuse `TimerSchedule.totalDuration` so preparation, work and rest follow the actual schedule. Format durations without wrapping at an hour. The displayed scheduled length excludes pauses. Keep the settings independently scrollable and preserve launch behavior.

User refinement: extract the session overview as a private widget; put the spacing outside the card, contain the summary and Start content inside it, and make the whole card one accessible launch action.

- [x] Add derived session duration and localized label/formatting.
- [x] Add the fixed session overview dock and verify narrow screens and large text.
- [x] Test schedule-derived totals, live updates, localization, layout and existing launch behavior; format and analyze touched files. Both relevant suites passed (60 tests); formatting and analysis passed.
