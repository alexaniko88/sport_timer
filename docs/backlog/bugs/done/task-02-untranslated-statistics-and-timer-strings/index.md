---
id: BUG-02
status: done
type: fix
complexity: 3
depends-on: []
touches:
  - lib/features/timer/presentation/timer_page.dart
  - lib/l10n/**
  - test/features/timer/presentation/timer_page_test.dart
skills: []
---

# Timer recording notice is not translated

Category: [Bugs](../../index.md)

## Goal

The snackbar that says a workout cannot be saved to the statistics shows Spanish text when the app is in Spanish. It is the last hardcoded user-facing string in `lib/`.

## Context

- **Expected:** every user-facing string comes from `context.l10n`, with a key in both `lib/l10n/app_en.arb` and `lib/l10n/app_es.arb`.
- **Actual:** `TimerPage._showRecordingNotice` in `lib/features/timer/presentation/timer_page.dart` shows `Text('Could not save this workout to your statistics.')`. Above it sits a `FIXME-ALEX` comment block (a convention of another codebase, not used here) that names the intended key `timerRecordingUnavailable`. The key does not exist in either ARB file.
- **When it shows:** `TimerPage` shows the notice when the activity recorder cannot start a recording run (for example no signed-in account or a storage failure). The timer keeps running.
- **Reproduction:** set the device to Spanish, make the recorder fail to start, open the timer. The snackbar text is English. The widget test `test/features/timer/presentation/timer_page_test.dart` already forces this case with a fake recorder (`_Recorder()..fail = true`) and checks the English text.
- **Cause (confirmed):** the string is a literal in the widget. A search of `lib/` on `master` finds no other hardcoded user-facing English sentence. The `errorMessage` fields in the statistics and settings ViewModels are never shown by a view.
- **History:** this bug first listed several Statistics strings (empty and error states, tile labels, duration units, the date format). Later Statistics PRs moved all of them to `l10n` keys, so only this notice is left.
- Feature `timer`, layer `presentation`. Golden reference: [`timer_recording_notice.png`](../../../../../test/snapshots/goldens/timer_recording_notice.png), captured in English.

## Behavior

- New key `timerRecordingUnavailable`:
  - English (`app_en.arb`): `Could not save this workout to your statistics.` with an `@timerRecordingUnavailable` entry whose `description` is `Short notice shown when the workout runs but its activity cannot be saved to the statistics.`
  - Spanish (`app_es.arb`): `No se pudo guardar este entrenamiento en tus estadísticas.`
- Regenerate the localizations with `fvm flutter gen-l10n`.
- `_showRecordingNotice` reads the text from `context.l10n.timerRecordingUnavailable`. The `SnackBar` and its `Text` can no longer be `const`; keep the same `duration` and `showCloseIcon`.
- Remove the whole `FIXME-ALEX` comment block (the four comment lines above `content:`).
- Nothing else changes: same timing, same close icon, same English text.

## Decisions

- Scope is only this notice, because the other strings of the original report are already translated on `master` (user, during planning).
- Spanish text: `No se pudo guardar este entrenamiento en tus estadísticas.`, matching the style of `statisticsError` and `dayDetailsError` (user accepted the proposal).

## Out of scope

- Any other string, screen or ARB key.
- Showing the ViewModels' `errorMessage` values anywhere.
- Changing when or how long the notice is shown.

## Files and tests

- Change `lib/features/timer/presentation/timer_page.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`, and the generated files under `lib/l10n/` (from `fvm flutter gen-l10n`).
- In `test/features/timer/presentation/timer_page_test.dart`, keep the existing English test of the notice and add a Spanish case. Copy the existing test's setup (fake recorder that fails, `getIt` registrations, the method channel mock) and build the `MaterialApp` with `locale: const Locale('es')`.
- The golden `test/snapshots/goldens/timer_recording_notice.png` must not change. Do not run `--update-goldens`.

## Acceptance

- [x] When the recorder cannot start and the app is in English, then the snackbar shows `Could not save this workout to your statistics.` with a close icon, as before. Check: `fvm flutter test test/features/timer/presentation/timer_page_test.dart`.
- [x] When the recorder cannot start and the app is in Spanish, then the snackbar shows `No se pudo guardar este entrenamiento en tus estadísticas.`. Check: the new Spanish case in `test/features/timer/presentation/timer_page_test.dart`.
- [x] When the ARB files are read, then `timerRecordingUnavailable` exists in both, and the English file has its `@timerRecordingUnavailable` description. Check: `grep -n "timerRecordingUnavailable" lib/l10n/app_en.arb lib/l10n/app_es.arb` prints two lines for `app_en.arb` (key and `@` entry) and one for `app_es.arb`, and `fvm flutter gen-l10n` finishes without errors.
- [x] When `timer_page.dart` is read, then it contains no `FIXME-ALEX` and no hardcoded English sentence. Check: `grep -n "FIXME-ALEX\|Could not save" lib/features/timer/presentation/timer_page.dart` prints nothing.
- [x] When the UI snapshots run, then `timer_recording_notice.png` still matches. Check: `fvm flutter test test/snapshots/ui_snapshots_test.dart` passes without `--update-goldens`.
