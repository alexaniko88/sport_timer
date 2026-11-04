import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sport_timer/features/statistics/domain/activity_chart_data.dart';
import 'package:sport_timer/features/statistics/domain/activity_period.dart';
import 'package:sport_timer/features/statistics/presentation/extensions/activity_chart_data_extension.dart';
import 'package:sport_timer/features/statistics/presentation/extensions/duration_extension.dart';
import 'package:sport_timer/features/statistics/presentation/extensions/statistics_perspective_extension.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_state.dart';
import 'package:sport_timer/shared/presentation/extensions/l10n_context.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';

class ActivityChart extends StatelessWidget {
  final ActivityChartData data;
  final DateTime? selected;
  final ValueChanged<ActivityChartBucket> onSelected;
  final double maxY;
  final StatisticsPerspective perspective;

  const ActivityChart({
    super.key,
    required this.data,
    required this.selected,
    required this.onSelected,
    required this.maxY,
    required this.perspective,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final monthly = data.period.unit == ActivityPeriodUnit.year;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: math.max(MediaQuery.sizeOf(context).width - AppSpacing.s32, data.buckets.length * 48.0),
        height: 240,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.statisticsChartScale(
                  perspective == StatisticsPerspective.rounds
                      ? l10n.statisticsRounds(maxY.toInt())
                      : Duration(seconds: maxY.toInt()).formattedStatisticsDuration(l10n),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: BarChart(
                        BarChartData(
                          minY: 0,
                          maxY: maxY,
                          alignment: BarChartAlignment.spaceAround,
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            drawVerticalLine: false,
                            horizontalInterval: maxY / 4,
                            getDrawingHorizontalLine: (_) =>
                                FlLine(color: colors.outlineVariant, strokeWidth: AppBorderWidth.thin),
                          ),
                          titlesData: const FlTitlesData(show: false),
                          barTouchData: const BarTouchData(enabled: false),
                          barGroups: data.bars(colors, selected, maxY, perspective),
                        ),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      children: [
                        for (final bucket in data.buckets)
                          Expanded(
                            child: Semantics(
                              button: true,
                              enabled: !bucket.isFuture,
                              selected: bucket.start == selected,
                              onTap: bucket.isFuture ? null : () => onSelected(bucket),
                              label: l10n.statisticsChartBucket(
                                monthly
                                    ? DateFormat.yMMMM(locale).format(bucket.start)
                                    : DateFormat.yMMMMd(locale).format(bucket.start),
                                bucket.isFuture
                                    ? l10n.statisticsFuture
                                    : perspective.value(
                                        l10n,
                                        rounds: bucket.roundCount,
                                        workMs: bucket.workDurationMs,
                                        restMs: bucket.restDurationMs,
                                      ),
                              ),
                              child: ExcludeSemantics(
                                child: TextButton(
                                  onPressed: bucket.isFuture ? null : () => onSelected(bucket),
                                  style:
                                      TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(48, 48)),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: bucket.start == selected
                                        ? Icon(Icons.arrow_drop_down, color: colors.primary)
                                        : bucket.isFuture
                                            ? Icon(Icons.schedule, color: colors.outline)
                                            : const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                for (final bucket in data.buckets)
                  Expanded(
                    child: Center(
                      child: Text(
                        monthly
                            ? DateFormat.MMM(locale).format(bucket.start)
                            : DateFormat.d(locale).format(bucket.start),
                        style: Theme.of(context).textTheme.labelSmall,
                        maxLines: 1,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
