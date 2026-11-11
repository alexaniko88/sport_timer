---
id: DEV-01-03
status: ready
type: feat
complexity: 7
depends-on: [DEV-01-01, DEV-01-02, IMP-02]
touches:
  - lib/features/developer/presentation/developer_tools_page.dart
  - lib/features/home/presentation/home_page.dart
  - lib/navigation.dart
  - CLAUDE.md
  - test/features/developer/presentation/developer_tools_page_test.dart
  - test/features/home/presentation/home_page_test.dart
  - test/navigation_test.dart
  - test/snapshots/ui_snapshots_test.dart
  - test/snapshots/README.md
  - test/snapshots/goldens/home_drawer.png
  - test/snapshots/goldens/developer_tools.png
  - test/snapshots/goldens/developer_tools_dialog.png
skills: []
---

# Add the developer page

Story: [Purge local activity](../index.md)

Epic: [Developer tools](../../../index.md)

## Goal

Add a debug-only "Developer tools" page, opened from the bottom of the navigation drawer, with one action that deletes all local activity for every account after a confirmation. In profile and release builds the entry and the route do not exist. Serves R1, R2, R3, R5 and R6.

## Context

- The drawer redesign [Rethink the navigation drawer (IMP-02)](../../../../improvements/done/task-02-rethink-navigation-drawer/index.md) is done. `lib/features/home/presentation/home_page.dart` builds a `Drawer` with a `SafeArea` and a `Column` holding a header (`Icons.timer_outlined` badge and the `Sport Timer` title), a `Divider`, and an `Expanded` `ListView` of private `_DrawerTile` (`AppSurface`) items for "Templates" and "Styles". `_onDrawerTileTapped` closes the drawer with `_scaffoldKey.currentState?.closeDrawer()` before it pushes.
- Routes: `lib/navigation.dart` has the `RoutePath` enum and `Routes.router`, a `static final GoRouter`. Its initial route `/` is the login route, whose `redirect` reads `getIt<UserRepository>().isUserLoggedIn()`. `HomePage` is created there as `const HomePage()`.
- `DeveloperToolsViewModel` and `DeveloperToolsState` exist in `lib/features/developer/presentation/` after [Add the developer tools view model (DEV-01-02)](../task-02-add-developer-tools-view-model/index.md). The ViewModel takes the `ActivityRepository` registered in `getIt` in `lib/di/di.dart`, whose `deleteAllActivity()` comes from [Purge activity storage (DEV-01-01)](../task-01-purge-activity-storage/index.md). Statistics screens refresh on `changes`, which the purge emits, so this page does nothing extra to refresh them.
- Page pattern to copy: `lib/features/login/presentation/login_page.dart` (creates its ViewModel in `State`, awaits it, checks `mounted`, shows a snackbar).
- Shared pieces: `AppSurface` (`lib/shared/presentation/widgets/app_surface.dart`, `onTap` is nullable), `AppSpacing` (`lib/shared/presentation/theme/app_spacing.dart`), text roles `tileTitle` and `tileSecondary` (`lib/shared/presentation/extensions/text_theme_extension.dart`), dialog shape from `SportTheme` (`dialogTheme`).
- Goldens: [home_drawer.png](../../../../../../test/snapshots/goldens/home_drawer.png) (drawer today), [templates_selected.png](../../../../../../test/snapshots/goldens/templates_selected.png) (page with app bar and tiles, built without a router), [account_sign_out_dialog.png](../../../../../../test/snapshots/goldens/account_sign_out_dialog.png) (confirmation dialog). Golden tests are in `test/snapshots/ui_snapshots_test.dart` (`configureFakeDependencies`, `_lightAndDarkGroup`, `_tapInBothFrames`, and a `setUp` that registers `_FakeActivityRepository`), indexed in `test/snapshots/README.md`.
- `test/features/home/presentation/home_page_test.dart` has the drawer tests from IMP-02, with private `_FakeSettingsRepository` and `_FakeUserRepository` and `FakeEmptyActivityRepository` registered in `getIt`.
- `flutter test` always runs in debug mode, so `kDebugMode` is always true in tests. That is why the gate is a flag tests can set.
- `CLAUDE.md` "Project layout" names `developer` after DEV-01-02 (features line and a `developer` bullet). Its `navigation.dart` bullet lists the routes (`/` login, `/home`, `/timer`, `/timer-styles`, `/templates`).

## Contract

- `ActivityRepository.deleteAllActivity()` — provided by DEV-01-01: `Future<Result<void>> deleteAllActivity()`. Page tests fake it.
- `DeveloperToolsState` (`isPurging`, `errorMessage`) and `DeveloperToolsViewModel(ActivityRepository)` with `state`, `Future<bool> purge()` and `dispose()` in `lib/features/developer/presentation/` — provided by DEV-01-02. `purge()` returns `true` on success; on failure it returns `false` and sets `errorMessage`; while a purge is pending it returns `false` without calling the repository.
- `RoutePath.developer` in `lib/navigation.dart` — new here: `developer('/developer')`.
- `Routes.build` in `lib/navigation.dart` — new here: `static GoRouter build({required bool developerToolsEnabled})` returns the router, and `static final router = build(developerToolsEnabled: kDebugMode);`. The existing routes stay unchanged. The `/developer` `GoRoute` (`MaterialPage` with `const DeveloperToolsPage()`, like the other routes) is in the list only when `developerToolsEnabled` is true. When it is false, going to `/developer` shows go_router's default error page and `DeveloperToolsPage` is never built. `Routes.build` passes its flag to `HomePage(developerToolsEnabled: developerToolsEnabled)`.
- `HomePage.developerToolsEnabled` — new here: `final bool developerToolsEnabled;` with `const HomePage({super.key, this.developerToolsEnabled = kDebugMode})`.
- `DeveloperToolsPage` in `lib/features/developer/presentation/developer_tools_page.dart` — new here: a `StatefulWidget` whose `State` creates `DeveloperToolsViewModel(getIt())` and disposes it in `dispose()`.
- Page flow: tapping the tile opens the confirmation with `showDialog<bool>`. "Cancel" returns `false`; tapping outside the dialog or system back returns `null`. Both mean cancel and nothing is called. "Delete" returns `true`; the page then awaits `viewModel.purge()` and stops if it is no longer mounted. On `true` it shows the success snackbar; on `false` with a non-null `errorMessage` it shows the failure snackbar.

## View spec

Where the [mockup](../mockup.html) and this View spec differ, this text wins; the mockup is the visual reference. For example, the mockup dims the tile while deleting; the app does not (see Purging below).

- **Drawer footer (`home_page.dart`):** when `developerToolsEnabled` is true, below the `Expanded` `ListView` inside the drawer's `Column`, render `Divider(height: 1, indent: AppSpacing.s16, endIndent: AppSpacing.s16)` followed by `Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, AppSpacing.s24))` holding an `AppSurface` tile wrapped in `Semantics(button: true, child: ...)`.
  - Inside `AppSurface`: a `Row` with `Icon(Icons.bug_report_outlined, color: colorScheme.primary)`, `const Gap(AppSpacing.s12)`, `Expanded(child: Text('Developer tools', maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.tileTitle))`, `const Gap(AppSpacing.s12)` and `Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant)`.
  - Tapping it closes the drawer (`_scaffoldKey.currentState?.closeDrawer()`) and calls `context.pushNamed(RoutePath.developer.value)` (no `extra`).
  - When `developerToolsEnabled` is false, neither this `Divider` nor the footer `Padding` is rendered.
- **Page layout:** a full page at `/developer`. `AppBar` with the automatic back button and the title "Developer tools". The body is a `ListView` with padding `AppSpacing.s16` holding one `AppSurface` tile. The tile's spacing matches the drawer's `_DrawerTile` in `lib/features/home/presentation/home_page.dart` exactly:
  - `AppSurface` keeps its default padding (`AppSurface.defaultPadding`, which is `AppSpacing.s12` on all sides); do not pass `padding`.
  - Child: a `Row` with `Icon(Icons.delete_sweep_outlined, color: colorScheme.primary)`, `const Gap(AppSpacing.s12)`, an `Expanded` `Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start)`, `const Gap(AppSpacing.s12)`, then a 24 by 24 trailing slot.
  - The `Column` holds the title "Delete all activity" (`tileTitle`) directly followed by the secondary text "Removes workouts and statistics for every account on this device. Settings and sign-in are kept." (`tileSecondary` with `colorScheme.onSurfaceVariant`), with no gap between them, as in `_DrawerTile`. Unlike `_DrawerTile`, the secondary text has no `maxLines` and wraps.
- **States:**
  - Default: trailing `Icons.chevron_right`; the tile is tappable (`AppSurface.onTap` set).
  - Purging (`state.isPurging`): `AppSurface.onTap` is null and the trailing slot shows a 20 by 20 `CircularProgressIndicator(strokeWidth: 2.5, semanticsLabel: 'Deleting')`. Nothing else changes: no dimming, no `Opacity`, same icon, texts and colors. The tile does not respond to taps, so a second purge cannot start from the UI.
  - Semantics in both states: the `AppSurface` is wrapped in `Semantics(button: true, enabled: !state.isPurging, child: ...)`, so the tile is a button that reads as disabled while purging. Its title and description stay readable as the button's label.
  - Confirmation: an `AlertDialog` (shape from `SportTheme`) with the title "Delete all activity?", the content "This deletes every workout and statistic for all accounts on this device. It can't be undone.", and two `TextButton`s, "Cancel" and "Delete". "Delete" uses `colorScheme.error` as its foreground color, set with `TextButton.styleFrom(foregroundColor: ...)`, no new token.
  - Success: snackbar "All local activity deleted.".
  - Failure: snackbar "Could not delete activity: <errorMessage>" (the raw error text is fine on a developer page).
  - No empty, loading-on-open or partial-data state: the page loads nothing.
  - Long text: the secondary line wraps; nothing is cut off at large text scales.
- **Interaction:** only the tile is interactive on the page; back leaves the page. The dialog's buttons and barrier work as in the Contract's page flow.
- **Navigation:** in through the drawer footer entry; out through the app bar back button or system back, which returns to Home.
- **Reuse:** `AppSurface`, `AppSpacing`, `Gap`, `tileTitle`, `tileSecondary`, theme colors. No new shared widget or token.
- **Themes:** light and dark come from the theme; no custom or phase colors.
- **Texts:** English only, as string constants in the developer page and the home page footer. No ARB keys and no Spanish (see Decisions).
- **Accessibility:** the tile and dialog buttons are at least 48 by 48. The page and the open confirmation dialog pass `androidTapTargetGuideline`, `iOSTapTargetGuideline` and `textContrastGuideline` in light and dark, and neither overflows at `TextScaler.linear(2)`. Reading order: app bar title, then the tile (title, then description). The drawer footer entry has the label "Developer tools" and is a button for screen readers.
- **Snapshots:**
  - `home_drawer.png` changes: it gains the footer entry, because tests run with the default flag `kDebugMode`, which is true.
  - New `developer_tools.png` (page, default state) and `developer_tools_dialog.png` (confirmation open over the page), light and dark like the other goldens. Both build `const DeveloperToolsPage()` directly inside `_lightAndDarkGroup`, with no router, like the existing page goldens. The `_FakeActivityRepository` that `setUp` already registers is enough. With no previous route, the `AppBar` shows only the title and no back button, as in `templates_selected.png`.
  - `developer_tools_dialog` taps the tile in both frames with `_tapInBothFrames(find.text('Delete all activity'))`.
  - `test/snapshots/README.md`: in the `home_drawer.png` row, add "a `Developer tools` entry pinned at the bottom (debug builds only)" to the description, and add ``Tap `Developer tools` → [Developer tools](goldens/developer_tools.png) (`/developer`)`` to the flow links (the link is relative to `test/snapshots/`). Add rows for the two new goldens (tile → dialog, Cancel → page, back → Home) in the table under "### 3. Navigation Drawer & Account Overlays", after the existing rows, in the format of those rows.
  - In the ASCII diagram under "## App Navigation Flow", add a third branch under `[Navigation Drawer]`: `("Developer tools", debug only)──► [Developer tools (/developer)]`. The current last branch `└── ("Styles")…` becomes `├── ("Styles")…`, and the new branch takes the `└──`.

## Mockup

[mockup.html](../mockup.html), approved by the user. It shows the drawer footer, the page, the confirmation, and the deleting, success and failure states, in light and dark. This task implements all of them.

## Decisions

- **Gate from `kDebugMode` through a flag tests can set:** release behavior must be tested, and `flutter test` always runs in debug. Chosen by the user.
- **Entry at the bottom of the drawer:** chosen by the user over placing it below "Styles".
- **Page, tile and dialog texts as in the mockup:** approved by the user.
- **No localization:** the page texts in `lib/features/developer/` and the drawer entry label "Developer tools" in `lib/features/home/presentation/home_page.dart` are hardcoded English with no ARB keys, under the Developer tools exception in the "Strings" rule of `.agents/planner-dispatcher/project-overrides.md` (debug-only, never shipped in release builds). Chosen by the user.
- **Double taps blocked in the ViewModel and in the UI:** the ViewModel guard is in DEV-01-02; this task disables the tile while purging. Chosen by the user.
- **Not dependent on the [Delete statistics story](../../../../epic-statistics/stories/story-05-delete-statistics/index.md):** chosen by the user.

## Out of scope

- The storage purge itself and stale-write handling (that is [Purge activity storage (DEV-01-01)](../task-01-purge-activity-storage/index.md)).
- The ViewModel and state logic (that is [Add the developer tools view model (DEV-01-02)](../task-02-add-developer-tools-view-model/index.md)).
- Any other developer tool, showing row counts, account-specific deletion, or changes to settings or sign-in.
- Localization and Spanish strings for this page.

## Files and tests

- New: `lib/features/developer/presentation/developer_tools_page.dart`, `test/features/developer/presentation/developer_tools_page_test.dart` and `test/navigation_test.dart`.
- Fakes: hand-written, no mocking package. Do not change `test/features/statistics/fake_activity_repository.dart` and do not create a new shared test helper. `developer_tools_page_test.dart` declares a private `ActivityRepository` fake that implements only `deleteAllActivity()`, which counts calls and returns the future of a `Completer<Result<void>>` the test controls (success or `Failure(Exception('boom'))`), and `changes` as an empty stream if the page reads it; every other member goes to `noSuchMethod` with `@override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);`, exactly like the private fakes in `test/snapshots/ui_snapshots_test.dart`, so any unexpected call throws.
- `developer_tools_page_test.dart`: behavioral widget test, because the dialog flow, the snackbars and the blocked tile while purging are interactions that unit tests and goldens cannot check. The fake is registered in `getIt` in `setUp`, and `getIt.reset()` runs in `tearDown`. Each accessibility case ("page meets accessibility guidelines", "confirmation dialog meets accessibility guidelines") is one `testWidgets` whose body loops over `SportTheme.light` and `SportTheme.dark`, pumping each and checking all three guidelines, so the test name matches the Check exactly; do not split it per theme or generate names per theme.
- `home_page_test.dart`: widget test; extend the existing drawer tests.
  - The shared router in `setUp` keeps its routes and builds `const HomePage(developerToolsEnabled: false)`, so the existing case "drawer shows the header and two tiles with the active values" keeps its counts unchanged (one `Divider`, two `AppSurface`, two chevrons). The other existing cases also run with the entry hidden.
  - "drawer hides the Developer tools entry when disabled" uses that shared router.
  - "drawer shows the Developer tools entry when enabled" and "tapping Developer tools closes the drawer and opens /developer" each build their own router with `Routes.build(developerToolsEnabled: true)` in `MaterialApp.router`, dispose it with `addTearDown`, and go to `RoutePath.home.value` first, since the initial route is login.
- `navigation_test.dart`: widget test with `Routes.build(developerToolsEnabled: false)` in `MaterialApp.router`. The initial route can build pages that read `getIt`, so `setUp` registers the shared `FakeEmptyActivityRepository` from `test/features/statistics/fake_activity_repository.dart` (reused, not changed) and private copies of `_FakeSettingsRepository` and `_FakeUserRepository`, copied from `test/features/home/presentation/home_page_test.dart`. Dispose the router and run `getIt.reset()` in `tearDown`.
- `CLAUDE.md`, "Project layout": change the `developer` bullet from DEV-01-02 to "- `developer`: debug-only Developer tools page and its ViewModel, presentation only.", and add `/developer` (debug only) to the routes in the `navigation.dart` bullet. Change nothing else in the file.
- Snapshots: add the two golden tests to `test/snapshots/ui_snapshots_test.dart`, refresh only the three listed images with `fvm flutter test --update-goldens test/snapshots/ui_snapshots_test.dart`, and update `test/snapshots/README.md` as in the View spec.

## Acceptance

- [ ] Given a router built with `Routes.build(developerToolsEnabled: true)`, when the drawer is open, then the footer shows "Developer tools" as a button. Check: `test/features/home/presentation/home_page_test.dart` "drawer shows the Developer tools entry when enabled".
- [ ] Given a router built with `Routes.build(developerToolsEnabled: true)`, when the "Developer tools" entry is tapped, then the drawer closes and `DeveloperToolsPage` is shown. Check: `test/features/home/presentation/home_page_test.dart` "tapping Developer tools closes the drawer and opens /developer".
- [ ] Given the shared `setUp` router with `HomePage(developerToolsEnabled: false)`, when the drawer is open, then it has no "Developer tools" entry and no footer divider. Check: `test/features/home/presentation/home_page_test.dart` "drawer hides the Developer tools entry when disabled".
- [ ] Given the shared `setUp` router with `HomePage(developerToolsEnabled: false)`, when the drawer is open, then it still shows the header, one `Divider` and the two tiles with the active values. Check: `test/features/home/presentation/home_page_test.dart` "drawer shows the header and two tiles with the active values".
- [ ] When the router is built with `developerToolsEnabled: false` and goes to `/developer`, then no `DeveloperToolsPage` is built. Check: `test/navigation_test.dart` "developer route does not exist when developer tools are disabled".
- [ ] When the confirmation is cancelled with "Cancel", then `deleteAllActivity()` is never called and no snackbar shows. Check: `test/features/developer/presentation/developer_tools_page_test.dart` "Cancel does not delete".
- [ ] When the confirmation is dismissed by tapping outside it, then `deleteAllActivity()` is never called and no snackbar shows. Check: `test/features/developer/presentation/developer_tools_page_test.dart` "tapping outside the dialog does not delete".
- [ ] When the user taps "Delete" and the purge succeeds, then `deleteAllActivity()` is called exactly once and "All local activity deleted." shows. Check: `test/features/developer/presentation/developer_tools_page_test.dart` "Delete purges and shows the success snackbar".
- [ ] While a purge is pending, then the tile shows a `CircularProgressIndicator` and tapping it opens no dialog. Check: `test/features/developer/presentation/developer_tools_page_test.dart` "tile is blocked while purging".
- [ ] When the purge fails, then "Could not delete activity: <error>" shows and "All local activity deleted." does not. Check: `test/features/developer/presentation/developer_tools_page_test.dart` "failure shows the error snackbar".
- [ ] When the page is shown in light and dark, then it meets `androidTapTargetGuideline`, `iOSTapTargetGuideline` and `textContrastGuideline`. Check: `test/features/developer/presentation/developer_tools_page_test.dart` "page meets accessibility guidelines".
- [ ] When the page renders at `TextScaler.linear(2)`, then no overflow exception is thrown. Check: `test/features/developer/presentation/developer_tools_page_test.dart` "page renders at 2x text scale".
- [ ] When the confirmation dialog is open in light and dark, then it meets `androidTapTargetGuideline`, `iOSTapTargetGuideline` and `textContrastGuideline`. Check: `test/features/developer/presentation/developer_tools_page_test.dart` "confirmation dialog meets accessibility guidelines".
- [ ] When the confirmation dialog is open at `TextScaler.linear(2)`, then no overflow exception is thrown. Check: `test/features/developer/presentation/developer_tools_page_test.dart` "confirmation dialog renders at 2x text scale".
- [ ] When the drawer is open in debug builds, then it shows the footer entry in light and dark. Check: `test/snapshots/goldens/home_drawer.png`.
- [ ] When the developer page is shown, then it matches the default state in light and dark. Check: `test/snapshots/goldens/developer_tools.png`.
- [ ] When the tile is tapped, then the confirmation dialog matches in light and dark. Check: `test/snapshots/goldens/developer_tools_dialog.png`.
- [ ] When `CLAUDE.md` changes, then "Project layout" still names every feature folder, including `developer`. Check: `test/architecture/ai_setup_test.dart` "every folder under lib/features is named in the "Project layout" section of CLAUDE.md".
- [ ] When the checks run, then they pass, including the layer boundary test. Check: `fvm dart tool/agent_check.dart --skip-build`.
