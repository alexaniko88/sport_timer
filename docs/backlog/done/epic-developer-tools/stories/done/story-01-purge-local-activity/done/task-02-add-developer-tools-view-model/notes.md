# Notes

## Summary

- Added `DeveloperToolsState` (`isPurging`, `errorMessage`, const constructor, `copyWith`, `==`, `hashCode`) in `lib/features/developer/presentation/developer_tools_state.dart`.
- Added `DeveloperToolsViewModel(ActivityRepository)` in `lib/features/developer/presentation/developer_tools_view_model.dart`. `purge()` returns `false` at once if a purge is already pending. Otherwise it sets `isPurging: true` and awaits `deleteAllActivity()`. It returns `false` if disposed meanwhile. On success it resets the state and returns `true`. On failure it sets `errorMessage` and returns `false`.
- Updated `CLAUDE.md` "Project layout" to name the `developer` feature.

## Evidence

- purge() succeeds returns true and the state is clean: `test/features/developer/presentation/developer_tools_view_model_test.dart` "purge succeeds" — passed
- purge() fails returns false with the error text: same file, "purge failure sets the error message" — passed
- second purge while pending returns false and the repository is called once: same file, "second purge while pending is ignored" — passed
- dispose while pending returns false with no error: same file, "dispose while purging" — passed
- CLAUDE.md names `developer`: `test/architecture/ai_setup_test.dart` — passed

## Points to review

- `lib/features/developer/presentation/developer_tools_state.dart:10`: `copyWith` uses `errorMessage ?? this.errorMessage`, so `copyWith(errorMessage: null)` cannot clear an error. The ViewModel builds new state objects, so it is not affected. DEV-01-03 should build a new `DeveloperToolsState(...)` to clear the error instead of using `copyWith`.

## Run

implementer: Claude Sonnet 5.5; tests: Claude Sonnet 5.5; reviewer: Claude Opus 5.5
