---
id: DEV-01-02
status: ready
type: feat
complexity: high
depends-on: [DEV-01-01, IMP-02]
touches:
  - lib/features/developer/**
  - lib/features/home/presentation/home_page.dart
  - lib/navigation.dart
  - test/features/developer/**
  - test/features/home/**
  - test/navigation_test.dart
  - test/snapshots/ui_snapshots_test.dart
  - test/snapshots/goldens/home_drawer.png
  - test/snapshots/goldens/developer_tools.png
  - test/snapshots/goldens/developer_tools_dialog.png
skills: []
---

# Add the developer page

Story: [Purge local activity](../index.md)

Epic: [Developer tools](../../../index.md)

## Goal

Add a debug-only "Developer tools" page, opened from the bottom of the navigation drawer, with one action that deletes all local activity for every account after a confirmation. In profile and release builds the entry and the route do not exist. The page calls `ActivityRepository.deleteAllActivity()` from [DEV-01-01](../01-purge-activity-storage/index.md).

## Context

- Story: [Purge local activity](../index.md). Epic: [Developer tools](../../../index.md). Storage purge: [DEV-01-01](../01-purge-activity-storage/index.md). Drawer redesign: [IMP-02](../../../../improvements/02-rethink-navigation-drawer/index.md).
- Drawer: after [IMP-02](../../../../improvements/02-rethink-navigation-drawer/index.md), `lib/features/home/presentation/home_page.dart` builds a `Drawer` with a `SafeArea` and `Column` holding a header (`Icons.timer_outlined` badge + `Sport Timer` title), a `Divider`, and an `Expanded` `ListView` of `_DrawerTile` (`AppSurface`) items for `Templates` and `Styles`.
- Routes: `lib/navigation.dart` has the `RoutePath` enum and `Routes.router`, a `static final GoRouter`. `HomePage` is created there as `const HomePage()`.
- `ActivityRepository` (`lib/features/statistics/domain/activity_repository.dart`) is registered in `getIt` in `lib/di/di.dart`. Statistics screens refresh on `changes`, which the purge emits, so this page does nothing extra to refresh them.
- ViewModel pattern to copy: `lib/features/login/presentation/login_view_model.dart` and `login_state.dart` (`ValueNotifier` state, `Future<bool>` for a one-time result, `_disposed` flag) and how `login_page.dart` shows a snackbar after awaiting it.
- Shared pieces: `AppSurface` (`lib/shared/presentation/widgets/app_surface.dart`), `AppSpacing`, text roles `tileTitle` and `tileSecondary` (`lib/shared/presentation/extensions/text_theme_extension.dart`).
- Goldens: [home_drawer.png](../../../../../test/snapshots/goldens/home_drawer.png) (drawer today), [templates_selected.png](../../../../../test/snapshots/goldens/templates_selected.png) (page with app bar and tiles), [account_sign_out_dialog.png](../../../../../test/snapshots/goldens/account_sign_out_dialog.png) (confirmation dialog). Golden tests are in `test/snapshots/ui_snapshots_test.dart` (`configureFakeDependencies`, `_lightAndDarkGroup`, `_tapInBothFrames`) and indexed in `test/snapshots/README.md`.
- `flutter test` always runs in debug mode, so `kDebugMode` is always true in tests. That is why the gate is a flag tests can set.

## Behavior

- **Gate flag `developerToolsEnabled`:**
  - `Routes` gets `static GoRouter build({required bool developerToolsEnabled})` that returns the router, and `static final router = build(developerToolsEnabled: kDebugMode);`. The existing routes stay unchanged.
  - `RoutePath` gets `developer('/developer')`. The `/developer` `GoRoute` is added to the list only when `developerToolsEnabled` is true. When it is false, going to `/developer` shows go_router's default error page and `DeveloperToolsPage` is never built.
  - `HomePage` gets `final bool developerToolsEnabled;` with `const HomePage({super.key, this.developerToolsEnabled = kDebugMode})`. `Routes.build` passes its flag: `HomePage(developerToolsEnabled: developerToolsEnabled)`.
- **Drawer entry:** when `developerToolsEnabled` is true, below the `Expanded` `ListView` inside the `Drawer`'s `Column`, render a `Divider(height: 1, indent: AppSpacing.s16, endIndent: AppSpacing.s16)` followed by `Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, AppSpacing.s24))` holding an `AppSurface` tile wrapped in `Semantics(button: true, child: ...)`:
  - Inside `AppSurface`: a `Row` with `Icon(Icons.bug_report_outlined, color: colorScheme.primary)`, `const Gap(AppSpacing.s12)`, `Expanded(child: Text('Developer tools', maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.tileTitle))`, `const Gap(AppSpacing.s12)`, and `Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant)`.
  - Tapping it closes the drawer (`_scaffoldKey.currentState?.closeDrawer()`) and calls `context.pushNamed(RoutePath.developer.value)`. When `developerToolsEnabled` is false, neither this bottom `Divider` nor the footer `Padding` is rendered. Where the mockup and this text differ, this text wins; the mockup is the visual reference.
- **Page `DeveloperToolsPage`:** a `StatefulWidget` that creates `DeveloperToolsViewModel(getIt())` in its `State` and disposes it in `dispose()`.
- **ViewModel `DeveloperToolsViewModel(ActivityRepository)`:**
  - State `DeveloperToolsState { final bool isPurging; final String? errorMessage; }` with a `const` constructor (defaults `false` and `null`), `copyWith`, `==` and `hashCode`.
  - `Future<bool> purge()`: if `isPurging` is already true, it returns `false` at once, without calling the repository and without changing the state. Otherwise it sets `isPurging: true, errorMessage: null`, awaits `deleteAllActivity()`, returns `false` if disposed meanwhile, and on `Success` sets `isPurging: false` and returns `true`. On `Failure(error)` it sets `isPurging: false, errorMessage: error.toString()` and returns `false`.
  - `dispose()` sets `_disposed` and disposes the notifier.
- **Flow:** tapping the tile opens the confirmation dialog (`showDialog<bool>`). Cancel returns `false`; tapping outside the dialog or the system back returns `null`. Both mean cancel: nothing is called. Delete returns `true`, then the page awaits `viewModel.purge()`. If the page is no longer mounted it stops. On `true` it shows the snackbar "All local activity deleted."; on `false` with a non-null `errorMessage` it shows "Could not delete activity: <errorMessage>".
- While `isPurging` is true the tile does not respond to taps, so a second purge cannot start from the UI, and the ViewModel guard also blocks a direct second call.

## View spec

- **Place and layout:** a new full page at `/developer`. `AppBar` with the automatic back button and the title "Developer tools". The body is a `ListView` with padding `AppSpacing.s16` holding one `AppSurface` tile. The tile is a `Row`: `Icons.delete_sweep_outlined` in `colorScheme.primary`; then an `Expanded` column with the title "Delete all activity" (`tileTitle`) and the secondary text "Removes workouts and statistics for every account on this device. Settings and sign-in are kept." (`tileSecondary`, `colorScheme.onSurfaceVariant`), spaced with `AppSpacing` tokens; then a 24 by 24 trailing slot.
- **States:**
  - Default: trailing `Icons.chevron_right`; the tile is tappable (`AppSurface.onTap` set).
  - Purging: `AppSurface.onTap` is null and the trailing slot shows a 20 by 20 `CircularProgressIndicator(strokeWidth: 2.5, semanticsLabel: 'Deleting')`.
  - Semantics in both states: the `AppSurface` is wrapped in `Semantics(button: true, enabled: !state.isPurging, child: ...)`, so the tile is a button that reads as disabled while purging. Its title and description stay readable as the button's label.
  - Confirmation: an `AlertDialog` (shape from `SportTheme`) with the title "Delete all activity?", the content "This deletes every workout and statistic for all accounts on this device. It can't be undone.", and two `TextButton`s: "Cancel" and "Delete". "Delete" uses `colorScheme.error` as its foreground color (set with `TextButton.styleFrom(foregroundColor: ...)`, no new token).
  - Success: snackbar "All local activity deleted.".
  - Failure: snackbar "Could not delete activity: <errorMessage>" (the raw error text is fine on a developer page).
  - There is no empty, loading-on-open or partial-data state: the page loads nothing.
  - Long text: the secondary line wraps; nothing is cut off at large text scales.
- **Interaction:** only the tile is interactive on the page; back leaves the page. The dialog's buttons and barrier are as described in Behavior.
- **Navigation:** in through the drawer footer entry (`pushNamed`, no `extra`); out through the app bar back button or system back, which returns to Home.
- **Reuse:** `AppSurface`, `AppSpacing`, `tileTitle`, `tileSecondary`, theme colors. No new shared widget or token.
- **Themes:** light and dark come from the theme; no custom or phase colors.
- **Texts:** English only, as string constants in the developer page and the home page footer. No ARB keys and no Spanish, because only developers see this page in debug builds.
- **Accessibility:** the tile and dialog buttons are at least 48 by 48; the page passes `androidTapTargetGuideline`, `iOSTapTargetGuideline` and `textContrastGuideline` in light and dark. Reading order: app bar title, then the tile (title, then description). The drawer footer entry has the label "Developer tools" and is a button for screen readers.
- **Snapshots:** `home_drawer.png` changes (it gains the footer entry, because tests run with the default flag `kDebugMode`, which is true). New: `developer_tools.png` (page, default state) and `developer_tools_dialog.png` (confirmation open over the page). Both light and dark like the other goldens.
  - The two new goldens build `const DeveloperToolsPage()` directly inside `_lightAndDarkGroup`, with no router, in the same way the existing page goldens build their pages. The `ActivityRepository` fake that `setUp` in `ui_snapshots_test.dart` already registers is enough. With no previous route, the `AppBar` shows only the title and no back button, as in `templates_selected.png`.
  - `developer_tools_dialog` taps the tile in both frames with `_tapInBothFrames(find.text('Delete all activity'))`.
  - In `test/snapshots/README.md`: in the `home_drawer.png` row, add "a `Developer tools` entry pinned at the bottom (debug builds only)" to the description, and add ``Tap `Developer tools` → [Developer tools](goldens/developer_tools.png) (`/developer`)`` to the flow links (this is text for the README, so its link is relative to `test/snapshots/`). Add rows for the two new goldens (tile → dialog, Cancel → page, back → Home), following the format of the existing rows.

## Mockup

[mockup.html](mockup.html), approved by the user. It shows the drawer, page, confirmation, deleting, success and failure states in light and dark.

## Decisions

- **Gate from `kDebugMode` through a flag tests can set:** release behavior must be tested, and `flutter test` always runs in debug. Chosen by the user.
- **Entry at the bottom of the drawer:** chosen by the user over placing it below "Timer styles".
- **Page, tile and dialog texts as in the mockup:** approved by the user.
- **No localization:** developer-only page; texts are English constants. Chosen by the user.
- **Double taps blocked in the ViewModel, not only in the UI:** chosen by the user.
- **Not dependent on STAT-05-01:** chosen by the user.

## Out of scope

- The storage purge itself and stale-write handling (that is [DEV-01-01](../01-purge-activity-storage/index.md)).
- Any other developer tool, showing row counts, account-specific deletion, or changes to settings or sign-in.
- Localization and Spanish strings for this page.

## Files and tests

Created:

- `lib/features/developer/presentation/developer_tools_page.dart` (`DeveloperToolsPage`)
- `lib/features/developer/presentation/developer_tools_view_model.dart` (`DeveloperToolsViewModel`)
- `lib/features/developer/presentation/developer_tools_state.dart` (`DeveloperToolsState`)
Fakes: every new test file declares its own private, hand-written fakes (no mocking package). Do not change `test/features/statistics/fake_activity_repository.dart` and do not create a shared test helper. The private fakes in `test/snapshots/ui_snapshots_test.dart` (`_FakeSettingsRepository`, `_FakeUserRepository`, `_FakeActivityRepository`) show the shape to copy. The `ActivityRepository` fake for the developer tests overrides `deleteAllActivity()` to count calls and complete a `Completer<Result<void>>` that the test controls (success or `Failure(Exception('boom'))`). Its other methods return empty successes and `changes` is an empty stream.

- `test/features/developer/presentation/developer_tools_view_model_test.dart`: success, failure (`errorMessage` set), second call while the first is pending (repository called once), dispose while pending.
- `test/features/developer/presentation/developer_tools_page_test.dart`: cancel, barrier dismiss, confirm, purging state, failure snackbar, guidelines, text scale. The fake is registered in `getIt` in `setUp`, and `getIt.reset()` runs in `tearDown`.
- `test/features/home/presentation/home_page_test.dart`: extend the existing home drawer tests from `IMP-02` to verify that the drawer footer is shown or hidden by `developerToolsEnabled` and that tapping it opens `DeveloperToolsPage` through `Routes.build(developerToolsEnabled: true)` in `MaterialApp.router`.
- `test/navigation_test.dart`: `Routes.build(developerToolsEnabled: false)` then `go('/developer')` builds no `DeveloperToolsPage`. The same `getIt` fakes as the home page test are registered, because the router's initial route can build pages that read them.

Changed:

- `lib/navigation.dart`: `RoutePath.developer`, `Routes.build`, conditional route, `HomePage` flag.
- `lib/features/home/presentation/home_page.dart`: `developerToolsEnabled` field and the drawer footer.
- `test/snapshots/ui_snapshots_test.dart`: two new golden tests, `developer_tools` and `developer_tools_dialog` (tap the tile in both frames).
- Goldens refreshed with `fvm flutter test --update-goldens test/snapshots/ui_snapshots_test.dart`: `home_drawer.png`, `developer_tools.png`, `developer_tools_dialog.png`. `test/snapshots/README.md` is updated as in the View spec.

## Acceptance

- [ ] When `developerToolsEnabled` is true and the drawer is open, then the footer shows "Developer tools", and tapping it closes the drawer and shows `DeveloperToolsPage`. Check: `test/features/home/presentation/home_page_test.dart`.
- [ ] When `developerToolsEnabled` is false, then the drawer has no "Developer tools" entry, and going to `/developer` builds no `DeveloperToolsPage`. Check: `test/features/home/presentation/home_page_test.dart` and `test/navigation_test.dart`.
- [ ] When the confirmation is cancelled or dismissed by tapping outside it, then `deleteAllActivity()` is never called and no snackbar shows. Check: `test/features/developer/presentation/developer_tools_page_test.dart`.
- [ ] When the user taps Delete in the dialog, then `deleteAllActivity()` is called exactly once and "All local activity deleted." shows. Check: same page test.
- [ ] While a purge is pending, then the tile shows a `CircularProgressIndicator`, tapping it opens no dialog, and a second `purge()` call returns `false` without calling the repository. Check: page test and `test/features/developer/presentation/developer_tools_view_model_test.dart`.
- [ ] When the purge fails, then "Could not delete activity: <error>" shows and "All local activity deleted." does not. Check: page test and ViewModel test.
- [ ] When the snapshot test runs, then `home_drawer.png`, `developer_tools.png` and `developer_tools_dialog.png` match in light and dark. Check: `fvm flutter test test/snapshots/ui_snapshots_test.dart`.
- [ ] When the page is shown in light and dark, then it meets `androidTapTargetGuideline`, `iOSTapTargetGuideline` and `textContrastGuideline`, and at `TextScaler.linear(2)` it renders with no overflow exception. Check: page test.
- [ ] When the whole suite runs, then it passes, including the layer boundary test. Check: `fvm flutter test` and `fvm dart tool/agent_check.dart`.
