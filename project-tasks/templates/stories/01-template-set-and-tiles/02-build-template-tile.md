# TASK 1.2: Build the compact template tile

Story: [Story 1 overview](index.md)

Epic: [Templates](../../index.md)

Status: Blocked by Task 1.1.

## Goal

A reusable tile widget that shows one template, or one set of timer values, in the new compact style.

## Scope

- Icon, name, summary line (`1:00 work · 0:30 rest · 5 rounds`), total time on the right, and a thin phase bar at the bottom.
- The phase bar uses the preparation, round and rest colors from the app's timer colors, with segment widths proportional to the real durations. Rest is shown once per round gap, consistent with the total-time formula.
- Built only on shared tokens (`AppSpacing`, `AppRadius`, theme text styles, `timerColors`). Works in light and dark theme.
- Accept a state for "selected" and for "custom", so Story 2 can reuse the same widget without redesigning it. Do not implement the computed selection here.
- Semantics label that reads the name and the values for screen readers.
- Add the summary-line texts in English and Spanish.
- Out of scope: the page layout, the tap behavior, and the Custom card styling.

## Dependencies

[Task 1.1](01-move-templates-to-feature.md).

## Acceptance criteria

- The tile shows correct values for all 5 templates, and the phase bar proportions follow the durations (Hyrox rounds look much longer than Full Abs rounds).
- Long Spanish names and summary lines do not overflow on a narrow phone.
- It has no gradients or per-template accent colors, and it looks like the Setup page in both themes.
- A screen reader announces name, round time, rest time, rounds and total time.

## Validation

Widget tests for the tile (texts, semantics, selected and custom states) under `test/presentation/`, mirroring `lib/`. Read a nearby widget test first and copy its structure. Run only the touched files, plus `fvm flutter analyze`.

## Implementation context

Shared pieces: `lib/presentation/widgets/` and the theme and `timerColors` extension used by `lib/presentation/home/timer_setup_page.dart`. Read the parent indexes and follow `.agents/skills/skill-orchestrator/SKILL.md`.
