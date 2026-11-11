---
id: UI-05-02
status: ready
type: feat
complexity: 7
depends-on: [UI-05-01, IMP-05]
touches:
  - lib/features/statistics/presentation/statistics_page.dart
  - lib/features/statistics/presentation/widgets/daily_activity_tile.dart
  - lib/features/statistics/presentation/day_details_page.dart
  - lib/features/statistics/presentation/day_details_view_model.dart
  - lib/features/statistics/presentation/day_details_state.dart
  - lib/features/statistics/presentation/widgets/run_activity_summary_tile.dart
  - lib/features/statistics/presentation/widgets/activity_values.dart
  - lib/navigation.dart
  - lib/l10n/
  - test/features/statistics/presentation/statistics_page_test.dart
  - test/features/statistics/presentation/day_details_page_test.dart
  - test/features/statistics/presentation/day_details_view_model_test.dart
  - test/snapshots/ui_snapshots_test.dart
  - test/snapshots/README.md
  - test/snapshots/goldens/statistics.png
  - test/snapshots/goldens/statistics_expanded.png
  - test/snapshots/goldens/day_details.png
  - test/snapshots/goldens/day_details_empty.png
  - test/snapshots/goldens/day_details_error.png
skills: []
---

# Rethink statistics cards and details

Story: [Rethink statistics cards and day details](../index.md)

Epic: [UI refactor](../../../index.md)

## Goal

Redesign the daily cards on the Statistics `List` tab so each day reads at a glance (total time, a colored rounds · work · rest line and a work/rest bar), and show the day's sessions inside the same card when the user opens it, using the state from Prepare the statistics card state (UI-05-01). This replaces the separate `/day-details` page, which is removed. Serves R1, R2, R3, R4 and R5 of the story.

## Context

- Statistics presentation today (`lib/features/statistics/presentation/`):
  - `statistics_page.dart`: `StatisticPage` (`_StatisticPageState`, view model field `_viewModel`). Its `_content` builds a `ListView.separated` of `DailyActivityTile` with `Gap(AppSpacing.s8)` separators, and on tap does `context.push(RoutePath.dayDetails.value, extra: localDate)`.
  - `widgets/daily_activity_tile.dart`: `Semantics(label: l10n.statisticsTileSemantics(date, rounds, work, rest, total))` around an `AppSurface(onTap:)` with the date (`tileTitle`) and `ActivityValues` (rounds, `Work: …`, `Rest: …`, `Total: …`).
  - `day_details_page.dart`, `day_details_view_model.dart`, `day_details_state.dart`: the page that loads one day and shows a daily total card and one `RunActivitySummaryTile` (`widgets/run_activity_summary_tile.dart`, "Activity on this day" and "Original configuration") per run.
  - `widgets/activity_values.dart`: used only by the tile, the day details page and the run tile.
  - `extensions/daily_activity_extension.dart`: `formattedDate(locale)` (`DateFormat.yMMMMd`). `extensions/duration_extension.dart`: `formattedStatisticsDuration(l10n)` (full words).
- Domain: `RunActivitySummary` (`session: TimerSession`, `activity: DailyActivity`). `DailyActivity` has `localDate`, `roundCount`, `workDurationMs`, `restDurationMs` and the getter `totalDurationMs`.
- `lib/navigation.dart`: `RoutePath.dayDetails('/day-details')`, its `GoRoute` (builds `DayDetailsPage(localDate: state.extra as String)`) and the `day_details_page.dart` import.
- Templates: names come from `l10n.templateName(id)` (`lib/features/templates/presentation/extensions/template_names_extension.dart`). Strength in `builtInTemplates` is 20 s / 1 m 30 s / 30 s / 8 rounds.
- Theme: `AppSurface` (`lib/shared/presentation/widgets/app_surface.dart`, `AppSurface.defaultPadding` is 12), `context.timerColors` (`round` is the work color, `rest`, `roundsCount`), `AppTextThemeExtension` (`tileTitle`, `tileSecondary`), `AppSpacing`, `AppRadius`, `AppBorderWidth`, `AppButton`. `_PhaseBar` in `lib/features/templates/presentation/widgets/template_tile.dart` is the model for the 6 px rounded bar. The bar is plain widgets, not `fl_chart`; the `Charts` view is not touched.
- ARB keys used only by the files this task deletes (verified with a search): `dayDetailsTitle`, `dayDetailsSummary` (day details page), `dayDetailsActivity`, `dayDetailsConfiguration` (run tile), `statisticsTotalValue` (`ActivityValues`). Still used elsewhere and kept: `dayDetailsEmpty`, `dayDetailsError`, `statisticsRetryButton`, `statisticsWorkValue`, `statisticsRestValue`, `statisticsRounds`, `statisticsTileSemantics`.
- Goldens today: [statistics.png](../../../../../../test/snapshots/goldens/statistics.png), [day_details.png](../../../../../../test/snapshots/goldens/day_details.png), [day_details_empty.png](../../../../../../test/snapshots/goldens/day_details_empty.png), [day_details_error.png](../../../../../../test/snapshots/goldens/day_details_error.png), built in `test/snapshots/ui_snapshots_test.dart` and listed in [test/snapshots/README.md](../../../../../../test/snapshots/README.md). The harness's `_FakeActivityRepository` has two days (`2026-10-31`, `2026-10-30`) and a `dayResult` with two runs; the first (`run-2`) has a non-template configuration today. Scenarios chain taps with `_tapInBothFrames`.
- Tests today: `test/features/statistics/presentation/statistics_page_test.dart` (own `_FakeActivityRepository` with `reads` Completers and a `changesController`), `day_details_page_test.dart` and `day_details_view_model_test.dart`.

## Contract

- `compactStatisticsDuration` on `Duration` (`lib/features/statistics/presentation/extensions/duration_extension.dart`) — provided by UI-05-01: `26m`, `3m 35s`, `1h 2m 5s`, `0s`. Visible numbers use it; semantics keep `formattedStatisticsDuration(l10n)`.
- `matchingTemplateId` on `TimerSession` (`lib/features/statistics/domain/extensions/timer_session_template_extension.dart`) — provided by UI-05-01: `TemplateId?`, `null` means Custom.
- `StatisticsState.expandedDate`, `dayStatus`, `dayRuns` and `StatisticsViewModel.toggleDay(String localDate)` / `retryDay()` (`lib/features/statistics/presentation/`) — provided by UI-05-01: at most one open day, all closed at start, cached loads, stale results ignored, closed again on `changes` and `refresh`.
- `AppTag` in `lib/shared/presentation/widgets/app_tag.dart` — provided by IMP-05: `const AppTag({required IconData icon, required String label, Color? color, VoidCallback? onTap, String? semanticLabel})`. Without `onTap` it is plain, non-interactive text; without `color` it has no fill.
- `TemplateIcon` (`IconData get icon` on `TemplateId`) in `lib/features/templates/presentation/extensions/template_icon_extension.dart` — provided by IMP-05. Custom uses `Icons.tune` and `l10n.templateCustomName`.
- `DailyActivityTile` — new constructor here: `activity`, `bool isExpanded = false`, `VoidCallback? onTap`, `StatisticsStatus dayStatus = StatisticsStatus.initial`, `List<RunActivitySummary> runs = const []`, `VoidCallback? onRetry`. `StatisticPage` passes `isExpanded: state.expandedDate == activity.localDate`, and `dayStatus`, `dayRuns` and `onRetry: _viewModel.retryDay` only to that card, with `onTap: () => _viewModel.toggleDay(activity.localDate)`.
- New ARB keys (`lib/l10n/app_en.arb` with a `description`, `lib/l10n/app_es.arb`, then `fvm flutter gen-l10n`):
  - `statisticsRoundsWord`: `{count, plural, =1{round} other{rounds}}` / `{count, plural, =1{ronda} other{rondas}}`, the visible word after the colored number.
  - `statisticsSessionSemantics`: `{template}, {rounds}, work {work}, rest {rest}, total {total}` / `{template}, {rounds}, trabajo {work}, descanso {rest}, total {total}`, all placeholders `String`. `rounds` is `statisticsRounds(count)`; the durations are `formattedStatisticsDuration(l10n)`.
  - `statisticsDayLoading`: `Loading sessions` / `Cargando sesiones` (with a `description` in `app_en.arb`), the semantics label of the open card's loader.
- Removed here: `RoutePath.dayDetails`, its `GoRoute` and import; `day_details_page.dart`, `day_details_view_model.dart`, `day_details_state.dart`, `widgets/run_activity_summary_tile.dart`, `widgets/activity_values.dart`; their tests `day_details_page_test.dart` and `day_details_view_model_test.dart`; the ARB keys `dayDetailsTitle`, `dayDetailsSummary`, `dayDetailsActivity`, `dayDetailsConfiguration`, `statisticsTotalValue` (search again first; keep a key if something still uses it); the goldens `day_details.png`, `day_details_empty.png`, `day_details_error.png`.

## View spec

Follows the layout of the approved mockup. All sizes use existing tokens unless named.

- **Page:** the `StatisticPage` frame is unchanged (app bar, `List` / `Charts` switch, bottom navigation). The list keeps `ListView.separated` with `AppSpacing.s8` gaps and the same padding. The `Charts` view is unchanged.
- **Daily card (`DailyActivityTile`):** an outer `AppSurface(padding: EdgeInsets.zero)` with no `onTap`, holding a `Column` of the header and the body.
  - **Header**, the tappable part: `InkWell(borderRadius: BorderRadius.circular(AppRadius.r12), onTap: onTap, excludeFromSemantics: true)` with `Padding(EdgeInsets.all(AppSurface.defaultPadding))` around a `Column`: the top row, `Gap(AppSpacing.s12)`, the bar.
    1. Top row: `Row(crossAxisAlignment: CrossAxisAlignment.center)` with:
       - `Expanded` `Column(crossAxisAlignment: start)` with the date (`activity.formattedDate(locale)`, `textTheme.tileTitle`, `maxLines: 1`, ellipsis), no gap (the mockup's 2 px is smaller than the smallest token, `AppSpacing.s8`, so the two lines sit directly under each other, as in the `_DrawerTile` title and secondary text), then the summary line: `Text.rich` in `textTheme.tileSecondary` with `colorScheme.onSurfaceVariant`, `maxLines: 2`, ellipsis: `<roundCount>` (bold, `timerColors.roundsCount`) + ` ` + `statisticsRoundsWord(roundCount)` + ` · ` + work `compactStatisticsDuration` (bold, `timerColors.round`) + ` · ` + rest `compactStatisticsDuration` (bold, `timerColors.rest`). No `work` / `rest` words. Example: **12** rounds · **20m** · **6m**.
       - `Gap(AppSpacing.s8)`, the total as `compactStatisticsDuration` (`tileTitle`, one line, `softWrap: false`), `Gap(AppSpacing.s8)`, and the chevron `Icon(Icons.expand_more)` (24 px, `colorScheme.onSurfaceVariant`) inside `AnimatedRotation(turns: isExpanded ? 0.5 : 0, duration: kThemeAnimationDuration)`. The total and chevron sit on the right of both lines, centered on them.
    2. The bar: `ClipRRect` with radius 3 (half its height) around `SizedBox(key: Key('daily-activity-phase-bar'), height: _phaseBarHeight)` (`static const double _phaseBarHeight = 6;`), a `ColoredBox(color: colorScheme.outlineVariant)` track, and a `Row` of `Expanded` segments `timerColors.round` (flex `workDurationMs`) and `timerColors.rest` (flex `restDurationMs`); leave out a segment whose value is 0.
  - **Body under the header:** an `AnimatedSize(duration: kThemeAnimationDuration, alignment: Alignment.topCenter)` that holds the expanded section only when `isExpanded`: `Padding(EdgeInsets.fromLTRB(AppSpacing.s12, 0, AppSpacing.s12, AppSpacing.s12))` around a `Column` that starts with `Divider(height: 1, thickness: AppBorderWidth.thin, color: colorScheme.outlineVariant)`, so the divider is inset by 12 on both sides. Then by `dayStatus`:
    - `initial` / `loading`: `Padding(EdgeInsets.only(top: AppSpacing.s12))` with a centered `CircularProgressIndicator(semanticsLabel: l10n.statisticsDayLoading)`.
    - `error`: `Padding(EdgeInsets.only(top: AppSpacing.s12))` with a `Row(crossAxisAlignment: CrossAxisAlignment.center)`: `Expanded(Text(l10n.dayDetailsError))` (left-aligned, `tileSecondary`, `onSurfaceVariant`), `Gap(AppSpacing.s8)`, `AppButton.primary(label: l10n.statisticsRetryButton, onPressed: onRetry)`. Text and Retry sit side by side: the text from the left edge, Retry at the right.
    - `empty`: `Padding(EdgeInsets.only(top: AppSpacing.s12))` with centered `Text(l10n.dayDetailsEmpty)`. A day in the list should always have runs; if `readDayActivity` still returns an empty list, this shows and the header keeps its totals (accepted).
    - `content`: one flat row per run in repository order, with the same `Divider` between rows. No inner `AppSurface`, no border, no fill.
- **Session row:** `Padding(EdgeInsets.symmetric(vertical: AppSpacing.s12))`, with no bottom padding on the last row (the body's 12 bottom padding gives it), around a `Row(crossAxisAlignment: CrossAxisAlignment.center)`. The body's 12 side padding puts it on the header's 12 px keylines.
  - Left, `Expanded` `Column(crossAxisAlignment: start)`: `AppTag` without `onTap` and without `color` (built-in: `id.icon` + `l10n.templateName(id)`; Custom: `Icons.tune` + `l10n.templateCustomName`), `Gap(AppSpacing.s8)` (the mockup's 6 px is not a token), then the same colored summary line as the header for `run.activity`, `maxLines: 2`.
  - `Gap(AppSpacing.s8)`, then right: `run.activity.totalDurationMs` as `compactStatisticsDuration` in `tileTitle`, one line, `softWrap: false`. Its right edge sits on the card's 12 px right keyline, the same edge as the header chevron (not under the header total); rows do not reserve the chevron column.
  - The template comes from `run.session.matchingTemplateId`; the numbers come from `run.activity`, not from the session configuration.
- **Themes:** light and dark from `SportTheme`; only theme colors (`colorScheme`, `context.timerColors`).
- **Strings:** English and Spanish. Dates use `DateFormat.yMMMMd(locale)`, as today.
- **Long text:** at 320 × 640 with 1.5x text, in English and Spanish, the date ellipsizes, totals stay whole, the summary wraps to at most 2 lines, the tag ellipsizes, and nothing overflows. A long day such as `37h 2m 12s` fits.
- **Accessibility:**
  - Header: `Semantics(container: true, button: true, expanded: isExpanded, onTap: onTap, label: l10n.statisticsTileSemantics(date, rounds, work, rest, total), excludeSemantics: true)` around the header only. The label uses full words (`formattedStatisticsDuration`), so meaning does not depend on color. The header tap area is the full card width and over 48 dp high.
  - Session row: `Semantics(container: true, excludeSemantics: true, label: l10n.statisticsSessionSemantics(templateName, statisticsRounds(n), work, rest, total))`, where `templateName` is the tag label.
  - The loader reads `statisticsDayLoading` (`Loading sessions` / `Cargando sesiones`). The error text and Retry stay readable and focusable.
- **Navigation:** none. The card opens and closes in place; there is no `/day-details` route.

## Mockup

The story's [mockup.html](../mockup.html), approved by the user. The mockup's layout wins, and the View spec follows it: date and summary stacked on the left with the total and chevron on the right, 12 gaps in the header, the body divider inset by 12, and the error text and Retry side by side. Where a mockup size or text style has no existing token or text role, the written value wins. The known cases: the 2 px gap between date and summary is left out (no gap); the 6 px gap between tag and summary uses `AppSpacing.s8`; the `AppTag` sizes come from IMP-05; the session total uses `tileTitle` (16 px) instead of the mockup's 14 px `.session-total`. States: one card open with a Strength session and a Custom session, all closed, narrow with 1.5x text, session load error, session loading and empty list; light and dark; English and Spanish.

## Decisions

- **No details page; the card opens in place (like an `ExpansionTile`):** the user does not want a route for details; a chevron opens and closes the day's sessions inside the card.
- **Flat rows inside, not cards:** the parent card has an action and the rows do not, so following Material 3 they are list rows with dividers, not nested cards.
- **No "original configuration":** the user found it irrelevant. Each row instead shows which template the run used, as an `AppTag` with icon and name, and `Custom` when no template matches, so every row has the same height.
- **Colored numbers without the `work` / `rest` words (option A):** work in the work color, rest in the rest color, the rounds number in the rounds color, with the word `rounds` kept. Screen reader labels keep the full words.
- **Work/rest bar on the daily card:** the user liked the color indicator.
- **Trailing items on the card's 12 px right keyline:** the header chevron and each row's total end on the same right edge, as Material 3 list trailing content.

## Out of scope

- The state and logic from UI-05-01 (`compactStatisticsDuration`, `matchingTemplateId`, the open-day state and its view model rules).
- The `Charts` view, chart perspectives and the consistency calendar.
- How activity is recorded, stored or summed (`ActivityRepository`, data layer).
- Using `AppTag` elsewhere, or changing `AppTag` itself (IMP-05).
- Opening more than one day at a time, or remembering the open day after leaving Statistics.

## Files and tests

- New: the golden `test/snapshots/goldens/statistics_expanded.png`.
- Deleted: the files, tests, ARB keys and goldens listed under "Removed here" in Contract. Their coverage (loading, empty, error, retry, stale results) is in UI-05-01's view model tests and the page tests below.
- Widget tests: `test/features/statistics/presentation/statistics_page_test.dart`. Give its `_FakeActivityRepository` a `readDayActivity` that records each requested `localDate` and returns a `Completer` future the test completes, like `reads`. Widget tests are needed here for the tap, expand, semantics, tap-size and overflow checks, which goldens cannot see. Existing tests in this file that assert removed texts and must be updated (no other test there asserts removed texts or the day details page; the chart and calendar texts such as `Period total: Work: …` stay as they are):
  - Updated: `loads daily tiles and clears old content while refreshing`. Keep the test and its refresh steps. For the fixture `first` (2 rounds, work 125000 ms, rest 30000 ms), replace the four assertions `'2 rounds'`, `'Work: 2 minutes 5 seconds'`, `'Rest: 30 seconds'` and `'Total: 2 minutes 35 seconds'` with `find.text('2m 35s')` (header total) and `find.text('2 rounds · 2m 5s · 30s')` (the `Text.rich` summary line), each `findsOneWidget`.
  - Updated: `tile exposes all fields and fits large text`. Keep its setup, the full `bySemanticsLabel` check and the date check. For `longActivity` (123 rounds, work 34 h 17 m 36 s, rest 2 h 44 m 36 s), replace `'Work: 34 hours 17 minutes 36 seconds'` and `'Total: 37 hours 2 minutes 12 seconds'` with `find.text('37h 2m 12s')` and `find.text('123 rounds · 34h 17m 36s · 2h 44m 36s')`.
- Snapshot harness `test/snapshots/ui_snapshots_test.dart`: remove the three `day_details*` scenarios and the `DayDetailsPage` import; refresh `statistics.png` (all closed); add `statistics_expanded.png` in light and dark, whose `whilePerforming` runs `_tapInBothFrames(find.text('Statistics'))` then `_tapInBothFrames(find.text('October 31, 2026'))`, as the chart scenarios chain two taps. In `_FakeActivityRepository.dayResult`, change the first session (`run-2`) to the Strength settings (`preparationDurationMs: 20000`, `workDurationMs: 90000`, `restDurationMs: 30000`, `roundCount: 8`), keeping its `activity`; the second (`run-1`) stays and shows `Custom`.
- `test/snapshots/README.md`: replace the three `day_details*` rows with one `statistics_expanded.png` row, and change the `statistics.png` flow from "Tap a daily card → Day details" to "Tap a daily card → opens it in place (`statistics_expanded.png`)".

## Acceptance

- [ ] When the `List` tab shows a day, then its card shows the date (`tileTitle`, one line, ellipsis), the compact total and an `Icons.expand_more` chevron, and a `Text.rich` line with the round count in bold `timerColors.roundsCount`, the round word, the compact work in bold `timerColors.round` and the compact rest in bold `timerColors.rest`, joined by ` · `, with no `Work` / `Rest` words. Check: `test/features/statistics/presentation/statistics_page_test.dart` "daily card shows the date, compact total and colored summary".
- [ ] When daily activity loads and later refreshes, then the first card shows `2m 35s` and `2 rounds · 2m 5s · 30s`, and old content is cleared while the list reloads. Check: `test/features/statistics/presentation/statistics_page_test.dart` "loads daily tiles and clears old content while refreshing".
- [ ] When a very long day is shown at text scale 2 on a 320 px wide screen, then the card shows `37h 2m 12s` and `123 rounds · 34h 17m 36s · 2h 44m 36s`, keeps its full-word semantics label, and nothing overflows. Check: `test/features/statistics/presentation/statistics_page_test.dart` "tile exposes all fields and fits large text".
- [ ] When the card shows its bar, then `Key('daily-activity-phase-bar')` is 6 px high with work and rest segments weighted by their milliseconds, and a zero segment is left out. Check: `test/features/statistics/presentation/statistics_page_test.dart` "daily card bar weights work and rest".
- [ ] When the user taps a closed card, then Statistics stays on screen (no route), the chevron turns up, and a loader shows under a 1 px `outlineVariant` divider until the sessions arrive. Check: `test/features/statistics/presentation/statistics_page_test.dart` "tapping a card opens it in place with a loader".
- [ ] When an open day is loading, then its loader has the semantics label `Loading sessions` in English and `Cargando sesiones` in Spanish. Check: `test/features/statistics/presentation/statistics_page_test.dart` "loading day reads its loader label".
- [ ] When a day's sessions have loaded, then each session is a flat row (no inner `AppSurface`) between 1 px `outlineVariant` dividers, with an `AppTag` that has no tap action (Strength icon and name for the Strength run, `Icons.tune` and `Custom` for the other), the colored summary of `run.activity` and its compact total on the right. Check: `test/features/statistics/presentation/statistics_page_test.dart` "open card lists each session with its template tag".
- [ ] When the user taps another card while one is open, then the first one closes. Check: `test/features/statistics/presentation/statistics_page_test.dart` "tapping another card closes the open one".
- [ ] When the user taps the open card's header again, then it closes. Check: `test/features/statistics/presentation/statistics_page_test.dart` "tapping the open card closes it".
- [ ] When loading a day fails, then the open card shows `dayDetailsError` and a `Retry` button side by side in one row (the text left of the button), and Retry loads the day again. Check: `test/features/statistics/presentation/statistics_page_test.dart` "a failed day shows the error and Retry loads it again".
- [ ] When a day has no sessions, then the open card shows `dayDetailsEmpty` and the header keeps its totals. Check: `test/features/statistics/presentation/statistics_page_test.dart` "a day with no sessions shows the empty text".
- [ ] When a screen reader focuses a card header, then it is one button node with the `expanded` state and the full `statisticsTileSemantics` label. Check: `test/features/statistics/presentation/statistics_page_test.dart` "card header is a button with its expanded state and full label".
- [ ] When the card header is measured, then its tap area is at least 48 dp high (`tester.getSize` of the header `InkWell`) and `meetsGuideline(androidTapTargetGuideline)` passes. Check: `test/features/statistics/presentation/statistics_page_test.dart` "card header meets the tap target guideline".
- [ ] When a screen reader focuses a session row, then it reads `statisticsSessionSemantics` with the template name and full-word rounds, work, rest and total. Check: `test/features/statistics/presentation/statistics_page_test.dart` "session row reads its template and full values".
- [ ] When Statistics shows at 320 × 640 with 1.5x text in English and Spanish, light and dark, with all cards closed and with one open, then nothing overflows. Check: `test/features/statistics/presentation/statistics_page_test.dart` "cards fit 320 x 640 at text scale 1.5 in $locale, dark: $dark".
- [ ] When the Statistics tab is captured, then every card is closed and shows the new header, summary line and bar. Check: `test/snapshots/goldens/statistics.png`.
- [ ] When the 31 October card is opened in the snapshot, then it shows a Strength row and a Custom row under the header. Check: `test/snapshots/goldens/statistics_expanded.png`.
- [ ] When the change is checked, then format, analyze, the mirrored tests, the boundary test, `gen-l10n` and the snapshots pass, with the day details code, route and unused ARB keys removed. Check: `fvm dart tool/agent_check.dart --skip-build`.
