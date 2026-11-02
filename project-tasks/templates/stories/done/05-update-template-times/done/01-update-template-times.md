# TASK 5.1: Update built-in template times

Story: [Update built-in template times](../index.md)

Epic: [Templates](../../../../index.md)

Status: Done on `improve/template-times` in commit `076c3b3`; pending PR and merge.

## Goal

Update the 5 built-in workout templates and fresh-install default fallback settings to the new preparation, work, rest and round values, without changing the template tile UI.

## Scope

- Update `builtInTemplates` in `lib/features/templates/built_in_templates.dart`:
  - `TemplateId.standard` (Default): `0:20` prep, `1:00` work, `0:30` rest, `12` rounds (total `17:50`).
  - `TemplateId.fullAbs` (Full Abs): `0:20` prep, `0:40` work, `0:10` rest, `12` rounds (total `10:10`).
  - `TemplateId.hyrox` (Hyrox): `0:20` prep, `5:00` work, `1:00` rest, `8` rounds (total `47:20`).
  - `TemplateId.stretching` (Stretching): `0:20` prep, `1:00` work, `0:05` rest, `10` rounds (total `11:05`).
  - `TemplateId.strength` (Strength): `0:20` prep, `1:30` work, `0:30` rest, `8` rounds (total `15:50`).
- Update default fallback rounds from `5` to `12` in `lib/features/settings/settings_view_model.dart` and `lib/features/settings/settings_repository.dart` so fresh-install defaults still match `TemplateId.standard`.
- Update affected unit and widget tests (`test/features/templates/built_in_templates_test.dart`, `test/features/templates/templates_view_model_test.dart`, `test/features/settings/`, `test/presentation/home/templates_page_test.dart`, and any other tests referencing the old preset numbers).
- Exclusion: no UI or layout changes to `TemplateTile` or `TemplatesPage` (tracked separately in a future UX redesign task).

## Dependencies

Completed [Story 1](../../01-template-set-and-tiles/index.md) and [Story 2](../../02-selection-follows-settings/index.md) outputs in `master`.

## Acceptance criteria

- All 5 built-in templates match the agreed table in [Story 5](../index.md).
- Fresh-install default settings match the updated `Default` template (`0:20` prep, `1:00` work, `0:30` rest, `12` rounds).
- Tapping each template on the Templates page saves its new values, updates Setup, and passes the new parameters to Start.
- No visual layout changes are made to `TemplateTile`.

## Validation

Run focused unit and widget tests for touched files (`built_in_templates_test.dart`, `templates_view_model_test.dart`, `settings_view_model_test.dart`, `settings_repository_test.dart`, `templates_page_test.dart`), plus `fvm flutter analyze`.

## Implementation context

- `lib/features/templates/built_in_templates.dart`
- `lib/features/settings/settings_view_model.dart`
- `lib/features/settings/settings_repository.dart`
- `test/features/templates/built_in_templates_test.dart`
- `test/presentation/home/templates_page_test.dart`
- Read parent indexes before starting and follow `.agents/skills/skill-orchestrator/SKILL.md`.

## Completion evidence

The five presets and fresh-install defaults were updated. Existing saved settings remain intact. The user approved the implementation; review found no issues. Full Flutter analysis passed, along with 126 focused and snapshot tests.
