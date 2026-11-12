# Notes

## Summary

- Added the domain files `custom_template_icon.dart`, `custom_template.dart` (copyWith, ==, hashCode, `totalTime`, `maxCount` 20, `maxNameLength` 30), `custom_template_repository.dart` and `extensions/custom_template_list_ids_extension.dart` (`nextId`).
- Added `SharedPreferencesCustomTemplateRepository`: one JSON list under the key `custom_templates`. A missing key gives an empty list, an unknown icon becomes `weights`, `rounds` is clamped to `1..TimerSettings.maxRounds`, and bad data or a failed write gives `Failure`.
- Registered `CustomTemplateRepository` in `lib/di/di.dart` and added the shared `FakeCustomTemplateRepository`.

## Evidence

- Equality uses every field: `test/features/templates/domain/custom_template_test.dart` "equality uses every field" — passed
- `totalTime` skips the last rest: `custom_template_test.dart` "totalTime skips the last rest" — passed
- `nextId` follows the highest number and ignores ids that do not parse: `custom_template_list_ids_extension_test.dart` "nextId follows the highest number" — passed
- Empty storage gives an empty list: `shared_preferences_custom_template_repository_test.dart` "empty storage gives an empty list" — passed
- Saved templates survive a restart: same file, "saved templates survive a restart" — passed
- Malformed data is a failure: same file, "malformed data is a failure" — passed
- Unknown icon falls back to weights: same file, "unknown icon falls back to weights" — passed
- Failed or throwing write is a failure: same file, "failed write is a failure" — passed

## Points to review

- lib/features/templates/data/shared_preferences_custom_template_repository.dart:51: `_decode` reads the JSON map with manual `as` casts instead of a map pattern. It matches the settings repository and a wrong type still becomes a `Failure`.

## Run

implementer: Claude Sonnet 5.5; tests: Claude Sonnet 5.5; reviewer: Claude Opus 5.5
