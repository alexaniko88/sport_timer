---
id: DEV-01-02
status: ready
type: feat
complexity: 4
depends-on: [DEV-01-01]
touches:
  - lib/features/developer/presentation/developer_tools_view_model.dart
  - lib/features/developer/presentation/developer_tools_state.dart
  - CLAUDE.md
  - test/features/developer/presentation/developer_tools_view_model_test.dart
skills: []
---

# Add the developer tools view model

Story: [Purge local activity](../index.md)

Epic: [Developer tools](../../../index.md)

## Goal

Add the Developer tools state and ViewModel that run the purge, report success or failure, and block a second purge while one is pending. Serves R2, R3 and R5. This task has no UI; the page in [Add the developer page (DEV-01-03)](../task-03-add-developer-page/index.md) creates and uses the ViewModel.

## Context

- `ActivityRepository` (`lib/features/statistics/domain/activity_repository.dart`) is registered in `getIt` in `lib/di/di.dart`. Its `deleteAllActivity()` is added by [Purge activity storage (DEV-01-01)](../done/task-01-purge-activity-storage/index.md). Statistics screens refresh on `changes`, which the purge emits, so the ViewModel does nothing extra to refresh them.
- ViewModel pattern to copy: `lib/features/login/presentation/login_view_model.dart` and `login_state.dart` (`ValueNotifier` state exposed as `ValueListenable`, `Future<bool>` for a one-time result, `_disposed` flag, `Result.fold`).
- `lib/features/developer/` does not exist yet; this task creates it with a `presentation/` folder only.
- `CLAUDE.md` "Project layout" lists every feature folder ("Features: `user` (domain, data), …, `timer` and `statistics`." plus one bullet per feature). `test/architecture/ai_setup_test.dart` "every folder under lib/features is named in the "Project layout" section of CLAUDE.md" fails once `lib/features/developer/` exists and is not named, and CI runs the full `flutter test`, so this task adds the feature to `CLAUDE.md`. DEV-01-03 later extends the bullet and the routes.

## Contract

- `ActivityRepository.deleteAllActivity()` — provided by DEV-01-01: `Future<Result<void>> deleteAllActivity()`; `Success` when every row is deleted, `Failure` otherwise.
- `DeveloperToolsState` in `lib/features/developer/presentation/developer_tools_state.dart` — new here: `final bool isPurging; final String? errorMessage;`, a `const` constructor with defaults `false` and `null`, `copyWith`, `==` and `hashCode`.
- `DeveloperToolsViewModel(ActivityRepository)` in `lib/features/developer/presentation/developer_tools_view_model.dart` — new here, consumed by `DeveloperToolsPage` in DEV-01-03 (unwired until then):
  - `ValueListenable<DeveloperToolsState> get state`, starting at `const DeveloperToolsState()`.
  - `Future<bool> purge()`: if `isPurging` is already true, returns `false` at once, without calling the repository and without changing the state. Otherwise sets `isPurging: true, errorMessage: null`, awaits `deleteAllActivity()`, and returns `false` if disposed meanwhile (without touching the disposed notifier). On `Success` sets `isPurging: false` and returns `true`. On `Failure(error)` sets `isPurging: false, errorMessage: error.toString()` and returns `false`.
  - `dispose()` sets `_disposed` and disposes the notifier.

## Decisions

- **Double taps blocked in the ViewModel, not only in the UI:** chosen by the user.
- **Raw error text:** `errorMessage` is `error.toString()`; the raw text is fine on a developer page.

## Out of scope

- The page, dialog, snackbars, drawer entry, route, the `/developer` route in `CLAUDE.md`, goldens and snapshot README (that is [Add the developer page (DEV-01-03)](../task-03-add-developer-page/index.md)).
- The storage purge itself (that is [Purge activity storage (DEV-01-01)](../done/task-01-purge-activity-storage/index.md)).

## Files and tests

- New: `lib/features/developer/presentation/developer_tools_state.dart`, `lib/features/developer/presentation/developer_tools_view_model.dart` and `test/features/developer/presentation/developer_tools_view_model_test.dart` (unit test).
- `CLAUDE.md`, "Project layout": add `developer` to the features line ("Features: `user` (domain, data), …, `timer`, `statistics` and `developer` (presentation only).") and add a bullet "- `developer`: debug-only Developer tools ViewModel and state, presentation only." after the `statistics` bullet. Change nothing else in the file.
- Fakes: the test declares its own private, hand-written `ActivityRepository` fake (no mocking package). Do not change `test/features/statistics/fake_activity_repository.dart` and do not create a shared test helper. The fake implements only `deleteAllActivity()`, which counts calls and returns the future of a `Completer<Result<void>>` the test controls (success or `Failure(Exception('boom'))`); every other member goes to `noSuchMethod` with `@override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);`, exactly like the private fakes in `test/snapshots/ui_snapshots_test.dart`, so any unexpected call throws.

## Acceptance

- [ ] When `purge()` succeeds, then it returns `true` and the state is back to `isPurging: false` with no error. Check: `test/features/developer/presentation/developer_tools_view_model_test.dart` "purge succeeds".
- [ ] When `purge()` fails, then it returns `false`, `isPurging` is false and `errorMessage` holds the error text. Check: `test/features/developer/presentation/developer_tools_view_model_test.dart` "purge failure sets the error message".
- [ ] While a purge is pending, when `purge()` is called again, then it returns `false` at once and the repository is called only once. Check: `test/features/developer/presentation/developer_tools_view_model_test.dart` "second purge while pending is ignored".
- [ ] When the ViewModel is disposed while a purge is pending, then `purge()` returns `false` and no error is thrown when the purge completes. Check: `test/features/developer/presentation/developer_tools_view_model_test.dart` "dispose while purging".
- [ ] When `lib/features/developer` exists, then `CLAUDE.md` "Project layout" names `developer`. Check: `test/architecture/ai_setup_test.dart` "every folder under lib/features is named in the "Project layout" section of CLAUDE.md".
- [ ] When the checks run, then they pass, including the layer boundary test. Check: `fvm dart tool/agent_check.dart --skip-build`.
