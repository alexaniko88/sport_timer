# STORY 5: Update built-in template times

Epic: [Templates](../../../index.md)

Status: Done on `improve/template-times`; pending PR and merge.

## User outcome

As a user, I want the 5 built-in workout templates to use realistic preparation, work, rest and round values so that each preset matches a practical workout session out of the box.

## Agreed behavior and scope

- Update all 5 built-in templates in `lib/features/templates/built_in_templates.dart` so every template uses `0:20` preparation time and the new work, rest and round values:

| Template | Preparation | Work (Round) | Rest | Rounds | Total |
| --- | --- | --- | --- | --- | --- |
| Default | 0:20 | 1:00 | 0:30 | 12 | 17:50 |
| Full Abs | 0:20 | 0:40 | 0:10 | 12 | 10:10 |
| Hyrox | 0:20 | 5:00 | 1:00 | 8 | 47:20 |
| Stretching | 0:20 | 1:00 | 0:05 | 10 | 11:05 |
| Strength | 0:20 | 1:30 | 0:30 | 8 | 15:50 |

- Update the initial default fallback rounds in `SettingsViewModel` and `SharedPreferencesSettingsRepository` from `5` to `12` so a fresh install continues to match the `Default` template (`0:20` preparation, `1:00` work, `0:30` rest, `12` rounds).
- Update existing unit and widget tests that assert the built-in template values, total times, or initial default settings.

Out of scope: any UI/UX changes to `TemplateTile` or `TemplatesPage` (such as showing preparation on the tile, changing the summary layout, or removing the phase bar). Those belong to a separate UX redesign task.

## Acceptance criteria

- All 5 built-in templates in `builtInTemplates` store and apply the updated `preparationTime`, `roundTime`, `restTime` and `rounds` values, with total times `17m 50s`, `10m 10s`, `47m 20s`, `11m 5s` and `15m 50s`.
- A fresh install with no saved settings starts with the updated Default values (`0:20` prep, `1:00` work, `0:30` rest, `12` rounds), so the Default template is highlighted on Templates without showing Custom.
- Existing template tile UI, summary format and phase bar remain unchanged.
- All affected unit and widget tests pass with the updated numbers.

## Tasks

1. [Update built-in template times](done/01-update-template-times.md).

## Dependencies and open decisions

Depends on completed [Story 1](../01-template-set-and-tiles/index.md) and [Story 2](../02-selection-follows-settings/index.md) outputs in `master`. No open decisions.
