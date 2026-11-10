---
id: UI-05-01
status: ready
type: feat
complexity: 9
depends-on: [IMP-05]
touches:
  - lib/features/statistics/**
  - lib/navigation.dart
  - lib/l10n/**
  - test/features/statistics/**
  - test/snapshots/ui_snapshots_test.dart
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

Redesign the daily cards on the Statistics `List` tab so each day is easy to read at a glance (total time, a colored rounds · work · rest line, and a work/rest bar), and show the day's sessions inside the same card when the user expands it. This replaces the separate `/day-details` page, which is removed.

## Context

- Story: [Rethink statistics cards and day details](../index.md). Epic: [UI refactor](../../../index.md).
- Depends on [IMP-05](../../../../improvements/task-05-add-shared-app-tag/index.md), which adds `AppTag` (`lib/shared/presentation/widgets/app_tag.dart`) and the `TemplateIcon` extension (`TemplateId.icon`, `lib/features/templates/presentation/extensions/template_icon_extension.dart`). Use both; do not create copies.
- Current code (statistics feature, presentation layer unless noted):
  - `statistics_page.dart`: `StatisticPage` (`_content`) builds a `ListView.separated` of `DailyActivityTile`, gap `AppSpacing.s8`, and on tap does `context.push(RoutePath.dayDetails.value, extra: localDate)`.
  - `widgets/daily_activity_tile.dart`: `AppSurface` with the date (`tileTitle`) and `ActivityValues` (four text lines: rounds, `Work: …`, `Rest: …`, `Total: …`). Semantics label `l10n.statisticsTileSemantics(date, rounds, work, rest, total)`.
  - `day_details_page.dart`, `day_details_view_model.dart`, `day_details_state.dart`: the page that loads `ActivityRepository.readDayActivity(localDate)` and shows a "Daily total" card plus one `RunActivitySummaryTile` per run (`widgets/run_activity_summary_tile.dart`, which shows "Activity on this day" and "Original configuration").
  - `widgets/activity_values.dart`: only used by the tile, the day details page and the run tile.
  - `statistics_view_model.dart` / `statistics_state.dart`: `StatisticsViewModel` listens to `_repository.changes` (clears the chart selection and calls `refresh()`), keeps a `_generation` counter and a `_disposed` flag. `StatisticsState` has `==` and `hashCode`.
  - `extensions/duration_extension.dart`: `StatisticsDurationExtension.formattedStatisticsDuration(l10n)` gives full words (`26 minutes`), used for semantics and charts.
  - Domain: `RunActivitySummary` (`session: TimerSession`, `activity: DailyActivity`). `TimerSession` has `preparationDurationMs`, `workDurationMs`, `restDurationMs`, `roundCount` (the configuration the run started with). `DailyActivity` has `roundCount`, `workDurationMs`, `restDurationMs`, `totalDurationMs` (what was completed on that day).
  - `lib/navigation.dart`: `RoutePath.dayDetails('/day-details')` and its `GoRoute`.
- Templates: `builtInTemplates` (`lib/features/templates/domain/built_in_templates.dart`) holds `WorkoutTemplate(id, settings: TimerSettings(preparationTime, roundTime, restTime, rounds))`. Names come from `l10n.templateName(id)` (`lib/features/templates/presentation/extensions/template_names_extension.dart`); Custom uses `Icons.tune` and `l10n.templateCustomName`.
- Theme: `AppSurface` (`lib/shared/presentation/widgets/app_surface.dart`), `context.timerColors` (`round` = work color, `rest`, `roundsCount`), `AppTextThemeExtension` (`tileTitle`, `tileSecondary`), `AppSpacing`, `AppRadius`. `TemplateTile`'s `_PhaseBar` (`lib/features/templates/presentation/widgets/template_tile.dart`) is the model for the 6 px rounded bar.
- Goldens today: [statistics.png](../../../../../../test/snapshots/goldens/statistics.png), [day_details.png](../../../../../../test/snapshots/goldens/day_details.png), [day_details_empty.png](../../../../../../test/snapshots/goldens/day_details_empty.png), [day_details_error.png](../../../../../../test/snapshots/goldens/day_details_error.png), built in `test/snapshots/ui_snapshots_test.dart` and listed in [test/snapshots/README.md](../../../../../../test/snapshots/README.md).
- Tests today: `test/features/statistics/presentation/statistics_page_test.dart` (its own `_FakeActivityRepository` with `Completer` reads), `statistics_view_model_test.dart`, `day_details_page_test.dart`, `day_details_view_model_test.dart`, and the shared `test/features/statistics/fake_activity_repository.dart`.

## Behavior

### Compact durations

Add `String get compactStatisticsDuration` to `StatisticsDurationExtension` (same file). It drops milliseconds, then joins the non-zero parts with spaces as `<h>h`, `<m>m`, `<s>s`: `26m`, `3m 35s`, `1h 2m 5s`, `30s`. Zero (or under one second) gives `0s`. The symbols are the same in English and Spanish, so no strings are needed. Visible numbers use this; semantics keep the full `formattedStatisticsDuration(l10n)`.

### Template match (domain)

Add `lib/features/statistics/domain/extensions/timer_session_template_extension.dart` with `extension TimerSessionTemplate on TimerSession { TemplateId? get matchingTemplateId }`. It returns the `id` of the first entry in `builtInTemplates` whose settings equal the session's configuration: `preparationTime == Duration(milliseconds: preparationDurationMs)`, `roundTime == Duration(milliseconds: workDurationMs)`, `restTime == Duration(milliseconds: restDurationMs)`, `rounds == roundCount`. Otherwise `null` (Custom). It imports only domain files (`templates/domain`, `settings/domain`), which the boundary test allows.

### Expand state (view model)

- `StatisticsState` gets three fields, included in `copyWith`, `==` and `hashCode`: `String? expandedDate` (the `localDate` of the open card, `null` when all are closed), `StatisticsStatus dayStatus` (default `StatisticsStatus.initial`), and `List<RunActivitySummary> dayRuns` (default empty, stored unmodifiable like `dailyActivity`). `copyWith` gets `bool clearExpanded = false`, which sets `expandedDate` to `null`, `dayStatus` to `initial` and `dayRuns` to empty.
- `StatisticsViewModel` keeps a private cache `final Map<String, List<RunActivitySummary>> _dayRuns = {};` and a separate `int _dayGeneration = 0;`.
- `void toggleDay(String localDate)`:
  - If `localDate == expandedDate`: collapse (`clearExpanded: true`).
  - Otherwise open this day and close the one before (accordion: at most one open). If `_dayRuns` has the day, set `dayStatus` to `content` (or `empty` for an empty list) with the cached runs at once, with no repository call. If not, set `dayStatus: loading`, `dayRuns: []` and call `_loadDay(localDate)`.
- `Future<void> retryDay()`: when `expandedDate` is not null, set `dayStatus: loading` and call `_loadDay` for it again.
- `_loadDay(localDate)`: takes `final generation = ++_dayGeneration;`, awaits `_repository.readDayActivity(localDate)`, then returns early when `_disposed`, when `generation != _dayGeneration`, or when `expandedDate` is no longer `localDate`. On success it caches the list and sets `dayStatus` to `content` or `empty` with `dayRuns`; on failure it sets `dayStatus: error` and does not cache. Use `fold` (`onSuccess` / `onFailure`), like `DayDetailsViewModel.refresh` does today.
- `refresh()` and the `changes` listener clear `_dayRuns`, increment `_dayGeneration` and collapse (`clearExpanded: true`), because the stored data may have changed. All cards start collapsed when Statistics opens.
- `dispose()` also increments `_dayGeneration`.

### Navigation

Remove `RoutePath.dayDetails`, its `GoRoute` and the `day_details_page.dart` import from `lib/navigation.dart`. Tapping a card no longer navigates.

### Removed code

Delete `day_details_page.dart`, `day_details_view_model.dart`, `day_details_state.dart`, `widgets/run_activity_summary_tile.dart`, `widgets/activity_values.dart` and their tests (`day_details_page_test.dart`, `day_details_view_model_test.dart`); move what those tests covered (loading, empty, error, retry, ignore stale results) into the statistics tests. Remove the ARB keys no longer used anywhere: `dayDetailsTitle`, `dayDetailsSummary`, `dayDetailsActivity`, `dayDetailsConfiguration`, `statisticsTotalValue` (check with a search first; keep a key if something still uses it). Keep `dayDetailsEmpty`, `dayDetailsError`, `statisticsRetryButton`, `statisticsWorkValue`, `statisticsRestValue` and `statisticsTileSemantics`.

### New strings (`lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`, then `fvm flutter gen-l10n`)

- `statisticsRoundsWord`: `{count, plural, =1{round} other{rounds}}` / `{count, plural, =1{ronda} other{rondas}}`. The visible word after the colored number.
- `statisticsSessionSemantics`: `{template}, {rounds}, work {work}, rest {rest}, total {total}` / `{template}, {rounds}, trabajo {work}, descanso {rest}, total {total}`, with all placeholders `String`. `rounds` is `statisticsRounds(count)` and the durations are `formattedStatisticsDuration(l10n)`.

## View spec

Matches the approved mockup. All sizes use existing tokens unless named.

- **Page:** unchanged `StatisticPage` frame (app bar, `List` / `Charts` switch, bottom navigation). The list keeps `ListView.separated` with `AppSpacing.s8` gaps and the same padding. The `Charts` view is unchanged.
- **Daily card (`DailyActivityTile`)**, new constructor: `activity`, `bool isExpanded = false`, `VoidCallback? onTap`, `StatisticsStatus dayStatus = StatisticsStatus.initial`, `List<RunActivitySummary> runs = const []`, `VoidCallback? onRetry`. `StatisticPage` passes `isExpanded: state.expandedDate == activity.localDate`, the `dayStatus`, `dayRuns` and `retryDay` only for that card, and `onTap: () => _viewModel.toggleDay(activity.localDate)`.
  - Outer `AppSurface(padding: EdgeInsets.zero)` with no `onTap`, holding a `Column`:
  - **Header**, the tappable part: `InkWell(borderRadius: BorderRadius.circular(AppRadius.r12), onTap: onTap)` with `Padding(EdgeInsets.all(AppSurface.defaultPadding))`, containing:
    1. Top row: `Expanded` date (`activity.formattedDate(locale)`, `textTheme.tileTitle`, `maxLines: 1`, ellipsis), `Gap(AppSpacing.s8)`, total `compactStatisticsDuration` (`tileTitle`, one line, `softWrap: false`), `Gap(AppSpacing.s8)`, chevron `Icon(Icons.expand_more)` (24 px, `colorScheme.onSurfaceVariant`) inside `AnimatedRotation(turns: isExpanded ? 0.5 : 0, duration: kThemeAnimationDuration)`.
    2. `Gap(AppSpacing.s8)`, then the summary line: `Text.rich` in `textTheme.tileSecondary` with `colorScheme.onSurfaceVariant`, `maxLines: 2`, ellipsis: `<roundCount>` (bold, `timerColors.roundsCount`) + ` ` + `statisticsRoundsWord(roundCount)` + ` · ` + work `compactStatisticsDuration` (bold, `timerColors.round`) + ` · ` + rest `compactStatisticsDuration` (bold, `timerColors.rest`). No `work` / `rest` words. Example: **12** rounds · **20m** · **6m**.
    3. `Gap(AppSpacing.s8)`, then the bar: `ClipRRect` with radius 3 (half its height) around `SizedBox(key: Key('daily-activity-phase-bar'), height: 6)`, a `ColoredBox(color: colorScheme.outlineVariant)` track, and a `Row` of `Expanded` segments `timerColors.round` (flex = `workDurationMs`) and `timerColors.rest` (flex = `restDurationMs`); leave out a segment whose value is 0. Put the height in a private `static const double _phaseBarHeight = 6;`.
  - **Expanded section**, only when `isExpanded`, inside an `AnimatedSize(duration: kThemeAnimationDuration, alignment: Alignment.topCenter)` that wraps the whole body under the header: `Divider(height: 1, thickness: AppBorderWidth.thin, color: colorScheme.outlineVariant)`, then by `dayStatus`:
    - `initial` / `loading`: `Padding(all: AppSpacing.s16)` with a centered `CircularProgressIndicator`.
    - `error`: `Padding(all: AppSpacing.s16)` with a centered `Column`: `Text(l10n.dayDetailsError)`, `Gap(AppSpacing.s8)`, `AppButton.primary(label: l10n.statisticsRetryButton, onPressed: onRetry)`.
    - `empty`: `Padding(all: AppSpacing.s16)` with centered `Text(l10n.dayDetailsEmpty)`.
    - `content`: one flat row per run in repository order, with `Divider(height: 1, thickness: AppBorderWidth.thin, color: colorScheme.outlineVariant)` between rows. No inner `AppSurface`, no border, no fill.
  - A day in the daily list should always have runs. If `readDayActivity` still returns an empty list, show `dayDetailsEmpty` in the open card; the header keeps its totals. This is accepted.
- **Session row**: `Padding(EdgeInsets.all(AppSurface.defaultPadding))`, so it lines up with the header's 12 px keylines. A `Row(crossAxisAlignment: CrossAxisAlignment.center)`:
    - Left, `Expanded` `Column(crossAxisAlignment: start)`: `AppTag` without `onTap` and without `color`, so it is transparent on the card (built-in: `id.icon` + `l10n.templateName(id)`; Custom: `Icons.tune` + `l10n.templateCustomName`), `Gap(AppSpacing.s8)`, then the same colored summary line as the header for `run.activity` (completed on that day), `maxLines: 2`.
    - `Gap(AppSpacing.s8)`, then right: `run.activity.totalDurationMs` as `compactStatisticsDuration` in `tileTitle`, one line, `softWrap: false`. Its right edge sits on the card's 12 px right keyline, the same edge as the header chevron (not under the header total); rows do not reserve the chevron column. This is how the approved mockup lays it out.
    - The template comes from `run.session.matchingTemplateId`. The numbers come from `run.activity`, not from the session configuration (the user removed "original configuration").
- **Themes:** light and dark from `SportTheme`; only theme colors (`colorScheme`, `context.timerColors`), no raw colors.
- **Strings:** English and Spanish. Dates use `DateFormat.yMMMMd(locale)` (as today).
- **Long text:** at 320 × 640 with 1.5x text, in English and Spanish, the date ellipsizes, totals stay whole, the summary wraps to at most 2 lines, the tag ellipsizes, and nothing overflows. A long day such as `37h 2m 12s` fits.
- **Accessibility:**
  - Header: `Semantics(container: true, button: true, expanded: isExpanded, onTap: onTap, label: l10n.statisticsTileSemantics(date, rounds, work, rest, total), excludeSemantics: true)` around the header only, with the `InkWell` set to `excludeFromSemantics: true`. The labels use full words (`formattedStatisticsDuration`), so a screen reader does not depend on color.
  - Session row: `Semantics(container: true, excludeSemantics: true, label: l10n.statisticsSessionSemantics(templateName, statisticsRounds(n), work, rest, total))`, where `templateName` is the tag label.
  - Loading, error text and Retry stay readable and focusable. The header tap area is the full card width and well over 48 dp high.
- **Navigation:** none. The card expands and collapses in place; there is no `/day-details` route.

## Mockup

[mockup.html](mockup.html), approved by the user. It is the visual reference; where its pixel values differ from this View spec or from `AppTag` (IMP-05), the written values win. States: one card expanded with a Strength session and a Custom session, all collapsed, narrow + 1.5x text, session load error, session loading, and empty list; light and dark; English and Spanish.

## Decisions

- **No details page; the card expands in place (like an `ExpansionTile`):** the user does not want a new route for details; a chevron opens and closes the day's sessions inside the card.
- **Accordion, all closed at start:** only one day open at a time, because it looks cleaner and keeps the screen from filling up.
- **Flat rows inside, not cards:** the parent card has an action, the rows do not, so following Material 3 they are list rows with dividers, not nested cards.
- **No "original configuration":** the user found it irrelevant. Each row instead shows which template the run used, as an `AppTag` (from IMP-05) with icon and name, and `Custom` when no template matches, so every row has the same height.
- **Colored numbers without the `work` / `rest` words (option A):** work in the work color, rest in the rest color, rounds number in the rounds color, with the word `rounds` kept. The user picked this for a cleaner line. Screen reader labels keep the full words, so meaning does not depend on color only.
- **Compact durations (`26m`, `3m 35s`):** shown in the mockup and approved; the same symbols in both languages.
- **Work/rest bar on the daily card:** the user liked the color indicator.
- **Trailing items on the card's 12 px right keyline:** the header chevron and each row's total end on the same right edge, as Material 3 list trailing content (as in the approved mockup).

## Out of scope

- The `Charts` view, chart perspectives and the consistency calendar.
- How activity is recorded, stored or summed (`ActivityRepository`, data layer).
- Using `AppTag` elsewhere, or changing `AppTag` itself (IMP-05).
- Expanding more than one day at a time, or remembering the open day after leaving Statistics.

## Files and tests

Created:

- `lib/features/statistics/domain/extensions/timer_session_template_extension.dart`.
- `test/features/statistics/domain/extensions/timer_session_template_extension_test.dart`: every built-in template matches its id; a change in any one of preparation, work, rest or rounds gives `null`.

Changed:

- `lib/features/statistics/presentation/extensions/duration_extension.dart`: add `compactStatisticsDuration`; test it in `test/features/statistics/presentation/extensions/duration_extension_test.dart` (`26m`, `3m 35s`, `1h 2m 5s`, `30s`, `0s`, `37h 2m 12s`, milliseconds dropped).
- `lib/features/statistics/presentation/statistics_state.dart` and `statistics_view_model.dart`: expand state as described. Tests in `test/features/statistics/presentation/statistics_view_model_test.dart` and `statistics_state_test.dart`: toggle opens and loads; a second toggle closes; opening another day closes the first; a cached day does not call the repository again; error then `retryDay` succeeds; a stale result (day closed, other day opened, or disposed) is ignored; `changes` and `refresh` collapse and clear the cache; `==` covers the new fields.
- `lib/features/statistics/presentation/widgets/daily_activity_tile.dart`: new layout.
- `lib/features/statistics/presentation/statistics_page.dart`: pass expand state, no navigation.
- `lib/navigation.dart`: remove the route.
- `lib/l10n/app_en.arb`, `lib/l10n/app_es.arb` and the generated `lib/l10n/app_localizations*.dart`: new and removed keys.
- `test/features/statistics/presentation/statistics_page_test.dart`: extend the repository fake there with `readDayActivity` reads (a `Completer` list, like `reads`). Cover: collapsed card content (date, compact total, colored spans with their colors and bold weight, no `Work`/`Rest` words, the phase bar key with work and rest flex); tap expands with a loader, then rows with the right tag (Strength vs Custom), summary and total; tapping another card collapses the first; tapping again collapses; error + Retry; empty day text; semantics (`expanded` flag, tile label, row label); the header's tap area is at least 48 dp high (`tester.getSize` of the header `InkWell`) and `meetsGuideline(androidTapTargetGuideline)` passes; no overflow at 320 × 640 with 1.5x text in EN and ES, light and dark, collapsed and expanded.
- `test/snapshots/ui_snapshots_test.dart`: remove the three `day_details*` scenarios and the `DayDetailsPage` import; refresh `statistics.png` (all collapsed); add `statistics_expanded.png` in light and dark. Its `whilePerforming` runs `_tapInBothFrames(find.text('Statistics'))` then `_tapInBothFrames(find.text('October 31, 2026'))`, the same way the chart scenarios chain two taps. Change the first fake `RunActivitySummary` session in that file to the Strength settings (`preparationDurationMs: 20000`, `workDurationMs: 90000`, `restDurationMs: 30000`, `roundCount: 8`), keeping its `activity`; the second session stays as it is and shows `Custom`.
- `test/snapshots/README.md`: replace the `day_details*` rows with a `statistics_expanded.png` row, and change the `statistics.png` flow from "Tap a daily card → Day details" to "Tap a daily card → expands it (`statistics_expanded.png`)".

Deleted: the files listed under "Removed code", their two tests, and the goldens `day_details.png`, `day_details_empty.png`, `day_details_error.png`.

## Acceptance

- [ ] When the `List` tab shows a day in light or dark theme, then its `DailyActivityTile` is an `AppSurface` whose header shows the date (`tileTitle`, one line, ellipsis), the compact total (`tileTitle`) and an `Icons.expand_more` chevron; below it a `Text.rich` line with the round count in bold `timerColors.roundsCount`, the localized round word, the compact work time in bold `timerColors.round` and the compact rest time in bold `timerColors.rest`, separated by ` · ` and with no `work` / `rest` words; and a 6 px rounded bar (`Key('daily-activity-phase-bar')`) with work and rest segments weighted by their milliseconds. Check: `test/features/statistics/presentation/statistics_page_test.dart` and `test/snapshots/goldens/statistics.png`.
- [ ] When a duration is shown on a card or row, then it uses `compactStatisticsDuration` (`26m`, `3m 35s`, `1h 2m 5s`, `0s`), the same in English and Spanish. Check: `test/features/statistics/presentation/extensions/duration_extension_test.dart`.
- [ ] When the user taps a closed card, then that day opens, any other open day closes, the chevron turns up, the sessions load with `readDayActivity(localDate)` only if they are not cached, and a loader shows under a 1 px `outlineVariant` divider while loading. Check: `test/features/statistics/presentation/statistics_view_model_test.dart` and `test/features/statistics/presentation/statistics_page_test.dart`.
- [ ] When the user taps the open card's header again, then it closes. Check: `test/features/statistics/presentation/statistics_page_test.dart`.
- [ ] When a day's sessions have loaded, then each session is a flat row (no inner `AppSurface`) separated by 1 px `outlineVariant` dividers, showing an `AppTag` without a tap action (template icon and name when `matchingTemplateId` finds a built-in template, otherwise `Icons.tune` and `Custom` / `Personalizado`), the colored summary of `run.activity` below it, and its compact total on the right on the 12 px keyline. Check: `test/features/statistics/presentation/statistics_page_test.dart`, `test/features/statistics/domain/extensions/timer_session_template_extension_test.dart` and `test/snapshots/goldens/statistics_expanded.png`.
- [ ] When loading a day fails, then the open card shows `dayDetailsError` and a `Retry` button that loads the day again; when the day has no sessions, it shows `dayDetailsEmpty`. Check: `test/features/statistics/presentation/statistics_page_test.dart` and `test/features/statistics/presentation/statistics_view_model_test.dart`.
- [ ] When a day result arrives after the card was closed, another day was opened, or the view model was disposed, then it is ignored; and when the repository emits `changes` or the list refreshes, then all cards close and the cache is cleared. Check: `test/features/statistics/presentation/statistics_view_model_test.dart`.
- [ ] When a screen reader focuses a card header or a session row, then the header is a button with the `expanded` state, the full `statisticsTileSemantics` label and a tap area at least 48 dp high, and each row reads `statisticsSessionSemantics` with the template name and full-word rounds, work, rest and total. Check: `test/features/statistics/presentation/statistics_page_test.dart`.
- [ ] When Statistics is shown at 320 × 640 with 1.5x text in English and Spanish, light and dark, collapsed and expanded, then nothing overflows. Check: `test/features/statistics/presentation/statistics_page_test.dart`.
- [ ] When the app is built, then `RoutePath.dayDetails`, `DayDetailsPage`, `DayDetailsViewModel`, `DayDetailsState`, `ActivityValues`, `RunActivitySummaryTile`, their tests, the unused ARB keys and the `day_details*.png` goldens are gone, and the snapshot test produces `statistics.png` and `statistics_expanded.png`. Check: `fvm flutter test test/snapshots/ui_snapshots_test.dart` and `fvm flutter analyze`.
- [ ] When the full suite and agent check run, then everything passes. Check: `fvm flutter test` and `fvm dart tool/agent_check.dart`.
