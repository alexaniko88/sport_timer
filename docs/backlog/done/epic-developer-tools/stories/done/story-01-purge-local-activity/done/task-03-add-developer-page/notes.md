# Notes

## Summary

- New `lib/features/developer/presentation/developer_tools_page.dart`: a "Delete all activity" tile, a confirm dialog, success and failure snackbars, and a blocked tile with a spinner while purging. The State creates the ViewModel and disposes it, and checks `mounted` after the purge.
- `lib/navigation.dart`: added `RoutePath.developer` and `Routes.build({required bool developerToolsEnabled})`. The `/developer` route exists only when the flag is true. `router` is `build(developerToolsEnabled: kDebugMode)`.
- `lib/features/home/presentation/home_page.dart`: new `developerToolsEnabled` field (default `kDebugMode`). When true, the drawer footer shows a divider and a "Developer tools" tile that closes the drawer and opens `/developer`.
- `CLAUDE.md`: updated the `developer` bullet and the routes.

## Evidence

- Drawer shows "Developer tools" when enabled, and tapping it closes the drawer and opens the page: `test/features/home/presentation/home_page_test.dart` — passed
- Drawer hides the entry and footer divider when disabled: same file — passed
- `/developer` does not exist when disabled: `test/navigation_test.dart` — passed
- Cancel and tap outside do not delete: `test/features/developer/presentation/developer_tools_page_test.dart` — passed
- Delete succeeds with one call and a success snackbar: same file — passed
- Tile is blocked while purging: same file — passed
- Failure shows the error snackbar: same file — passed
- Page and dialog accessibility guidelines (light and dark) and 2x text scale: same file — passed
- Goldens `home_drawer.png`, `developer_tools.png`, `developer_tools_dialog.png` refreshed; `ui_snapshots_test.dart` passes
- `fvm dart tool/agent_check.dart --skip-build` — passed

## Points to review

- `lib/features/home/presentation/home_page.dart:176`: `Divider(height: 1, indent: ..., endIndent: ...)` has 3 arguments on one line. The Dart style rule asks for a trailing comma and one argument per line.
- `test/snapshots/ui_snapshots_test.dart:497`: the `developer_tools_dialog` golden taps `AppSurface.onTap` directly instead of `_tapInBothFrames(...)` as the task text says. The reason is in a comment: both frames share one overlay, and a real tap in the dark frame hit the first dialog's barrier. The sign-out dialog golden does the same. The task text should be updated to match.
- `test/features/home/presentation/home_page_test.dart:187`: the two enabled-entry tests sit in `group('with developer tools enabled')`, so their full names have a prefix and do not exactly match the names in the task.

## Run

implementer: Claude Sonnet 5.5; tests: Claude Sonnet 5.5; reviewer: Claude Opus 5.5
