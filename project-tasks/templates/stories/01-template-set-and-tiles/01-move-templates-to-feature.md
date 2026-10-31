# TASK 1.1: Move templates into a feature folder

Story: [Story 1 overview](index.md)

Epic: [Templates](../../index.md)

Status: Done — implementation and checks complete; user approved delivery on 2026-10-31.

## Goal

Template data and the total-time calculation live outside the page widget, in a plain feature folder, with the new set of 5 templates.

## Scope

- Create the template data and the total-time calculation under `lib/features/` (a `templates` feature), following the existing feature-first layout. Views must not own this logic.
- Define the 5 templates and their values from the [epic](../../index.md): Default, Full Abs, Hyrox, Stretching, Strength. Remove CrossFit and the per-template accent.
- Add localized names for each template in the English and Spanish ARB files. Remove the unused description texts and the old CrossFit and "applied badge" texts only when nothing uses them any more.
- Out of scope: the tile, the page, and the selected-state logic.

## Dependencies

None.

## Acceptance criteria

- The 5 templates exist as constant data with the exact values in the epic table.
- The total time of each template matches the epic table (7:20, 13:30, 35:50, 9:55, 11:40).
- The calculation is not duplicated, and the page can reuse it later.
- English and Spanish names exist for all 5 templates, and `fvm flutter analyze` is clean.

## Validation

Unit tests for the total-time calculation and for the template list (count, order, values), under `test/features/templates/`, mirroring `lib/`. Run only the files touched, plus `fvm flutter analyze`.

## Implementation context

Current templates and the total-time method are in `lib/presentation/home/templates_page.dart`. The `TimerSettings` type is in `lib/features/settings/settings_repository.dart`. Texts are in `lib/l10n/app_en.arb` and `lib/l10n/app_es.arb`. Read the parent indexes and follow `.agents/skills/skill-orchestrator/SKILL.md`.
