# Notes

## Summary

- `TemplatesState` has `customTemplates` and `selectedCustomTemplateId`. `TemplatesViewModel` builds its state from the settings and picks the highlight: explicit built-in selection, then explicit own selection, then the first matching built-in, then the first matching own template.
- `applyCustomTemplate` selects an own template.
- The templates page lists own templates after the built-ins, each with `ValueKey(id)`. The Custom card shows only when no template is selected and the page is not loading.
- `AppSurface` and `TemplateTile` have an `onLongPress`, announced as "Edit template" (new ARB key in both languages).
- A new `CustomTemplateIconData` extension maps own-template icons.
- Test fix (`560ccaa`): "returning to Statistics preserves the chart and period" in `templates_page_test.dart` failed on `master` too. It used an empty activity fake, so the Charts tab never appeared. The test now uses one day of activity data. This file was not in the task's `touches` list.

## Evidence

- Own templates follow the settings state: `test/features/templates/presentation/templates_view_model_test.dart` "own templates follow the settings state" — passed
- Explicit own selection wins: same file — passed
- Explicit built-in selection wins: same file — passed
- Matching prefers built-in templates: same file — passed
- No match shows Custom: same file — passed
- Applying an own template selects it: same file — passed
- Long press is announced as "Edit template": `test/features/templates/presentation/widgets/template_tile_test.dart` — passed
- Golden `test/snapshots/goldens/templates_own.png` (light and dark) created and viewed; existing `templates_selected.png` and `templates_custom.png` unchanged
- Full `fvm dart tool/agent_check.dart --skip-build` — passed

## Points to review

- `test/snapshots/README.md:92`: the Tabata row describes `0:10 prep · 0:20 work · 0:10 rest · 8 rounds`, but the golden shows `0:20 work · 0:10 rest · 8 rounds`. The row also leaves out the `4m 0s` and `10m 0s` totals that the other rows list.
- `lib/features/templates/presentation/templates_state.dart:21`: `copyWith` has no `selectedCustomTemplateId` parameter. Calling `copyWith(selectedTemplateId: ...)` keeps the old own-template id, so both ids could be set. Nothing calls it that way today.
- `test/features/templates/presentation/templates_page_test.dart`: the fix in `560ccaa` is outside the task's `touches` list (see Summary).
- On the main checkout, `master` has a commit `c389632 chore: bump planner_dispatcher to v0.1.2 (#113)` that I did not make. It is worth checking who made it.

## Run

implementer: Claude Sonnet 5.5; tests: Claude Sonnet 5.5; reviewer: Claude Opus 5.5
