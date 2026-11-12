---
id: TPL-03-04
status: ready
type: feat
complexity: 6
depends-on: [TPL-03-02]
touches:
  - lib/features/settings/presentation/settings_view_model.dart
  - lib/features/settings/presentation/settings_state.dart
  - lib/features/home/presentation/home_page.dart
  - test/features/settings/presentation/settings_view_model_test.dart
  - test/features/settings/presentation/timer_settings_persistence_test.dart
  - test/features/home/presentation/home_page_test.dart
  - test/features/templates/presentation/templates_view_model_test.dart
  - test/features/templates/presentation/templates_page_test.dart
  - test/snapshots/ui_snapshots_test.dart
skills: []
---

# Track own templates in settings

Story: [Create your own templates](../index.md)

Epic: [Templates](../../../index.md)

## Goal

`SettingsViewModel` loads, saves and deletes own templates, and its saved selection accepts an own template. No screen changes yet. Serves R6, R8 and R9 (state part).

## Context

- `lib/features/settings/presentation/settings_view_model.dart`: `_readSettings`, `selectTemplate`, `_validated`, `_currentConfiguration`, `_setConfiguration`, `flushSettings`, `_updateTimerSettings`. Today the selection is `TemplateId? _selectedTemplateId`; `_currentConfiguration` writes `_selectedTemplateId?.name`; `_setConfiguration` parses the id with `TemplateId.values.asNameMap()`; `_validated` only accepts built-in ids.
- `lib/features/settings/presentation/settings_state.dart`: `selectedTemplateId` and `clearSelectedTemplate` in `copyWith`.
- `TimerConfiguration.selectedTemplateId` is already a `String?`, so an own id (`custom-<n>`) is stored without changing the settings repository.
- Who builds a `SettingsViewModel`:
  - Directly: `lib/features/home/presentation/home_page.dart` (`SettingsViewModel(getIt())`), the snapshot harness (3 calls `SettingsViewModel(getIt())`), `settings_view_model_test.dart` and `templates_view_model_test.dart`.
  - Through `HomePage` and `getIt`: `home_page_test.dart`, `timer_settings_persistence_test.dart` and `templates_page_test.dart`. Their `setUp` registers `SettingsRepository` (and others) in `getIt`, but not `CustomTemplateRepository`.
  - `templates_page_test.dart` also calls `SettingsViewModel(repository)` directly (4 calls), and `settings_view_model_test.dart` builds extra instances for restarts (`restarted`, `nextSession`, `model`).

## Contract

- `CustomTemplate`, `CustomTemplateRepository`, `FakeCustomTemplateRepository` — provided by TPL-03-02 (see the story's shared contracts).
- `SettingsViewModel(this._settingsRepository, this._customTemplateRepository)` — changed here. `HomePage` passes `getIt()` twice.
- Selection field — changed here: replace `TemplateId? _selectedTemplateId` with `String? _selectedTemplateId` holding the raw id (`TemplateId.name` or `custom-<n>`), plus `List<CustomTemplate> _customTemplates`. `_currentConfiguration` writes `_selectedTemplateId` as is. `_setConfiguration` sets `SettingsState.selectedTemplateId` to `TemplateId.values.asNameMap()[id]` and `selectedCustomTemplate` to the own template with that id (first match in `_customTemplates`), so at most one is non-null.
- `_validated` — changed here: keeps the id when it is a built-in `TemplateId.name` whose settings equal the configuration's settings, or the id of an own template in `_customTemplates` whose settings equal them; otherwise the id becomes `null`.
- `SettingsState` — changed here: `final List<CustomTemplate> customTemplates` (default `const []`) and `final CustomTemplate? selectedCustomTemplate`; `copyWith` gains `List<CustomTemplate>? customTemplates`, `CustomTemplate? selectedCustomTemplate` and `bool clearSelectedCustomTemplate = false`; `==` and `hashCode` include both (`listEquals` / `Object.hashAll` for the list).
- `Future<void> selectCustomTemplate(CustomTemplate template)` — new here: same body as `selectTemplate`, with `TimerConfiguration(template.settings, template.id)`.
- `Future<bool> saveCustomTemplate(CustomTemplate template)` — new here.
  - Builds the new list: replaces the entry with the same `id` in place, or appends. Appending when the list already has `CustomTemplate.maxCount` entries returns `false` without writing.
  - Calls `saveTemplates(newList)`. `Failure` → returns `false`; `_customTemplates` and the state are unchanged.
  - `Success` → `_customTemplates` and `state.customTemplates` become the new list; returns `true`. `timerSettings` never changes.
  - If `template.id == _selectedTemplateId` (only an own id can match, since built-in ids never look like `custom-<n>`): when `template.settings == _currentSettings`, `selectedCustomTemplate` becomes the new value (rename or icon change); otherwise the selection is cleared (`_selectedTemplateId = null`, `_hasSettingsEdits = true`, `_setConfiguration`, then `flushSettings()`).
- `Future<bool> deleteCustomTemplate(String id)` — new here. An id that is not in the list returns `true` without writing. Otherwise removes it and calls `saveTemplates`; `Failure` → `false`, nothing changes. On success, if `id == _selectedTemplateId`, the selection is cleared and saved the same way; the settings stay.
- Consumers: `TemplatesViewModel` (TPL-03-05), `TimerSetupPage` (TPL-03-06) and `TemplateFormViewModel` (TPL-03-03).

## Decisions

- Own templates load first in `_readSettings`, before `getTimerConfiguration()` is validated, so `_validated` sees them. A load `Failure` is logged with `debugPrint` and leaves the list empty; the settings still load.
- Never overwrite stored templates after a failed load: keep a private `bool _customTemplatesLoaded`. While it is `false`, `saveCustomTemplate` and `deleteCustomTemplate` first call `getTemplates()` again (and on `Success` replace `_customTemplates` and the state list); if it fails again they return `false` without writing.
- Changing a setting in Timer Setup clears an own selection exactly like a built-in one (the existing `_updateTimerSettings` rule, unchanged).

## Out of scope

- Any page or widget change (Setup tag: TPL-03-06; list: TPL-03-05). New strings.

## Files and tests

- Unit: `settings_view_model_test.dart` gets the cases below. Create one `FakeCustomTemplateRepository templates` in `setUp` next to `repository`, and pass it to every `SettingsViewModel(repository, templates)` in the file, including the restarted instances, so stored templates survive a restart.
- `templates_view_model_test.dart` and the 4 direct calls in `templates_page_test.dart`: pass a `FakeCustomTemplateRepository()` as the second argument.
- `home_page_test.dart`, `timer_settings_persistence_test.dart`, `templates_page_test.dart`: in each `setUp` that registers `SettingsRepository`, also register `getIt.registerSingleton<CustomTemplateRepository>(FakeCustomTemplateRepository())`.
- Snapshot harness: in `setUp`, create a `FakeCustomTemplateRepository` (a `late` variable next to `settingsRepository`) and register it as `CustomTemplateRepository`; change the 3 `SettingsViewModel(getIt())` calls to `SettingsViewModel(getIt(), getIt())`. No golden changes.

## Acceptance

- [ ] Given stored own templates, when settings load, then `customTemplates` holds them in stored order. Check: `test/features/settings/presentation/settings_view_model_test.dart` "loads own templates with the settings".
- [ ] When loading own templates fails, then `customTemplates` is empty and the timer settings still load. Check: `test/features/settings/presentation/settings_view_model_test.dart` "own template load failure keeps settings".
- [ ] Given a saved selection `custom-1` with settings equal to that template, when settings load, then `selectedCustomTemplate` is it and `selectedTemplateId` is null; with different settings or an unknown id, both are null. Check: `test/features/settings/presentation/settings_view_model_test.dart` "restores a valid own selection only".
- [ ] Given a saved built-in selection, when settings load, then `selectedTemplateId` is restored as before and `selectedCustomTemplate` is null. Check: `test/features/settings/presentation/settings_view_model_test.dart` "built-in selection still restores".
- [ ] When `selectCustomTemplate` runs, then the settings become its values, `selectedCustomTemplate` is set and the saved configuration has its id. Check: `test/features/settings/presentation/settings_view_model_test.dart` "selecting an own template saves its id".
- [ ] When a setting is changed after selecting an own template, then the selection is cleared and saved without an id. Check: `test/features/settings/presentation/settings_view_model_test.dart` "editing a setting clears the own selection".
- [ ] When `saveCustomTemplate` saves a new template, then it is appended, the result is `true` and `timerSettings` is unchanged. Check: `test/features/settings/presentation/settings_view_model_test.dart` "saving a new template appends it".
- [ ] When an existing template is saved, then it keeps its position. Check: `test/features/settings/presentation/settings_view_model_test.dart` "editing keeps the position".
- [ ] Given 20 own templates, when a new one is saved, then the result is `false` and `saveCalls` does not grow. Check: `test/features/settings/presentation/settings_view_model_test.dart` "the 21st template is refused".
- [ ] Given the selected own template, when it is saved with a new name and the same settings, then `selectedCustomTemplate` has the new name; when saved with other settings, then the selection is cleared and `timerSettings` is unchanged. Check: `test/features/settings/presentation/settings_view_model_test.dart` "editing the selected template updates or clears the selection".
- [ ] When the selected own template is deleted, then it leaves the list, the selection is cleared and `timerSettings` is unchanged. Check: `test/features/settings/presentation/settings_view_model_test.dart` "deleting the selected template clears the selection".
- [ ] When the repository fails on save or delete, then the result is `false` and the state is unchanged. Check: `test/features/settings/presentation/settings_view_model_test.dart` "failed template write keeps the state".
- [ ] Given the load of own templates failed, when a template is saved and the retry also fails, then the result is `false` and `saveCalls` is 0; when the retry succeeds, the save goes on with the loaded list. Check: `test/features/settings/presentation/settings_view_model_test.dart` "no write after a failed load".
- [ ] When the checks run, then everything passes and no golden changes. Check: `fvm dart tool/agent_check.dart --skip-build`.
