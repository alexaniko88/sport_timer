---
id: UI-05-01
status: ready
type: feat
complexity: 5
depends-on: []
touches:
  - lib/features/statistics/domain/extensions/timer_session_template_extension.dart
  - lib/features/statistics/presentation/extensions/duration_extension.dart
  - lib/features/statistics/presentation/statistics_state.dart
  - lib/features/statistics/presentation/statistics_view_model.dart
  - test/features/statistics/domain/extensions/timer_session_template_extension_test.dart
  - test/features/statistics/presentation/extensions/duration_extension_test.dart
  - test/features/statistics/presentation/statistics_state_test.dart
  - test/features/statistics/presentation/statistics_view_model_test.dart
skills: []
---

# Prepare the statistics card state

Story: [Rethink statistics cards and day details](../index.md)

Epic: [UI refactor](../../../index.md)

## Goal

Add the logic the redesigned statistics cards need: compact durations, the template a session matches, and an open-day state in `StatisticsViewModel` that loads, caches and retries one day's sessions. Nothing shows it yet; Rethink statistics cards and details (UI-05-02) wires it into the cards. Serves R1, R2 and R4 of the story.

## Context

- `lib/features/statistics/presentation/extensions/duration_extension.dart`: `StatisticsDurationExtension.formattedStatisticsDuration(l10n)` gives full words (`26 minutes`), used for semantics and charts. Its tests are in `test/features/statistics/presentation/extensions/duration_extension_test.dart`.
- `lib/features/statistics/presentation/statistics_state.dart`: `enum StatisticsStatus { initial, loading, content, empty, error }`; `StatisticsState` has `copyWith` (with `clearError` and `clearSelection` flags), `==` and `hashCode`, and stores `dailyActivity` with `List.unmodifiable`. Tests: `test/features/statistics/presentation/statistics_state_test.dart`.
- `lib/features/statistics/presentation/statistics_view_model.dart`: `StatisticsViewModel` listens to `_repository.changes` (clears the chart selection and calls `refresh()`), keeps a `_generation` counter and a `_disposed` flag, and `dispose()` increments `_generation`. Tests: `test/features/statistics/presentation/statistics_view_model_test.dart`, with its own `FakeActivityRepository` that returns `reads` Completers from `readDailyActivity`.
- `lib/features/statistics/presentation/day_details_view_model.dart`: `DayDetailsViewModel.refresh` loads `readDayActivity` and handles the `Result` with `fold`; follow it. That file stays here; UI-05-02 removes it.
- Domain: `RunActivitySummary` (`session: TimerSession`, `activity: DailyActivity`). `TimerSession` has `preparationDurationMs`, `workDurationMs`, `restDurationMs`, `roundCount` (the configuration the run started with). `ActivityRepository.readDayActivity(String localDate)` returns `Future<Result<List<RunActivitySummary>>>`.
- Templates: `builtInTemplates` (`lib/features/templates/domain/built_in_templates.dart`) holds `WorkoutTemplate(id, settings: TimerSettings(preparationTime, roundTime, restTime, rounds))`; `TemplateId` is in `lib/features/templates/domain/workout_template.dart`. New domain extensions go in `lib/features/statistics/domain/extensions/`, next to `daily_activity_list_extension.dart`.

## Contract

- `StatisticsDurationExtension.compactStatisticsDuration` in `lib/features/statistics/presentation/extensions/duration_extension.dart` — new here: `String get compactStatisticsDuration`. It drops milliseconds, then joins the non-zero parts with spaces as `<h>h`, `<m>m`, `<s>s` (`26m`, `3m 35s`, `1h 2m 5s`, `30s`). Zero, or under one second, gives `0s`. The symbols are the same in English and Spanish, so no strings. Consumer: UI-05-02 (visible numbers; semantics keep `formattedStatisticsDuration(l10n)`).
- `TimerSessionTemplate` in `lib/features/statistics/domain/extensions/timer_session_template_extension.dart` — new here: `extension TimerSessionTemplate on TimerSession { TemplateId? get matchingTemplateId }`. Returns the `id` of the first entry of `builtInTemplates` whose settings equal the session's configuration (`preparationTime == Duration(milliseconds: preparationDurationMs)`, `roundTime == Duration(milliseconds: workDurationMs)`, `restTime == Duration(milliseconds: restDurationMs)`, `rounds == roundCount`), otherwise `null` (Custom). It imports only domain files (`templates/domain`, `settings/domain`), which the boundary test allows. Consumer: UI-05-02 (session row tag).
- `StatisticsState` — new fields here, all in `copyWith`, `==` and `hashCode`: `String? expandedDate` (the open card's `localDate`, `null` when all are closed), `StatisticsStatus dayStatus` (default `initial`) and `List<RunActivitySummary> dayRuns` (default empty, stored with `List.unmodifiable`). `copyWith` gets `bool clearExpanded = false`, which sets `expandedDate` to `null`, `dayStatus` to `initial` and `dayRuns` to empty. Consumer: UI-05-02.
- `StatisticsViewModel` — new here: a private cache `final Map<String, List<RunActivitySummary>> _dayRuns = {};` and `int _dayGeneration = 0;`. Consumer: UI-05-02 (`StatisticPage` calls `toggleDay` and `retryDay`).
  - `void toggleDay(String localDate)`: when `localDate == expandedDate`, close (`clearExpanded: true`). Otherwise open this day and close the one before (at most one open). If `_dayRuns` has the day, set `dayStatus` to `content` (or `empty` for an empty list) with the cached runs at once, with no repository call. If not, set `dayStatus: loading`, `dayRuns: []` and call `_loadDay(localDate)`.
  - `Future<void> retryDay()`: when `expandedDate` is not null, set `dayStatus: loading` and call `_loadDay` for it again.
  - `_loadDay(localDate)`: `final generation = ++_dayGeneration;`, await `_repository.readDayActivity(localDate)`, then return early when `_disposed`, when `generation != _dayGeneration`, or when `expandedDate` is no longer `localDate`. On success cache the list and set `dayStatus` to `content` or `empty` with `dayRuns`; on failure set `dayStatus: error` and do not cache. Use `fold` (`onSuccess` / `onFailure`).
  - `refresh()` and the `changes` listener clear `_dayRuns`, increment `_dayGeneration` and close the open day (`clearExpanded: true`), because stored data may have changed. All days start closed. `dispose()` also increments `_dayGeneration`.

## Decisions

- **Accordion, all closed at start:** only one day open at a time (agreed with the user). The open day is not remembered after leaving Statistics.
- **Compact durations (`26m`, `3m 35s`):** approved in the mockup; the same symbols in both languages.
- **Template from the session configuration, numbers from the activity:** `matchingTemplateId` reads `TimerSession`; UI-05-02 shows `run.activity` values.
- **Unwired on purpose:** this task changes no widget, page, route, string or golden, so the app looks and works as before.

## Out of scope

- Any widget, `StatisticPage`, `lib/navigation.dart`, ARB files, goldens and the snapshot harness (all UI-05-02).
- Removing the day details page, its view model or state (UI-05-02).
- The `Charts` view, the consistency calendar and the data layer.

## Files and tests

- New: `lib/features/statistics/domain/extensions/timer_session_template_extension.dart` and its unit test `test/features/statistics/domain/extensions/timer_session_template_extension_test.dart`.
- Unit tests: `test/features/statistics/presentation/extensions/duration_extension_test.dart`, `test/features/statistics/presentation/statistics_state_test.dart`, `test/features/statistics/presentation/statistics_view_model_test.dart`. In the view model test, give `FakeActivityRepository` a `readDayActivity` that records each requested `localDate` and returns a `Completer` future the test completes, like `reads`. No existing test there needs changing.

## Acceptance

- [ ] When a duration has hours, minutes or seconds, then `compactStatisticsDuration` joins the non-zero parts (`26m`, `3m 35s`, `1h 2m 5s`, `30s`, `37h 2m 12s`) and drops milliseconds. Check: `test/features/statistics/presentation/extensions/duration_extension_test.dart` "compact duration joins the non-zero hours, minutes and seconds".
- [ ] When a duration is zero or under one second, then `compactStatisticsDuration` gives `0s`. Check: `test/features/statistics/presentation/extensions/duration_extension_test.dart` "compact duration of zero or under a second is 0s".
- [ ] When a session's configuration equals a built-in template, then `matchingTemplateId` returns that template's id, for every built-in template. Check: `test/features/statistics/domain/extensions/timer_session_template_extension_test.dart` "every built-in template matches its id".
- [ ] When exactly one of preparation, work, rest or rounds differs from every template, then `matchingTemplateId` is `null`. Check: `test/features/statistics/domain/extensions/timer_session_template_extension_test.dart` "a change in preparation, work, rest or rounds gives null".
- [ ] When two states differ only in `expandedDate`, `dayStatus` or `dayRuns`, then they are not equal, and `copyWith(clearExpanded: true)` resets all three. Check: `test/features/statistics/presentation/statistics_state_test.dart` "compares the open day fields and clears them".
- [ ] When `toggleDay` opens a day that is not cached, then `dayStatus` is `loading`, `readDayActivity(localDate)` is called once, and on success `dayStatus` is `content` with the runs. Check: `test/features/statistics/presentation/statistics_view_model_test.dart` "toggleDay opens a day and loads its runs".
- [ ] When `toggleDay` is called for the open day, then it closes. Check: `test/features/statistics/presentation/statistics_view_model_test.dart` "toggleDay on the open day closes it".
- [ ] When `toggleDay` opens another day, then the first one closes. Check: `test/features/statistics/presentation/statistics_view_model_test.dart` "toggleDay on another day closes the first".
- [ ] When a cached day is opened again, then its runs show at once and the repository is not called again. Check: `test/features/statistics/presentation/statistics_view_model_test.dart` "toggleDay shows a cached day without reading again".
- [ ] When a day loads an empty list, then `dayStatus` is `empty`. Check: `test/features/statistics/presentation/statistics_view_model_test.dart` "a day with no runs is empty".
- [ ] When loading a day fails, then `dayStatus` is `error` and nothing is cached, and `retryDay` loads it again to `content`. Check: `test/features/statistics/presentation/statistics_view_model_test.dart` "a failed day shows an error and retryDay loads it again".
- [ ] When a day result arrives after that day closed, after another day opened, or after `dispose`, then it is ignored. Check: `test/features/statistics/presentation/statistics_view_model_test.dart` "ignores a day result after it closed, another opened or disposal".
- [ ] When the repository emits `changes` or `refresh` runs, then the open day closes and the cache is cleared (the next open reads again). Check: `test/features/statistics/presentation/statistics_view_model_test.dart` "changes and refresh close the open day and clear the cache".
- [ ] When the change is checked, then format, analyze, the mirrored tests and the boundary test pass. Check: `fvm dart tool/agent_check.dart --skip-build`.
