# STORY 3: Create your own templates

Epic: [Templates](../../index.md)

A user can save their own workout setups as templates, then apply, edit and delete them like the built-in ones.

## Scope

- In: create, edit and delete own templates from the Templates page; own templates in the list, applied with one tap and highlighted; the Timer Setup label for an own template; device storage.
- Out: saving from the Custom card or from Timer Setup; reordering; sharing or syncing between devices or accounts; showing own template names in Statistics (sessions that match an own template show "Custom", as planned in the UI refactor Story 5); editing built-in templates.

## Requirements

- R1: A "+" (`Icons.add`) in the Templates app bar opens a full-page create form. With 20 own templates, it shows a snackbar instead — TPL-03-07.
- R2: The form has a name field (trimmed, 1 to 30 characters, duplicates allowed), an icon picker with 8 icons, the 4 setting cards (preparation, work, rest, rounds) that open the existing picker wheels with the Timer Setup limits, the session length and a Save button. On create it starts with the current timer settings and the first icon. An empty name on Save shows an error and saves nothing — TPL-03-03.
- R3: Long-press on an own template opens the same form in edit mode, filled with its values. Edit mode has a delete icon (`Icons.delete_outline`) in the app bar that opens a confirm dialog; there is no delete button in the form — TPL-03-03, TPL-03-05, TPL-03-07.
- R4: Own templates are stored on the device (SharedPreferences, JSON), shared by every account on it, kept on sign-out and restart, and lost on uninstall — TPL-03-02.
- R5: Own templates appear after the 5 built-in ones, in creation order; editing keeps the position. Each shows its icon, name, summary and total like a built-in tile — TPL-03-05.
- R6: Tapping an own template applies its values and selects it, like a built-in one. Saving or editing a template never changes the current timer settings — TPL-03-04, TPL-03-05.
- R7: The list highlights the explicit selection when it is still valid; otherwise the first template whose values equal the settings, built-in before own. The Custom card shows only when nothing matches — TPL-03-05.
- R8: Timer Setup shows "Template: <name>" for a selected own template, with the same rules as built-in ones. Renaming it updates the label; changing its values or deleting it clears the selection, and the timer settings stay. After the AppTag change (IMP-05) the label is a tag with the icon and name — TPL-03-04, TPL-03-06.
- R9: A failed save or delete shows a snackbar and keeps the form open with the user's input. A failed load of own templates shows only the built-in ones — TPL-03-04, TPL-03-03.
- R10: Every new text is in English and Spanish; icons and actions have screen reader labels; both themes are covered by snapshots — TPL-03-03, TPL-03-05, TPL-03-06, TPL-03-07.

## Tasks

Order: 2, 4, 5, then 3 and 6 (6 also waits for IMP-05), then 7.

2. [Store custom templates](done/task-02-store-custom-templates/index.md)
3. [Add the template form](task-03-add-template-form/index.md)
4. [Track own templates in settings](task-04-track-own-templates-in-settings/index.md)
5. [Show own templates in the list](task-05-show-own-templates-in-list/index.md)
6. [Show the own template in Timer Setup](task-06-show-own-template-in-setup/index.md)
7. [Open the form from Templates](task-07-open-the-form-from-templates/index.md)

Task 1 (Confirm the creation behavior) was a decision task; its decisions are this story and it was removed.

## Mockup

[mockup.html](mockup.html), approved. States: templates list, list with a long name, create form, create form with empty name error, edit form, delete dialog, save error, limit snackbar. Emoji in the mockup stand in for the Material 3 `Icons.*` named below.

## Shared contracts

All in `lib/features/templates/domain/` unless stated. New names are fixed by this plan.

- `CustomTemplateIcon` (new, `custom_template_icon.dart`): `enum CustomTemplateIcon { weights, running, cycling, swimming, martialArts, gymnastics, yoga, timer }`. Order is the picker order; `weights` is the default. Pure Dart; presentation maps it to `Icons.fitness_center`, `Icons.directions_run`, `Icons.directions_bike`, `Icons.pool`, `Icons.sports_martial_arts`, `Icons.sports_gymnastics`, `Icons.self_improvement`, `Icons.timer` (TPL-03-05).
- `CustomTemplate` (new, `custom_template.dart`): immutable, `final String id; final String name; final CustomTemplateIcon icon; final TimerSettings settings;`, `const` constructor with named required parameters, `copyWith`, `==`, `hashCode`, `Duration get totalTime` (same formula as `WorkoutTemplate.totalTime`), `static const int maxCount = 20`, `static const int maxNameLength = 30`.
- Ids: `custom-<n>`. `CustomTemplateListIds` (new, `extensions/custom_template_list_ids_extension.dart`): `extension CustomTemplateListIds on List<CustomTemplate> { String get nextId }` returns `custom-<n>`, where `n` is 1 plus the highest number of the ids in the list (`custom-1` for an empty list; ids that do not parse are ignored). Built-in ids are `TemplateId.name` (`standard`, `hyrox`…), so the two never clash in `TimerConfiguration.selectedTemplateId`.
- `CustomTemplateRepository` (new, `custom_template_repository.dart`): `Future<Result<List<CustomTemplate>>> getTemplates();` and `Future<Result<void>> saveTemplates(List<CustomTemplate> templates);` (replaces the whole stored list, in order). Implemented by `SharedPreferencesCustomTemplateRepository` in `lib/features/templates/data/` and registered in `lib/di/di.dart` (TPL-03-02).
- `SettingsViewModel` owns the list and the selection (TPL-03-04): the constructor becomes `SettingsViewModel(this._settingsRepository, this._customTemplateRepository)`; `SettingsState` gains `customTemplates` and `selectedCustomTemplate`; methods `selectCustomTemplate`, `saveCustomTemplate` and `deleteCustomTemplate` (signatures in TPL-03-04).
- `CustomTemplateIconData` (`IconData get iconData` on `CustomTemplateIcon`) and the snapshot harness parameter `configureFakeDependencies(customTemplates:)` come from TPL-03-05 and are used by TPL-03-06 and TPL-03-03.
- Sample own template for goldens and tests: `custom-1` "Tabata", `timer`, 0:10 / 0:20 / 0:10 / 8 rounds.
- Test fake (new, TPL-03-02): `test/features/templates/fake_custom_template_repository.dart`, `class FakeCustomTemplateRepository implements CustomTemplateRepository` with `List<CustomTemplate> stored`, `bool failLoad`, `bool failSave` and `int saveCalls`. Every test that builds a `SettingsViewModel` uses it.
