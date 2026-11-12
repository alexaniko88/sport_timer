---
id: STAT-05-02
status: ready
type: feat
complexity: 4
depends-on: [STAT-05-01]
touches:
  - lib/features/statistics/presentation/statistics_state.dart
  - lib/features/statistics/presentation/statistics_view_model.dart
  - lib/features/statistics/presentation/statistics_page.dart
  - lib/l10n/
  - test/features/statistics/presentation/statistics_state_test.dart
  - test/features/statistics/presentation/statistics_view_model_test.dart
  - test/features/statistics/presentation/statistics_page_test.dart
  - test/snapshots/ui_snapshots_test.dart
  - test/snapshots/README.md
  - test/snapshots/goldens/statistics*.png
skills: []
---

# Add the delete action to Statistics

Story: [Delete statistics](../index.md)

Epic: [Statistics](../../../index.md)

## Goal

A ⋮ menu in the Statistics app bar with "Delete statistics", a confirmation dialog and the result snackbar, calling the delete from Delete local statistics (STAT-05-01); and an empty Statistics screen that shows only the centered empty text. Serves R1, R2, R3, R4, R7 and R8.

## Context

- `lib/features/statistics/presentation/statistics_page.dart`: `AppBar(leading: menu, title: statisticsTitle, actions: [AccountAvatarButton(...), SizedBox(width: AppSpacing.s8)])`; the page owns `_viewModel` (`StatisticsViewModel`).
- `lib/features/statistics/presentation/statistics_view_model.dart` refreshes when `_repository.changes` emits, so a successful delete refreshes the list and charts by itself. `statistics_state.dart` holds `StatisticsState` with `copyWith`.
- Snapshot scenarios `statistics`, `statistics_empty`, `statistics_error` and the chart/consistency loops in `test/snapshots/ui_snapshots_test.dart` open the tab with `whilePerforming: _tapInBothFrames(find.text('Statistics'))`; the harness's `_FakeActivityRepository` needs no change (it sends unknown members to `noSuchMethod`, and no scenario deletes).
- Dialog pattern: `_confirmSignOut` in `lib/features/account/presentation/account_avatar_button.dart` (`AlertDialog` with two `TextButton`s popping `false` / `true`).

## Contract

- `ActivityRepository.deleteAccountActivity()` — provided by STAT-05-01.
- `StatisticsState.isDeleting` — new here: `bool`, default `false`, in `copyWith`, `==` and `hashCode`.
- `StatisticsViewModel.deleteStatistics()` — new here: `Future<bool>`. Returns `false` at once when `isDeleting`; sets `isDeleting: true`, awaits `deleteAccountActivity()`, sets `isDeleting: false` (unless disposed), returns `true` on `Success` and `false` on `Failure`. It does not touch the activity list; `changes` refreshes it.

## View spec

- The `AppBar` is built outside the page's `ValueListenableBuilder`, so wrap the menu in its own `ValueListenableBuilder<StatisticsState>` on `_viewModel.state`.
- App bar `actions`: `PopupMenuButton<_StatisticsMenuAction>` (private enum with one value `delete`) with `icon: const Icon(Icons.more_vert)` and the default Material tooltip, then `AccountAvatarButton`, then `SizedBox(width: AppSpacing.s8)`. Shown only when `state.status == StatisticsStatus.content` (there is something to delete); with `initial`, `loading`, `empty` or `error` there is no ⋮ at all. Its one `PopupMenuItem` has `Text(l10n.statisticsDeleteAction)` and `enabled: !state.isDeleting`.
- Item tap → `showDialog<bool>`: title `statisticsDeleteDialogTitle`, content `statisticsDeleteDialogBody`, actions `TextButton(commonCancel)` (returns `false`) and `TextButton(style: TextButton.styleFrom(foregroundColor: colorScheme.error), child: Text(statisticsDeleteDialogConfirm))` (returns `true`). Cancel or dismiss → nothing.
- Confirm → `await _viewModel.deleteStatistics()`; if still mounted, `true` → snackbar `statisticsDeleted`; `false` → snackbar `statisticsDeleteError`.
- Strings (en / es, each English key with a `description`):
  - `statisticsDeleteAction`: "Delete statistics" / "Eliminar estadísticas"
  - `statisticsDeleteDialogTitle`: "Delete statistics?" / "¿Eliminar las estadísticas?"
  - `statisticsDeleteDialogBody`: "All statistics of this account on this device will be deleted. This can't be undone." / "Se eliminarán todas las estadísticas de esta cuenta en este dispositivo. No se puede deshacer."
  - `statisticsDeleteDialogConfirm`: "Delete" / "Eliminar"
  - `statisticsDeleted`: "Statistics deleted" / "Estadísticas eliminadas"
  - `statisticsDeleteError`: "Couldn't delete statistics. Try again." / "No se pudieron eliminar las estadísticas. Inténtalo de nuevo."
- **Empty screen:** when `state.status == StatisticsStatus.empty`, the body is only `Center(child: Text(l10n.statisticsEmpty))`, in both views: no `SegmentedButton` switcher and no `_ChartControls`. Other states keep today's layout.
- After a successful delete the status becomes `empty` through `changes`, so the screen switches to the empty layout and the ⋮ disappears.
- Both themes; the dialog text wraps at larger text sizes (default `AlertDialog` behavior, no fixed heights).

## Decisions

- **Menu, not a direct icon:** chosen by the user, to leave room for later options.
- **No menu without actions:** the menu shows only when it has an available action; delete is available only with content. Chosen by the user.
- **Empty screen without the switcher:** chosen by the user; there is nothing to switch between.
- Mockup: [mockup.html](../mockup.html), approved by the user: data with ⋮, menu open, menu while deleting, dialog, after delete, failed delete, empty history; both themes and languages.

## Out of scope

- Day details page (it refreshes through `changes` already). Any data-layer change.

## Files and tests

- Unit: `statistics_state_test.dart` (one case for `isDeleting`). `statistics_view_model_test.dart`: its fake gets `deleteAccountActivity()` returning the future of a test-controlled `Completer<Result<void>>` and an `int deleteCalls` counter.
- Widget: `statistics_page_test.dart` (reason: the dialog flow, snackbars, disabled item and labels cannot be checked by goldens). Its fake gets `deleteAccountActivity()` with a configurable `Result<void>` (or a `Completer` for the busy case) and an `int deleteCalls` counter.
- Goldens: refresh every `statistics*.png` that changes: content states gain the ⋮, and `statistics_empty` loses the switcher. `statistics_error.png` stays the same.
- The `empty` cases of the `statistics chart $chartState` and `statistics consistency $calendarState` loops set `activityRepository.result = const Success([])`, which now hides the switcher, so they would lose what they show (an empty chart period). Keep them showing it: set the result to a one-day history outside the shown period instead — one `DailyActivity` built like the harness's existing days but with `localDate: '2025-01-15'` (the view model's clock is `DateTime(2026, 10, 31)`). Their file names stay; their rows in `test/snapshots/README.md` become "No activity in the shown period (history has older days)". New scenarios: `statistics_menu` (data state, `whilePerforming` taps "Statistics" then the ⋮ icon, chained with `_tapInBothFrames`) and `statistics_delete_dialog` (same, then taps "Delete statistics"). Add both rows to `test/snapshots/README.md` under Statistics with the menu → dialog flow.
- Run `fvm flutter gen-l10n` after editing both ARB files.

## Acceptance

- [ ] When two states differ only in `isDeleting`, then they are not equal, and `copyWith(isDeleting: true)` sets it. Check: `test/features/statistics/presentation/statistics_state_test.dart` "isDeleting is part of the state".
- [ ] When `deleteStatistics()` succeeds, then it returns `true` and `isDeleting` goes `true` then `false`. Check: `test/features/statistics/presentation/statistics_view_model_test.dart` "delete succeeds and clears the busy flag".
- [ ] When the repository fails, then `deleteStatistics()` returns `false` and `isDeleting` is `false` again. Check: `test/features/statistics/presentation/statistics_view_model_test.dart` "failed delete returns false".
- [ ] When `deleteStatistics()` is called twice before the first ends, then the repository is called once and the second call returns `false`. Check: `test/features/statistics/presentation/statistics_view_model_test.dart` "a second delete while busy is ignored".
- [ ] When the user confirms the dialog and the delete succeeds, then "Statistics deleted" shows. Check: `test/features/statistics/presentation/statistics_page_test.dart` "confirm deletes and reports success".
- [ ] When the delete fails, then "Couldn't delete statistics. Try again." shows and no success message appears. Check: `test/features/statistics/presentation/statistics_page_test.dart` "failed delete shows an error".
- [ ] When the dialog is cancelled or dismissed, then the repository's delete is not called. Check: `test/features/statistics/presentation/statistics_page_test.dart` "cancel keeps the statistics".
- [ ] Given a delete is running, when the menu opens, then "Delete statistics" is disabled. Check: `test/features/statistics/presentation/statistics_page_test.dart` "delete item is disabled while deleting".
- [ ] When a screen reader reads the app bar, then the ⋮ is a button with the Material "Show menu" tooltip. Check: `test/features/statistics/presentation/statistics_page_test.dart` "menu button is labelled".
- [ ] Given the Spanish locale and 2x text, when the dialog opens, then it shows "¿Eliminar las estadísticas?", the Spanish body and "Eliminar" with no overflow. Check: `test/features/statistics/presentation/statistics_page_test.dart` "Spanish dialog fits at large text".
- [ ] When the history is empty, then there is no ⋮, no List/Charts switcher, and "No completed activity yet." is centered, in both themes. Check: `test/snapshots/goldens/statistics_empty.png`.
- [ ] When the history has content, then the ⋮ is in the app bar. Check: `test/snapshots/goldens/statistics.png`.
- [ ] Given an empty history with the view set to charts, when the page shows, then there is no switcher, no chart controls and only the centered empty text. Check: `test/features/statistics/presentation/statistics_page_test.dart` "empty history hides the switcher in both views".
- [ ] Given history only outside the shown period, when the charts view shows, then the switcher, the period controls and the empty-period chart are there. Check: `test/snapshots/goldens/statistics_chart_empty.png`.
- [ ] When the status is loading, empty or error, then no ⋮ is shown; after a successful delete, the ⋮ and the switcher disappear. Check: `test/features/statistics/presentation/statistics_page_test.dart` "menu shows only with content".
- [ ] When the ⋮ is tapped, then the menu shows "Delete statistics" in both themes. Check: `test/snapshots/goldens/statistics_menu.png`.
- [ ] When "Delete statistics" is tapped, then the dialog shows the title, the explanation, Cancel and Delete. Check: `test/snapshots/goldens/statistics_delete_dialog.png`.
- [ ] When the checks run, then everything passes, including `gen-l10n`. Check: `fvm dart tool/agent_check.dart --skip-build`.
