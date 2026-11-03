# BUG-02: Statistics and timer notice text is not translated

Category: [Bugs](index.md)

Related: [Statistics epic](../statistics/index.md) shares these files; coordinate with any active Statistics story that edits them.

Status: Ready for planning.

## Problem and impact

The app is localized in English and Spanish with `gen-l10n`, but part of the Statistics screen and one timer notice are hardcoded in English. With the device in Spanish these texts stay in English next to translated text, for example an English error message above the translated Retry button.

**Expected:** Every user-facing string, including accessibility labels, comes from `context.l10n` in both `app_en.arb` and `app_es.arb`, and dates follow the app locale.

**Actual:** The strings below are English literals in the widgets or in presentation extensions.

## Confirmed findings

Found by searching `lib/` for hardcoded user-facing text on the checkout of branch `improve/unify-app-styles`. The Retry button label was already localized there as `statisticsRetryButton`.

- Statistics page (`lib/features/statistics/presentation/statistics_page.dart`): the empty-state message "No completed activity yet." and the error message "Could not load your statistics."
- Daily activity tile (`lib/features/statistics/presentation/widgets/daily_activity_tile.dart`): the "Work:", "Rest:" and "Total:" lines, the "round" and "rounds" text built with a manual singular and plural check, and the accessibility label ("..., work ..., rest ..., total ...").
- Duration text (`lib/features/statistics/presentation/extensions/duration_extension.dart`): "hour(s)", "minute(s)" and "second(s)" with manual plurals.
- Date (`lib/features/statistics/presentation/extensions/daily_activity_extension.dart`): `DateFormat('d MMMM y', 'en_US')` ignores the app locale, so Spanish shows an English month name.
- Timer notice (`lib/features/timer/presentation/timer_page.dart`): "Could not save this workout to your statistics." It carries a `FIXME-ALEX` block, which this project does not use, because real localization exists.

Not confirmed: whether other hardcoded strings exist outside `Text`, `label` and `tooltip` call sites (for example in data-layer error messages shown to the user). Planning should repeat the search.

## Scope and exclusions

- Replace each string above with `l10n` keys in both ARB files, using ICU plural messages for counts, and regenerate with `fvm flutter gen-l10n`. Add a `description` to each English key.
- Format the date with the app locale, not a fixed `en_US` locale.
- Remove the `FIXME-ALEX` block from the timer notice once its key exists.
- Keep the Statistics layout and styles unchanged. No new features and no changes to what is recorded or shown.
- Presentation extensions that need `l10n` take it as a parameter or become extensions on `AppLocalizations`, following the project's extension rules. The plan names each file.

## Dependencies

None. The Statistics charts story edits some of the same files, so check which branch lands first.

## Acceptance criteria

- No hardcoded user-facing English text remains in the Statistics feature or the timer notice, including semantic labels.
- With the app in Spanish, the Statistics screens (content, empty, error) and the timer notice show Spanish text, and the date uses a Spanish month name.
- Counts use correct singular and plural forms in both languages.
- English output looks the same as before.
- The `FIXME-ALEX` block is gone from the timer notice.

## Validation

Update the existing Statistics widget and unit tests that assert the English strings, and add a Spanish case for the tile, the empty and error states, and the date. Run `fvm flutter analyze` and the full test suite, and refresh the affected goldens in `test/snapshots/goldens/` with `fvm flutter test --update-goldens test/snapshots/ui_snapshots_test.dart` only if English output changes.

## UI snapshot reference

Current captured states: [statistics](../../test/snapshots/goldens/statistics.png), [statistics_empty](../../test/snapshots/goldens/statistics_empty.png), [statistics_error](../../test/snapshots/goldens/statistics_error.png) and [timer_recording_notice](../../test/snapshots/goldens/timer_recording_notice.png). See the [snapshot index](../../test/snapshots/README.md). The goldens are captured in English, so Spanish needs widget tests. These images are a baseline, not an approved design.
