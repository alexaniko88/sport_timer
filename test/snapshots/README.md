# Sport Timer UI Snapshot Reference

This directory holds repeatable Alchemist platform golden snapshots (`goldens/*.png`) and their generator test (`ui_snapshots_test.dart`). Together they provide a visual reference of the implemented app and its navigation flow without launching an emulator or signing into an account.

- **Phone size:** `390 × 844` logical pixels (portrait)
- **Locale:** English (`en`)
- **Themes:** `Light` (`SportTheme.light`) and `Dark` (`SportTheme.dark`) side-by-side in every image
- **Fixture user:** `Alex Runner` (`alex@example.com`, no network avatar URL)

---

## Commands & Maintenance

Generate or refresh the snapshots on macOS after a UI, state, or route change:

```bash
fvm flutter test --update-goldens test/snapshots/ui_snapshots_test.dart
```

Verify that the current widget tree matches the committed snapshots:

```bash
fvm flutter test test/snapshots/ui_snapshots_test.dart
```

> **Maintenance requirement:** Any UI change that alters a captured screen, state, or route transition must refresh the affected PNG snapshots in `test/snapshots/goldens/` and update the flow descriptions and links in this index.

---

## App Navigation Flow

```
[Login (/)]
   │  ("Continue with Google" succeeds, or signed-in redirect)
   ▼
[Home (/home)] ──(App bar menu icon)──► [Navigation Drawer]
   │                                       ├── ("Templates")──► [Templates (/templates)]
   │                                       └── ("Timer styles")──► [Timer Styles (/timer-styles)]
   ├── Tab 0: Timer / Setup ("Are you prepared?")
   │     ├── Tap "Template: <name>" chip ──► [Templates (/templates)]
   │     ├── Tap Preparation / Work / Rest card ──► opens Time Picker bottom sheet
   │     ├── Tap Rounds card ──► opens Rounds Picker bottom sheet
   │     └── Tap "Start" card ──► [Timer (/timer)]
   ├── Tab 1: Statistics ("Your statistics")
   └── App bar avatar ("A") ──► [Account Bottom Sheet]
                                   └── Tap "Sign out" ──► [Sign-Out Confirmation Dialog]
                                                             └── Tap "Sign out" ──► [Login (/)]
```

---

## Snapshot Catalog

### 1. Login (`/`)

| Snapshot | Screen & State | Themes | Next Screens / Transitions |
| --- | --- | --- | --- |
| [`goldens/login.png`](goldens/login.png) | **Login (`LoginPage`)** — Idle welcome state with `"Welcome to Sport Timer"` heading and `"Continue with Google"` button. | Light & Dark | Tapping `"Continue with Google"` signs in and navigates to [`Home — Setup`](#2-home--timer-setup-home-tab-0) (`goldens/setup_custom.png`). If already signed in, `/` redirects straight to `/home`. |

---

### 2. Home — Timer Setup (`/home`, Tab 0)

| Snapshot | Screen & State | Themes | Next Screens / Transitions |
| --- | --- | --- | --- |
| [`goldens/setup_custom.png`](goldens/setup_custom.png) | **Timer Setup (`TimerSetupPage`) — Custom Settings**, with the Timer destination selected in the bottom navigation — Custom durations (`00:10` preparation, `01:30` work, `00:15` rest, `3` rounds, `05:10` session length) with no template chip shown. | Light & Dark | • Tap a duration card → [`Time Picker`](#2-home--timer-setup-home-tab-0) (`goldens/setup_time_picker.png`)<br>• Tap `Rounds` → [`Rounds Picker`](#2-home--timer-setup-home-tab-0) (`goldens/setup_rounds_picker.png`)<br>• Tap `"Start"` → [`Timer`](#6-timer-timer) (`goldens/timer_ring_preparation.png`)<br>• Tap menu icon → [`Navigation Drawer`](#3-navigation-drawer--account-overlays) (`goldens/home_drawer.png`)<br>• Tap avatar `"A"` → [`Account Sheet`](#3-navigation-drawer--account-overlays) (`goldens/account_sheet.png`)<br>• Bottom nav switches to [`Statistics`](#5-home--statistics--timer-styles). |
| [`goldens/setup_template_selected.png`](goldens/setup_template_selected.png) | **Timer Setup (`TimerSetupPage`) — Template Selected** — Displays the `"Template: Hyrox"` shortcut chip above the four cards (`00:20` prep, `05:00` work, `01:00` rest, `8` rounds, `47:20` session length). | Light & Dark | • Tap `"Template: Hyrox"` chip → pushes [`Templates — Selected`](goldens/templates_selected.png) (`/templates`)<br>• Editing any card clears the template selection and transitions to [`Setup — Custom`](goldens/setup_custom.png)<br>• Tap `"Start"` → [`Timer`](#6-timer-timer) (`goldens/timer_ring_preparation.png`). |
| [`goldens/setup_time_picker.png`](goldens/setup_time_picker.png) | **Timer Setup — Duration Wheel Picker (`TimerSettingsPickerWheel`, `PicketType.time`)** — Modal bottom sheet open for `"Work"` showing `"Minutes"` (`01`) and `"Seconds"` (`30`) wheels. | Light & Dark | Scrolling updates the duration live; dismissing the sheet flushes settings and returns to [`Setup — Custom`](goldens/setup_custom.png). |
| [`goldens/setup_rounds_picker.png`](goldens/setup_rounds_picker.png) | **Timer Setup — Rounds Wheel Picker (`TimerSettingsPickerWheel`, `PicketType.rounds`)** — Modal bottom sheet open for `"Rounds"` with `3` selected. | Light & Dark | Scrolling updates the round count live; dismissing the sheet flushes settings and returns to [`Setup — Custom`](goldens/setup_custom.png). |

---

### 3. Navigation Drawer & Account Overlays

| Snapshot | Screen & State | Themes | Next Screens / Transitions |
| --- | --- | --- | --- |
| [`goldens/home_drawer.png`](goldens/home_drawer.png) | **Navigation Drawer (`HomePage` drawer)** — Open side drawer with rounded trailing corners, `"Sport Timer"` title, `"Templates"` destination, and `"Timer styles"` destination. | Light & Dark | • Tap `"Templates"` → closes drawer and pushes [`Templates`](goldens/templates_selected.png) (`/templates`)<br>• Tap `"Timer styles"` → closes drawer and pushes [`Timer Styles`](goldens/timer_styles.png) (`/timer-styles`). |
| [`goldens/account_sheet.png`](goldens/account_sheet.png) | **Account Bottom Sheet (`AccountAvatarButton`)** — Modal bottom sheet showing avatar initial `"A"`, display name `"Alex Runner"`, email `"alex@example.com"`, and `"Sign out"` action. | Light & Dark | Tapping `"Sign out"` opens [`Sign-Out Confirmation Dialog`](goldens/account_sign_out_dialog.png). Dismissing returns to the underlying Home tab. |
| [`goldens/account_sign_out_dialog.png`](goldens/account_sign_out_dialog.png) | **Sign-Out Confirmation Dialog (`AlertDialog`)** — Confirmation dialog (`"Sign out?"` / `"Do you want to sign out of your account?"`) layered over the account sheet. | Light & Dark | • Tap `"Cancel"` → closes dialog back to [`Account Sheet`](goldens/account_sheet.png)<br>• Tap `"Sign out"` → signs out and navigates to [`Login`](goldens/login.png) (`/`). |

---

### 4. Templates (`/templates`)

| Snapshot | Screen & State | Themes | Next Screens / Transitions |
| --- | --- | --- | --- |
| [`goldens/templates_selected.png`](goldens/templates_selected.png) | **Templates (`TemplatesPage`, `/templates`) — Built-in Template Selected** — `"Choose your template"` title with back button (no drawer menu, avatar, bottom bar, or FAB); `"Hyrox"` (`47m 20s`) highlighted with check icon; `"Custom"` tile hidden. | Light & Dark | • Tap another template tile → selects that preset and updates Setup (`goldens/setup_template_selected.png`)<br>• Back navigation returns to the originating Home tab. |
| [`goldens/templates_custom.png`](goldens/templates_custom.png) | **Templates (`TemplatesPage`, `/templates`) — Custom Settings Row** — Shows the amber-bordered `"Custom"` card (`0:10 prep · 1:30 work · 0:15 rest · 3 rounds`, `5m 10s`) with its phase bar above the five built-in templates (`Default`, `Full Abs`, `Hyrox`, `Stretching`, `Strength`). | Light & Dark | • Tap any built-in template tile → collapses `"Custom"` and transitions to [`Templates — Selected`](goldens/templates_selected.png)<br>• Back navigation returns to the originating Home tab. |

---

### 5. Home — Statistics & Timer Styles

| Snapshot | Screen & State | Themes | Next Screens / Transitions |
| --- | --- | --- | --- |
| [`goldens/statistics.png`](goldens/statistics.png) | **Statistics (`StatisticPage`, `/home` Tab 1)** — Daily activity cards showing the date, rounds, work, rest and total. Cards open the selected day’s details. The List / Charts control switches views. | Light & Dark | • Tap Charts → [`Work time chart`](goldens/statistics_chart_content.png)<br>• Tap a daily card → [`Day details`](goldens/day_details.png)<br>• Bottom nav switches to [`Setup`](goldens/setup_custom.png)<br>• App bar menu opens [`Navigation Drawer`](goldens/home_drawer.png)<br>• App bar avatar opens [`Account Sheet`](goldens/account_sheet.png). |
| [`goldens/statistics_empty.png`](goldens/statistics_empty.png) | **Statistics — Empty** — No completed activity message. | Light & Dark | Switching tabs returns to Setup. |
| [`goldens/statistics_error.png`](goldens/statistics_error.png) | **Statistics — Error** — Load failure message and Retry button. | Light & Dark | Retry requests the daily totals again. |
| [`goldens/statistics_chart_content.png`](goldens/statistics_chart_content.png) | **Statistics — Work time chart** — Current week, period total, date navigation and daily bars. | Light & Dark | Select a bar to show its exact value. |
| [`goldens/statistics_chart_selected.png`](goldens/statistics_chart_selected.png) | **Statistics — Selected bar** — The selected date and work time replace the period summary. | Light & Dark | Select the bar again to restore the period total. |
| [`goldens/statistics_chart_empty.png`](goldens/statistics_chart_empty.png) | **Statistics — Empty chart period** — No recorded activity, with period controls available. | Light & Dark | Navigate to another period or switch to List. |
| [`goldens/statistics_chart_error.png`](goldens/statistics_chart_error.png) | **Statistics — Chart error** — Load failure, retry and period controls. | Light & Dark | Retry requests activity again. |
| [`goldens/day_details.png`](goldens/day_details.png) | **Day details** — Daily totals and separate run cards with completed activity and original settings. | Light & Dark | Back navigation returns to Statistics. |
| [`goldens/day_details_empty.png`](goldens/day_details_empty.png) | **Day details — Empty** — No completed activity for the selected day. | Light & Dark | Back navigation returns to Statistics. |
| [`goldens/day_details_error.png`](goldens/day_details_error.png) | **Day details — Error** — Load failure and Retry button. | Light & Dark | Retry requests the selected day again. |
| [`goldens/timer_styles.png`](goldens/timer_styles.png) | **Timer Styles (`TimerStylesPage`, `/timer-styles`)** — Lists the three timer style preview cards (`Ring`, `Full color`, `Rounds strip`) with `Ring` selected. | Light & Dark | • Tap a style card → persists that `TimerStyle` for the next workout (`Ring` → [`goldens/timer_ring_round.png`](goldens/timer_ring_round.png), `Full color` → [`goldens/timer_full_color_round.png`](goldens/timer_full_color_round.png), `Rounds strip` → [`goldens/timer_rounds_strip_round.png`](goldens/timer_rounds_strip_round.png))<br>• Back navigation returns to [`Home`](goldens/setup_custom.png). |

---

### 6. Timer (`/timer`)

The timer screen renders one of three styles (`RingTimerView`, `FullColorTimerView`, `RoundsStripTimerView`) chosen on `/timer-styles`. Tapping anywhere on the screen or pressing the pause/play button toggles pause/resume while running.

| Snapshot | Screen & State | Themes | Next Screens / Transitions |
| --- | --- | --- | --- |
| [`goldens/timer_recording_notice.png`](goldens/timer_recording_notice.png) | **Timer — Recording Notice (`TimerPage`)** — The timer runs in its preparation phase, and a 3-second snackbar with a close icon says the workout cannot be saved to the statistics. | Light & Dark | Disappears after 3 seconds or when the close icon is tapped, and the timer keeps running ([`Ring — Preparation`](goldens/timer_ring_preparation.png)). |
| [`goldens/timer_ring_preparation.png`](goldens/timer_ring_preparation.png) | **Timer — Ring (`RingTimerView`) — Preparation Phase** — `"PREPARE"` pill, `00:07` remaining (`30%` ring progress), `"Total 05:07"`, pause button. | Light & Dark | Advances automatically to [`Ring — Round`](goldens/timer_ring_round.png) when preparation reaches `00:00`, or pauses on tap ([`Ring — Paused`](goldens/timer_ring_paused.png)). |
| [`goldens/timer_ring_round.png`](goldens/timer_ring_round.png) | **Timer — Ring (`RingTimerView`) — Round Phase** — `"ROUND"` pill, `"2 of 3"` subtitle, `01:12` remaining (`20%` ring progress), `"Total 02:57"`, pause button. | Light & Dark | Advances to [`Ring — Rest`](goldens/timer_ring_rest.png) (between rounds) or [`Ring — Finished`](goldens/timer_ring_finished.png) (after final round); tap pauses ([`Ring — Paused`](goldens/timer_ring_paused.png)). |
| [`goldens/timer_ring_rest.png`](goldens/timer_ring_rest.png) | **Timer — Ring (`RingTimerView`) — Rest Phase** — `"REST"` pill, `"3 of 3"` next-round subtitle, `00:10` remaining (`33%` ring progress), `"Total 01:40"`, pause button. | Light & Dark | Advances to the next [`Ring — Round`](goldens/timer_ring_round.png) when rest reaches `00:00`. |
| [`goldens/timer_ring_paused.png`](goldens/timer_ring_paused.png) | **Timer — Ring (`RingTimerView`) — Paused State** — Dimmed `00:45` time text (`40%` opacity) and play/resume button (`Icons.play_arrow_rounded`). | Light & Dark | Tapping anywhere or pressing the play button resumes [`Ring — Round`](goldens/timer_ring_round.png). |
| [`goldens/timer_ring_finished.png`](goldens/timer_ring_finished.png) | **Timer — Ring (`RingTimerView`) — Finished State** — `"DONE"` pill, full green ring at `00:00`, `"3 rounds done"`, `"Total 05:10"`, pause button hidden. | Light & Dark | System back navigation returns to [`Home — Setup`](goldens/setup_custom.png). |
| [`goldens/timer_full_color_round.png`](goldens/timer_full_color_round.png) | **Timer — Full Color (`FullColorTimerView`) — Round Phase** — Full-bleed round color background with top progress curtain (`20%` height), `"ROUND"`, `"2 of 3"`, `01:12`, `"Total 02:57"`. | Light & Dark | Tap pauses ([`Full Color — Paused`](goldens/timer_full_color_paused.png)); system back returns to [`Home`](goldens/setup_custom.png). |
| [`goldens/timer_full_color_paused.png`](goldens/timer_full_color_paused.png) | **Timer — Full Color (`FullColorTimerView`) — Paused in Rest Phase** — Full-bleed rest color with top progress curtain (`33%` height), dimmed `00:10`, and `"Paused · tap to resume"` hint. | Light & Dark | Tap anywhere resumes the countdown. |
| [`goldens/timer_rounds_strip_round.png`](goldens/timer_rounds_strip_round.png) | **Timer — Rounds Strip (`RoundsStripTimerView`) — Round Phase** — `"ROUND"`, `"2 of 3"`, large `01:12` readout, 3-segment strip (round 1 full, round 2 `20%` filled, round 3 empty), `"02:57 left"`, pause button. | Light & Dark | Tap pauses ([`Rounds Strip — Paused`](goldens/timer_rounds_strip_paused.png)); system back returns to [`Home`](goldens/setup_custom.png). |
| [`goldens/timer_rounds_strip_paused.png`](goldens/timer_rounds_strip_paused.png) | **Timer — Rounds Strip (`RoundsStripTimerView`) — Paused State** — Dimmed `00:45` readout, round 2 segment `50%` filled, `"02:30 left"`, and play/resume button. | Light & Dark | Tap anywhere or press the play button to resume [`Rounds Strip — Round`](goldens/timer_rounds_strip_round.png). |

---

## Known Impractical or Nondeterministic States Excluded

1. **Login loading spinner (`LoginState.isLoading: true`):** Renders an indeterminate `CircularProgressIndicator` while awaiting interactive Google OAuth; it does not settle in golden tests and adds no layout information beyond a centered spinner.
2. **Network account avatar photo (`AccountState.photoUrl != null`):** Uses `NetworkImage` to load a Google profile picture. Excluded per task scope to avoid network access and personal imagery; the deterministic initial fallback (`"A"`) is captured instead.
3. **Live `TimerPage` wall-clock countdown and platform side effects:** `TimerPage` starts a live `Stopwatch`, periodic `Timer`, `AudioManager` cues, background keep-alive, and `WakelockPlus.enable()` on mount. To keep captures 100% deterministic, `ui_snapshots_test.dart` renders the timer `Scaffold` and style view widgets (`RingTimerView`, `FullColorTimerView`, `RoundsStripTimerView`) with fixed `TimerState` values.
4. **Transient error `SnackBar`s (sign-in or sign-out failure):** Ephemeral error notifications triggered by failed auth calls are covered by unit/widget tests rather than static screen-flow snapshots.
