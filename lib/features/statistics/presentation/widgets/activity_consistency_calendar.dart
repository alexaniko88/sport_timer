import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:sport_timer/features/statistics/domain/activity_chart_data.dart';
import 'package:sport_timer/features/statistics/domain/activity_period.dart';
import 'package:sport_timer/features/statistics/presentation/extensions/duration_extension.dart';
import 'package:sport_timer/shared/presentation/extensions/l10n_context.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';

class ActivityConsistencyCalendar extends StatefulWidget {
  final ActivityChartData data;
  final DateTime? selected;
  final ValueChanged<ActivityChartDay> onSelected;
  final ValueChanged<DateTime> onMonthSelected;

  const ActivityConsistencyCalendar({
    super.key,
    required this.data,
    required this.selected,
    required this.onSelected,
    required this.onMonthSelected,
  });

  @override
  State<ActivityConsistencyCalendar> createState() => _ActivityConsistencyCalendarState();
}

class _ActivityConsistencyCalendarState extends State<ActivityConsistencyCalendar> {
  final _selectedDetailKey = GlobalKey();

  @override
  void didUpdateWidget(covariant ActivityConsistencyCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.period.unit == ActivityPeriodUnit.year &&
        widget.selected != null &&
        oldWidget.selected != widget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final detail = _selectedDetailKey.currentContext;
        if (mounted && detail != null) Scrollable.ensureVisible(detail, duration: const Duration(milliseconds: 200));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final months = widget.data.period.unit == ActivityPeriodUnit.year
        ? widget.data.buckets.map((bucket) => bucket.days).toList()
        : [widget.data.days];
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: math.max(336, constraints.maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final days in months) ...[
                if (widget.data.period.unit == ActivityPeriodUnit.year) _monthHeading(context, days),
                _days(context, days),
                if (widget.data.period.unit == ActivityPeriodUnit.year) const Gap(AppSpacing.s16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _monthHeading(BuildContext context, List<ActivityChartDay> days) {
    final month = days.first.date;
    final label = DateFormat.yMMMM(Localizations.localeOf(context).toString()).format(month);
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: days.every((day) => day.isFuture) ? null : () => widget.onMonthSelected(month),
        child: Text(label, semanticsLabel: context.l10n.statisticsOpenMonth(label)),
      ),
    );
  }

  Widget _days(BuildContext context, List<ActivityChartDay> days) {
    final localizations = MaterialLocalizations.of(context);
    final first = localizations.firstDayOfWeekIndex;
    final offset = widget.data.period.unit == ActivityPeriodUnit.week
        ? 0
        : (days.first.date.weekday % DateTime.daysPerWeek - first) % DateTime.daysPerWeek;
    final rows = (offset + days.length + 6) ~/ 7;
    return Column(
      children: [
        Row(
          children: [
            for (var index = 0; index < 7; index++)
              Expanded(child: Center(child: Text(localizations.narrowWeekdays[(first + index) % 7]))),
          ],
        ),
        for (var row = 0; row < rows; row++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(
                  child: row * 7 + column - offset >= 0 && row * 7 + column - offset < days.length
                      ? _day(context, days[row * 7 + column - offset])
                      : const SizedBox(height: 48),
                ),
            ],
          ),
          if (widget.data.period.unit == ActivityPeriodUnit.year)
            for (var column = 0; column < 7; column++)
              if (row * 7 + column - offset >= 0 &&
                  row * 7 + column - offset < days.length &&
                  days[row * 7 + column - offset].date == widget.selected)
                _selectedDetail(context, days[row * 7 + column - offset]),
        ],
      ],
    );
  }

  Widget _selectedDetail(BuildContext context, ActivityChartDay day) {
    final l10n = context.l10n;
    final date = DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(day.date);
    final value = day.isActive
        ? '${l10n.statisticsWorkValue(Duration(milliseconds: day.workDurationMs).formattedStatisticsDuration(l10n))} · ${l10n.statisticsRounds(day.roundCount)}'
        : l10n.statisticsNoActivityDay;
    return Align(
      key: _selectedDetailKey,
      alignment: Alignment.centerLeft,
      child: Text('$date: $value', style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _day(BuildContext context, ActivityChartDay day) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final date = DateFormat.yMMMMEEEEd(Localizations.localeOf(context).toString()).format(day.date);
    final status = day.isFuture
        ? l10n.statisticsCalendarFuture
        : day.isActive
            ? l10n.statisticsCalendarActive
            : l10n.statisticsCalendarInactive;
    final value = day.isActive
        ? '${l10n.statisticsWorkValue(Duration(milliseconds: day.workDurationMs).formattedStatisticsDuration(l10n))} · ${l10n.statisticsRounds(day.roundCount)}'
        : '';
    return Semantics(
      label: l10n.statisticsCalendarDayValue(date, status, value),
      selected: widget.selected == day.date,
      button: true,
      enabled: !day.isFuture,
      onTap: day.isFuture ? null : () => widget.onSelected(day),
      child: ExcludeSemantics(
        child: TextButton(
          onPressed: day.isFuture ? null : () => widget.onSelected(day),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: widget.selected == day.date ? colors.secondaryContainer : null,
            foregroundColor: day.isActive ? colors.primary : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${day.date.day}'),
              Icon(
                day.isFuture
                    ? Icons.schedule
                    : day.isActive
                        ? Icons.check_circle
                        : Icons.remove,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
