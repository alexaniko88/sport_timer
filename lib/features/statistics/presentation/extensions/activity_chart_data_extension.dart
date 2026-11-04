import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sport_timer/features/statistics/domain/activity_chart_data.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';

extension ActivityChartDataExtension on ActivityChartData {
  List<BarChartGroupData> workBars(ColorScheme colors, DateTime? selected, double maxY) => [
        for (var i = 0; i < buckets.length; i++)
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: buckets[i].workDurationMs / 1000,
                width: AppSpacing.s16,
                color: buckets[i].isFuture
                    ? colors.outlineVariant
                    : buckets[i].start == selected
                        ? colors.primary
                        : colors.secondary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.r8)),
                backDrawRodData:
                    BackgroundBarChartRodData(show: true, toY: maxY, color: colors.surfaceContainerHighest),
              ),
            ],
          ),
      ];
}
