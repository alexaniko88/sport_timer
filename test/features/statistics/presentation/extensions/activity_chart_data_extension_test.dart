import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/statistics/domain/activity_period.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/domain/extensions/daily_activity_list_extension.dart';
import 'package:sport_timer/features/statistics/presentation/extensions/activity_chart_data_extension.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_state.dart';
import 'package:sport_timer/shared/presentation/theme/sport_theme.dart';

void main() {
  test('maps monthly totals and zero segments to each perspective', () {
    const activity = [
      DailyActivity(localDate: '2026-02-01', roundCount: 2, workDurationMs: 1250, restDurationMs: 500),
      DailyActivity(localDate: '2026-02-02', roundCount: 1, workDurationMs: 750, restDurationMs: 0),
      DailyActivity(localDate: '2026-03-01', roundCount: 0, workDurationMs: 0, restDurationMs: 250),
      DailyActivity(localDate: '2026-04-01', roundCount: 1, workDurationMs: 1000, restDurationMs: 0),
    ];
    final data = activity.chartData(
      period: ActivityPeriod(unit: ActivityPeriodUnit.year, date: DateTime(2026), firstWeekday: 1),
      today: DateTime(2026, 12, 31),
    );
    final colors = SportTheme.light.colorScheme;
    double value(StatisticsPerspective perspective) => data.bars(colors, null, 5, perspective)[1].barRods.single.toY;
    expect(value(StatisticsPerspective.workTime), 2);
    expect(value(StatisticsPerspective.rounds), 3);
    expect(value(StatisticsPerspective.totalTime), 2.5);
    final bars = data.bars(colors, null, 5, StatisticsPerspective.workVsRest);
    final february = bars[1].barRods.single;
    expect(february.toY, 2.5);
    expect(february.rodStackItems[0].fromY, 0);
    expect(february.rodStackItems[0].toY, 2);
    expect(february.rodStackItems[1].fromY, 2);
    expect(february.rodStackItems[1].toY, 2.5);
    expect(bars[0].barRods.single.rodStackItems.every((segment) => segment.fromY == segment.toY), isTrue);
    expect(bars[2].barRods.single.rodStackItems[0].toY, 0);
    expect(bars[2].barRods.single.rodStackItems[1].toY, .25);
    expect(bars[2].barRods.single.rodStackItems[1].borderSide.width, greaterThan(0));
    final workOnly = bars[3].barRods.single;
    expect(workOnly.toY, 1);
    expect(workOnly.rodStackItems[1].borderSide, BorderSide.none);
    expect(bars[0].barRods.single.rodStackItems[1].borderSide, BorderSide.none);
    final transitioning = BarChartRodData.lerp(workOnly, bars[2].barRods.single, .5);
    expect(transitioning.rodStackItems, hasLength(2));
    expect(transitioning.rodStackItems[1].toY, greaterThan(transitioning.rodStackItems[1].fromY));
  });
}
