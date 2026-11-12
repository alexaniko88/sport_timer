---
id: TPL-03-02
status: done
type: feat
complexity: 3
depends-on: []
touches:
  - lib/features/templates/domain/custom_template.dart
  - lib/features/templates/domain/custom_template_icon.dart
  - lib/features/templates/domain/custom_template_repository.dart
  - lib/features/templates/domain/extensions/custom_template_list_ids_extension.dart
  - lib/features/templates/data/shared_preferences_custom_template_repository.dart
  - lib/di/di.dart
  - test/features/templates/domain/custom_template_test.dart
  - test/features/templates/domain/extensions/custom_template_list_ids_extension_test.dart
  - test/features/templates/data/shared_preferences_custom_template_repository_test.dart
  - test/features/templates/fake_custom_template_repository.dart
skills: []
---

# Store custom templates

Story: [Create your own templates](../../index.md)

Epic: [Templates](../../../../index.md)

## Goal

Add the own template model, its id helper and a repository that saves and loads the list on the device, registered in DI. Nothing uses it yet. Serves R4.

## Context

- Built-in model to mirror: `lib/features/templates/domain/workout_template.dart` (`WorkoutTemplate`, `totalTime`).
- Storage pattern to copy: `lib/features/settings/data/shared_preferences_settings_repository.dart` (JSON in one key, `prefs.reload()` before reading and writing, `Failure` on a `false` write or any exception, the `_failedWrites` guard).
- Repository test pattern: `test/features/settings/data/settings_repository_test.dart` (`_RecordingPreferencesStore` over `InMemorySharedPreferencesStore`).
- Shared fake location pattern: `test/features/statistics/fake_activity_repository.dart`.
- DI: `lib/di/di.dart`, next to the `SettingsRepository` registration.

## Contract

- `CustomTemplateIcon`, `CustomTemplate`, `CustomTemplateListIds` and `CustomTemplateRepository` — new here, exactly as in the story's [Shared contracts](../../index.md#shared-contracts).
- `SharedPreferencesCustomTemplateRepository implements CustomTemplateRepository` — new here, in `lib/features/templates/data/`.
  - Key `custom_templates`, a JSON list of `{"id": String, "name": String, "icon": String (enum name), "preparation": int seconds, "round": int seconds, "rest": int seconds, "rounds": int}`.
  - `getTemplates()`: missing key → `Success([])`. An entry with an unknown icon name gets `CustomTemplateIcon.weights`; `rounds` is clamped to `1..TimerSettings.maxRounds`. Malformed JSON or a wrong type → `Failure`.
  - `saveTemplates(list)`: writes the whole list in order; a `false` write or an exception → `Failure`.
- `FakeCustomTemplateRepository` — new here, as in the story. `getTemplates()` returns `Failure` when `failLoad`, else a copy of `stored`; `saveTemplates` increments `saveCalls`, returns `Failure` when `failSave`, else replaces `stored`. Consumers: TPL-03-04, TPL-03-05, TPL-03-03.
- Registration — new here: `registerLazySingleton<CustomTemplateRepository>(SharedPreferencesCustomTemplateRepository.new)` in `configureDependencies()`.

## Out of scope

- Any ViewModel, page or string. Account separation.

## Files and tests

- New: every `lib/` file in `touches` except `di.dart`, and the fake.
- Unit: `custom_template_test.dart`, `custom_template_list_ids_extension_test.dart`.
- Repository: `shared_preferences_custom_template_repository_test.dart`, with the recording store from the settings repository test copied locally.

## Acceptance

- [x] When two `CustomTemplate` values have the same fields, then they are equal and have the same hash; a different field makes them unequal. Check: `test/features/templates/domain/custom_template_test.dart` "equality uses every field".
- [x] When `totalTime` is read, then it is preparation + round × rounds + rest × (rounds − 1). Check: `test/features/templates/domain/custom_template_test.dart` "totalTime skips the last rest".
- [x] When `nextId` is read on an empty list, then it is `custom-1`; on `custom-1`, `custom-7`, then `custom-8`; ids that do not parse are ignored. Check: `test/features/templates/domain/extensions/custom_template_list_ids_extension_test.dart` "nextId follows the highest number".
- [x] Given nothing is stored, when `getTemplates()` runs, then it returns an empty list. Check: `test/features/templates/data/shared_preferences_custom_template_repository_test.dart` "empty storage gives an empty list".
- [x] When a list of two templates is saved and read again with a new repository instance, then the same list comes back in the same order. Check: `test/features/templates/data/shared_preferences_custom_template_repository_test.dart` "saved templates survive a restart".
- [x] When the stored value is not valid JSON, then `getTemplates()` returns `Failure` and does not throw. Check: `test/features/templates/data/shared_preferences_custom_template_repository_test.dart` "malformed data is a failure".
- [x] When a stored entry has an unknown icon name, then it loads with `weights`. Check: `test/features/templates/data/shared_preferences_custom_template_repository_test.dart` "unknown icon falls back to weights".
- [x] When the platform write fails or throws, then `saveTemplates` returns `Failure`. Check: `test/features/templates/data/shared_preferences_custom_template_repository_test.dart` "failed write is a failure".
- [x] When the checks run, then format, analyze, the boundary test and the tests above pass. Check: `fvm dart tool/agent_check.dart --skip-build`.
