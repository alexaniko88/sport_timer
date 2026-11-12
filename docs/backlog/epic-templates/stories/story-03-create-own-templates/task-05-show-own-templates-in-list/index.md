---
id: TPL-03-05
status: ready
type: feat
complexity: 5
depends-on: [TPL-03-04, IMP-05]
touches:
  - lib/features/templates/presentation/templates_state.dart
  - lib/features/templates/presentation/templates_view_model.dart
  - lib/features/templates/presentation/templates_page.dart
  - lib/features/templates/presentation/widgets/template_tile.dart
  - lib/features/templates/presentation/extensions/custom_template_icon_extension.dart
  - lib/shared/presentation/widgets/app_surface.dart
  - lib/l10n/
  - test/features/templates/presentation/templates_view_model_test.dart
  - test/features/templates/presentation/widgets/template_tile_test.dart
  - test/snapshots/ui_snapshots_test.dart
  - test/snapshots/README.md
  - test/snapshots/goldens/templates_own.png
skills: []
---

# Show own templates in the list

Story: [Create your own templates](../index.md)

Epic: [Templates](../../../index.md)

## Goal

The Templates page lists own templates after the built-in ones; a tap applies one, the matching one is highlighted, and the tile supports a long press that Open the form from Templates (TPL-03-07) wires to the edit form. Serves R5, R6 and R7, and R10 for the tile.

## Context

- `lib/features/templates/presentation/templates_view_model.dart` (`_stateFor` matches only `builtInTemplates`), `templates_state.dart`, `templates_page.dart` (built-in loop, Custom card when `selectedTemplateId == null`).
- `lib/features/templates/presentation/widgets/template_tile.dart`: `TemplateTile` wraps `AppSurface` in a `Semantics(container, button, selected, onTap, excludeSemantics, label: templateTileSemantics(...))`.
- `lib/shared/presentation/widgets/app_surface.dart`: `InkWell` only when `onTap` is set.
- Runs after Add a shared AppTag widget and use it on Timer Setup (IMP-05), which moves the built-in icon `switch` of `templates_page.dart` into `template.id.icon` (`TemplateIcon` extension).
- References: [templates_selected.png](../../../../../../test/snapshots/goldens/templates_selected.png), [templates_custom.png](../../../../../../test/snapshots/goldens/templates_custom.png); approved [mockup](../mockup.html), states "Templates list" and "Own template with a long name".

## Contract

- `SettingsState.customTemplates`, `SettingsState.selectedCustomTemplate`, `SettingsViewModel.selectCustomTemplate` — provided by TPL-03-04.
- `CustomTemplate`, `CustomTemplateIcon`, `FakeCustomTemplateRepository` — provided by TPL-03-02.
- `CustomTemplateIconData` — new here, `extensions/custom_template_icon_extension.dart`: `extension CustomTemplateIconData on CustomTemplateIcon { IconData get iconData }` with the mapping in the story's shared contracts. Also used by TPL-03-03.
- `TemplatesState` — changed here: adds `List<CustomTemplate> customTemplates` and `String? selectedCustomTemplateId`; `==` uses `listEquals`. Exactly one of `selectedTemplateId` / `selectedCustomTemplateId` is set when something matches.
- `TemplatesViewModel` — changed here: `_stateFor` takes the whole `SettingsState` instead of `TimerSettings` and applies the highlight rule in the View spec (today it only compares `timerSettings` with `builtInTemplates`).
- `TemplatesViewModel.applyCustomTemplate(CustomTemplate template)` — new here: forwards to `selectCustomTemplate` unless disposed.
- Snapshot harness — changed here: `configureFakeDependencies` gains `List<CustomTemplate> customTemplates = const []`, stored into the harness's `FakeCustomTemplateRepository` (registered by TPL-03-04). TPL-03-06 and TPL-03-03 use it.
- `AppSurface.onLongPress` — new here: optional `VoidCallback?`, passed to the `InkWell`; the `InkWell` is built when `onTap` or `onLongPress` is set.
- `TemplateTile.onLongPress` — new here: optional `VoidCallback?`, passed to `AppSurface`, and to the `Semantics` as `onLongPress` with `onLongPressHint: l10n.templateEditHint`. `TemplatesPage` leaves it `null` for now; TPL-03-07 sets it on own tiles.

## View spec

- Own tiles follow the built-ins in `customTemplates` order, with the same `Gap(AppSpacing.s8)`, the same `TemplateTile` (icon from `iconData`, `name`, summary, total, phase bar) and key `ValueKey(template.id)`. A long name stays on one line with an ellipsis.
- Highlight (R7), computed in `_stateFor(SettingsState s)`: if `s.selectedTemplateId` is set, that built-in is highlighted; else if `s.selectedCustomTemplate` is set, that own template (by id); else the first built-in in `builtInTemplates` order, then the first own template in list order, whose settings equal `s.timerSettings`. The Custom card shows only when none of these matches. Loading stays in the page as today: `TemplatesPage` computes `isLoading` from `SettingsState.status` (`initial` or `loading`) and then shows no highlight and no Custom card; `_stateFor` does not handle loading.
- Tap on an own tile calls `_templatesViewModel.applyCustomTemplate(template)`, like built-in tiles call `_templatesViewModel.applyTemplate`; the page stays open.
- Strings: `templateEditHint` — en "Edit template", es "Editar plantilla" (description: "Accessibility hint for the long press on an own template tile.").
- Both themes; no new colors or tokens.

## Mockup

[mockup.html](../mockup.html): "Templates list with one own template (selected)" and "Own template with a long name". The "+" in the app bar belongs to TPL-03-03.

## Out of scope

- The "+" button, the form, long-press wiring and navigation (TPL-03-03).

## Files and tests

- New: `custom_template_icon_extension.dart`.
- Unit: `templates_view_model_test.dart` (cases below).
- Component: `template_tile_test.dart` gains one semantics case for the long press (reason: the hint and action are not visible in a golden).
- New golden scenario `templates page with an own template selected` (`templates_own`): `TemplatesPage` with two own templates stored — `custom-1` "Tabata" (`timer`, 0:10 / 0:20 / 0:10 / 8) and `custom-2` "Kettlebell circuit for the gym" (30 characters, the maximum; `weights`, 0:15 / 0:45 / 0:15 / 10) — and `custom-1` selected: call `configureFakeDependencies(settings: <Tabata settings>, selectedTemplateId: 'custom-1', customTemplates: [...])`. Add its row to `test/snapshots/README.md` under Templates.
- Run `fvm flutter gen-l10n` after editing both ARB files.

## Acceptance

- [ ] Given two own templates, when the state is built, then `customTemplates` lists them in stored order, and it updates when the settings state changes. Check: `test/features/templates/presentation/templates_view_model_test.dart` "own templates follow the settings state".
- [ ] Given an own template is the explicit selection, when the state is built, then `selectedCustomTemplateId` is its id even if a built-in template has the same values. Check: `test/features/templates/presentation/templates_view_model_test.dart` "explicit own selection wins".
- [ ] Given an explicit built-in selection, when the state is built, then `selectedTemplateId` is that id and `selectedCustomTemplateId` is null, even if an own template has the same values. Check: `test/features/templates/presentation/templates_view_model_test.dart` "explicit built-in selection wins".
- [ ] Given no explicit selection and settings equal to an own template and to no built-in, when the state is built, then that own template is highlighted; equal to both, the built-in wins. Check: `test/features/templates/presentation/templates_view_model_test.dart` "matching prefers built-in templates".
- [ ] Given settings that match nothing, when the state is built, then both ids are null (Custom card). Check: `test/features/templates/presentation/templates_view_model_test.dart` "no match shows Custom".
- [ ] When `applyCustomTemplate` runs, then the settings view model selects that template. Check: `test/features/templates/presentation/templates_view_model_test.dart` "applying an own template selects it".
- [ ] When a tile has `onLongPress`, then its semantics expose a long-press action with the hint "Edit template". Check: `test/features/templates/presentation/widgets/template_tile_test.dart` "long press is announced as edit".
- [ ] When the page shows own templates with one selected, then they appear after the built-ins with their icons, the 30-character name ends with an ellipsis on one line and the selected one has the selected border, in both themes. Check: `test/snapshots/goldens/templates_own.png`.
- [ ] When the checks run, then everything passes and `templates_selected.png` and `templates_custom.png` are unchanged. Check: `fvm dart tool/agent_check.dart --skip-build`.
