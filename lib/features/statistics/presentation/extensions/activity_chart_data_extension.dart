import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_timer/features/statistics/domain/activity_chart_data.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_state.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';

extension ActivityChartDataExtension on ActivityChartData {
  List<BarChartGroupData> bars(
    ColorScheme colors,
    DateTime? selected,
    double maxY,
    StatisticsPerspective perspective,
  ) =>
      [
        for (var i = 0; i < buckets.length; i++)
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: switch (perspective) {
                  StatisticsPerspective.workTime => buckets[i].workDurationMs / 1000,
                  StatisticsPerspective.rounds => buckets[i].roundCount.toDouble(),
                  StatisticsPerspective.workVsRest ||
                  StatisticsPerspective.totalTime =>
                    buckets[i].totalDurationMs / 1000,
                },
                width: AppSpacing.s16,
                color: buckets[i].isFuture
                    ? colors.outlineVariant
                    : buckets[i].start == selected
                        ? colors.primary
                        : colors.secondary,
                rodStackItems: perspective == StatisticsPerspective.workVsRest
                    ? [
                        BarChartRodStackItem(
                          0,
                          buckets[i].workDurationMs / 1000,
                          buckets[i].start == selected ? colors.primary : colors.secondary,
                        ),
                        BarChartRodStackItem(
                          buckets[i].workDurationMs / 1000,
                          buckets[i].totalDurationMs / 1000,
                          colors.surface,
                          borderSide: buckets[i].restDurationMs == 0
                              ? BorderSide.none
                              : BorderSide(color: colors.secondary, width: AppBorderWidth.thick),
                        ),
                      ]
                    : [],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.r8)),
                backDrawRodData:
                    BackgroundBarChartRodData(show: true, toY: maxY, color: colors.surfaceContainerHighest),
              ),
            ],
          ),
      ];
}
