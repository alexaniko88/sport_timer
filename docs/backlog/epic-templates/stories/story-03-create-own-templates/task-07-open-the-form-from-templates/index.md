---
id: TPL-03-07
status: ready
type: feat
complexity: 3
depends-on: [TPL-03-03]
touches:
  - lib/features/templates/presentation/templates_page.dart
  - lib/l10n/
  - test/features/templates/presentation/templates_page_test.dart
  - test/snapshots/README.md
  - test/snapshots/goldens/templates_selected.png
  - test/snapshots/goldens/templates_custom.png
  - test/snapshots/goldens/templates_own.png
skills: []
---

# Open the form from Templates

Story: [Create your own templates](../index.md)

Epic: [Templates](../../../index.md)

## Goal

The Templates page opens the template form: "+" in the app bar for create (with a snackbar at 20 own templates), and a long press on an own tile for edit. Serves R1 and R3, and R10 for the "+".

## Context

- `lib/features/templates/presentation/templates_page.dart`: its `AppBar` has only the title; own tiles leave `TemplateTile.onLongPress` null (TPL-03-05). The page's field is `final SettingsViewModel viewModel` (`widget.viewModel`).
- Navigation pattern: `lib/features/home/presentation/home_page.dart` `_openTemplates` uses `context.pushNamed(RoutePath.templates.value, extra: _viewModel)`.
- `templates_page_test.dart` already builds the app around `HomePage` with `getIt` fakes; `CustomTemplateRepository` is registered there by TPL-03-04.

## Contract

- `RoutePath.templateForm`, `TemplateFormArgs`, `TemplateFormPage` — provided by TPL-03-03.
- `SettingsState.customTemplates`, `CustomTemplate.maxCount` — provided by TPL-03-04 / TPL-03-02. `TemplateTile.onLongPress` — provided by TPL-03-05.

## View spec

- App bar `actions:` `IconButton(icon: const Icon(Icons.add), tooltip: l10n.templatesAddTooltip)`, then `SizedBox(width: AppSpacing.s8)`.
- "+" tap: with `customTemplates.length >= CustomTemplate.maxCount`, `ScaffoldMessenger` shows `templatesLimitReached(CustomTemplate.maxCount)` and nothing opens; otherwise `context.pushNamed(RoutePath.templateForm.value, extra: TemplateFormArgs(settingsViewModel: widget.viewModel))`.
- Own tile long press: the same push with `template: <that template>`. Built-in tiles and the Custom card get no long press.
- Back from the form returns to Templates; the list follows the settings state, so saved changes show at once.
- Strings (en / es, English with a `description`):
  - `templatesAddTooltip`: "New template" / "Nueva plantilla"
  - `templatesLimitReached`: "You can save up to {count} templates." / "Puedes guardar hasta {count} plantillas." (`count`: `int`)
- Both themes.

## Mockup

[mockup.html](../mockup.html): "Templates list" (the "+") and "'+' with 20 own templates".

## Out of scope

- The form itself (TPL-03-03).

## Files and tests

- Widget: `templates_page_test.dart` gains the cases below (reason: navigation and snackbars cannot be checked by goldens). Fill the registered `FakeCustomTemplateRepository.stored` before the page is built, because `HomePage` loads settings in `initState`.
- Goldens: refresh `templates_selected`, `templates_custom` and `templates_own` (the "+" appears); no harness change. Update their rows in `test/snapshots/README.md` with the "+" → `/template-form` and long-press flows.
- Run `fvm flutter gen-l10n` after editing both ARB files.

## Acceptance

- [ ] Given fewer than 20 own templates, when "+" is tapped, then the create form opens. Check: `test/features/templates/presentation/templates_page_test.dart` "add opens the create form".
- [ ] Given 20 own templates, when "+" is tapped, then the snackbar "You can save up to 20 templates." shows and no page opens. Check: `test/features/templates/presentation/templates_page_test.dart` "add shows the limit at 20".
- [ ] When an own tile is long-pressed, then the edit form opens with its name; a built-in tile does nothing on long press. Check: `test/features/templates/presentation/templates_page_test.dart` "long press edits own templates only".
- [ ] When a screen reader reads the app bar, then the "+" is a button labelled "New template". Check: `test/features/templates/presentation/templates_page_test.dart` "add button is labelled".
- [ ] When the Templates page is shown with a built-in selected, then the "+" is in the app bar in both themes. Check: `test/snapshots/goldens/templates_selected.png`.
- [ ] When the Templates page shows the Custom card, then the "+" is in the app bar. Check: `test/snapshots/goldens/templates_custom.png`.
- [ ] When the Templates page shows own templates, then the "+" is in the app bar. Check: `test/snapshots/goldens/templates_own.png`.
- [ ] When the checks run, then everything passes, including `gen-l10n`. Check: `fvm dart tool/agent_check.dart --skip-build`.
