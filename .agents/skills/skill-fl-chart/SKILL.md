---
name: skill-fl-chart
description: >-
  Build or change a chart in the Sport Timer app with the fl_chart package (bar, line, pie):
  clean look, dark and light theme, tooltips, animation, accessibility, and the project's
  MVVM and theme rules. Use when the user asks for a chart, graph, or visual of statistics
  data, or edits an existing fl_chart widget. Not for the statistics data layer itself.
---

# fl_chart in Sport Timer

Package: `fl_chart` (MIT, pure Flutter, works on Android, iOS and macOS). It was at 1.3.0 when this skill was written. Pin the exact version in `pubspec.yaml` with no `^`, and read the changelog before bumping it.

Before writing chart code, read `lib/shared/presentation/theme/` and one existing widget in `lib/features/statistics/presentation/widgets/` and copy their style.

## Where the code goes

- A chart is a **presentation widget**: `features/<name>/presentation/widgets/<thing>_chart.dart`. `fl_chart` is only imported in presentation.
- The widget is a `StatelessWidget` that gets plain data through its constructor (a list of the domain or state model). It never calls a repository and never creates a ViewModel.
- Turning domain data into chart data (`BarChartGroupData`, `FlSpot`) is a helper that works on one type, so it is an **extension** in `presentation/extensions/`, one per file, for example `daily_activity_bars_extension.dart`. Never a top-level function.
- Any calculation that is not drawing (totals, averages, "last 7 days", max Y) belongs in the ViewModel or state, not in `build`. Keep the widget simple.
- The page handles `loading`, `empty` and `error`. The chart widget only draws `content`. Never draw an empty axis for empty data.

## Look and feel (the part that makes it nice)

1. **Less ink.** Remove the border (`borderData: FlBorderData(show: false)`), use only soft horizontal grid lines (`drawVerticalLine: false`), and hide the top and right titles.
2. **Rounded bars.** Give each rod a `borderRadius` on the top corners only, a `width` of 12 to 20, and a `backDrawRodData` track in a very light surface tone so empty days still show.
3. **Colors from the theme only.** Read `Theme.of(context).colorScheme` and `context.timerColors`. Never `Colors.*` and never `AppPalette` in a widget (the palette comment says widgets go through the theme). If a new color is needed, add it to the theme first, in light and dark.
4. **One accent color.** Highlight the selected or touched bar with the accent, and keep the others in a muted tone. Do not use a rainbow.
5. **Readable axes.** Left titles: few values (3 to 5), set `interval` on purpose, use `reservedSize` that fits the longest label. Bottom titles: short labels (weekday letters or day numbers). Use `AppTextStyles` or `textTheme` sizes, not raw numbers.
6. **Zero baseline for bars.** Start bar charts at `minY: 0`. Set `maxY` a little above the top value so the tallest bar does not touch the top. Never cut the axis to make small differences look large.
7. **Tooltip.** Use `getTooltipColor` (not the removed `tooltipBgColor`) with a surface color, `tooltipBorderRadius` with `AppRadius`, and `fitInsideHorizontally: true` and `fitInsideVertically: true` so it never leaves the screen. Show a formatted value (`asMinutesAndSeconds`), not a raw double.
8. **Animation.** The chart animates by itself when data changes. Set `duration` (about 250 to 400 ms) and `curve: Curves.easeOutCubic`. Use `duration` and `curve`, not the old `swapAnimationDuration` and `swapAnimationCurve`.
9. **Line charts.** `isCurved: true` with `preventCurveOverShooting: true`, a gradient `belowBarData` that fades to transparent, `dotData: const FlDotData(show: false)` except for the touched spot.
10. **Size.** Give the chart a fixed height or an `AspectRatio` (about 1.6 to 2). Never put it in an unbounded parent (`Column` without `Expanded` or a `SizedBox`). Pad with `AppSpacing` and `Gap`.

## Theme, language and accessibility

- Check both light and dark: gridlines, labels and tooltip must keep contrast on both.
- All visible text (axis names, tooltip text, empty message) comes from `context.l10n`. Add keys to both ARB files. Format dates and numbers with the locale, not by hand.
- Wrap the chart in `Semantics` with a short text summary (for example "Minutes trained in the last 7 days, most on Tuesday"). Charts are not readable by a screen reader by default.
- Touch targets: keep bars wide enough to tap (`touchExtraThreshold` helps).

## Version notes (API traps)

- Removed or renamed: `tooltipBgColor` (use `getTooltipColor`), `tooltipRoundedRadius` (use `tooltipBorderRadius`), `swapAnimationDuration` and `swapAnimationCurve` (use `duration` and `curve`).
- `SideTitleWidget` takes a `meta` (`TitleMeta`) argument, not `axisSide`.
- `duration` and `curve` are on the `BarChart` / `LineChart` widget, not on the data class.
- `BarChart` is not `const`.
- `BarChartRodStackItem.borderSide` is a named argument.
- A line's `color` and `gradient` cannot both be set.
- Minimum Flutter is 3.27.4. This repo's `.fvmrc` is above that.

## Basic bar chart pattern

```dart
BarChart(
  BarChartData(
    minY: 0,
    maxY: maxY,
    borderData: FlBorderData(show: false),
    gridData: FlGridData(
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (value) => FlLine(
        color: colors.outlineVariant,
        strokeWidth: 1,
      ),
    ),
    titlesData: FlTitlesData(
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: interval,
          getTitlesWidget: (value, meta) => SideTitleWidget(
            meta: meta,
            child: Text(value.asMinutesAndSeconds, style: labelStyle),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) => SideTitleWidget(
            meta: meta,
            child: Text(dayLabel(value.toInt()), style: labelStyle),
          ),
        ),
      ),
    ),
    barTouchData: BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (group) => colors.inverseSurface,
        tooltipBorderRadius: BorderRadius.circular(AppRadius.r8),
        fitInsideHorizontally: true,
        fitInsideVertically: true,
      ),
    ),
    barGroups: groups,
  ),
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeOutCubic,
)
```

Treat it as a pattern to adapt. Check names against the installed version (`fvm dart pub deps`, then the package source in the pub cache) before using a property you are not sure about.

## Checks before hand-off

- `fvm flutter analyze` is clean.
- Test the extension that maps data to chart data (pure logic, no widget tree). Do not write golden tests of the chart drawing itself.
- If a screen captured in `test/snapshots/` changed, refresh it with `fvm flutter test --update-goldens test/snapshots/ui_snapshots_test.dart` and update `test/snapshots/README.md`.
- Run the app and look at the chart in light and dark, with 1 item, many items and zero values.
