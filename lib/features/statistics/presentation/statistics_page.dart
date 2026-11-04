import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/account/presentation/account_avatar_button.dart';
import 'package:sport_timer/features/account/presentation/account_view_model.dart';
import 'package:sport_timer/features/statistics/domain/activity_period.dart';
import 'package:sport_timer/features/statistics/presentation/extensions/statistics_perspective_extension.dart';
import 'package:sport_timer/features/statistics/presentation/extensions/duration_extension.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_state.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_view_model.dart';
import 'package:sport_timer/features/statistics/presentation/widgets/daily_activity_tile.dart';
import 'package:sport_timer/features/statistics/presentation/widgets/activity_chart.dart';
import 'package:sport_timer/features/statistics/presentation/widgets/activity_consistency_calendar.dart';
import 'package:sport_timer/navigation.dart';
import 'package:sport_timer/shared/presentation/extensions/l10n_context.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';
import 'package:sport_timer/shared/presentation/widgets/app_button.dart';

class StatisticPage extends StatefulWidget {
  final AccountViewModel accountViewModel;
  final VoidCallback onMenuPressed;
  final StatisticsViewModel? viewModel;

  const StatisticPage({super.key, required this.accountViewModel, required this.onMenuPressed, this.viewModel});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  late final StatisticsViewModel _viewModel = widget.viewModel ?? StatisticsViewModel(getIt());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final firstDay = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    _viewModel.setFirstWeekday(firstDay == 0 ? DateTime.sunday : firstDay);
  }

  @override
  void dispose() {
    if (widget.viewModel == null) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading:
            IconButton(tooltip: l10n.homeMenuTooltip, onPressed: widget.onMenuPressed, icon: const Icon(Icons.menu)),
        title: Text(l10n.statisticsTitle),
        actions: [AccountAvatarButton(viewModel: widget.accountViewModel), const SizedBox(width: AppSpacing.s8)],
      ),
      body: ValueListenableBuilder<StatisticsState>(
        valueListenable: _viewModel.state,
        builder: (context, state, _) => LayoutBuilder(
          builder: (context, constraints) {
            final switcher = Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: SegmentedButton<StatisticsView>(
                segments: [
                  ButtonSegment(value: StatisticsView.list, label: Text(l10n.statisticsViewList)),
                  ButtonSegment(value: StatisticsView.charts, label: Text(l10n.statisticsViewCharts)),
                ],
                selected: {state.view},
                onSelectionChanged: (value) => _viewModel.setView(value.first),
              ),
            );
            if (state.view == StatisticsView.charts && constraints.maxHeight < 600) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    switcher,
                    _ChartControls(viewModel: _viewModel, state: state),
                    _content(context, state),
                  ],
                ),
              );
            }
            return Column(
              children: [
                switcher,
                if (state.view == StatisticsView.charts) _ChartControls(viewModel: _viewModel, state: state),
                Expanded(child: _content(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, StatisticsState state) {
    final l10n = context.l10n;
    if (state.status == StatisticsStatus.initial || state.status == StatisticsStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == StatisticsStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.statisticsError),
            const Gap(AppSpacing.s8),
            AppButton.primary(label: l10n.statisticsRetryButton, onPressed: _viewModel.refresh),
          ],
        ),
      );
    }
    if (state.view == StatisticsView.charts) return _chart(context, state);
    if (state.status == StatisticsStatus.empty) return Center(child: Text(l10n.statisticsEmpty));
    return ListView.separated(
      padding:
          EdgeInsets.fromLTRB(AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s16 + MediaQuery.paddingOf(context).bottom),
      itemCount: state.dailyActivity.length,
      itemBuilder: (context, index) => DailyActivityTile(
        activity: state.dailyActivity[index],
        onTap: () => context.push(RoutePath.dayDetails.value, extra: state.dailyActivity[index].localDate),
      ),
      separatorBuilder: (context, index) => const Gap(AppSpacing.s8),
    );
  }

  Widget _chart(BuildContext context, StatisticsState state) {
    final l10n = context.l10n;
    final data = _viewModel.currentChartData;
    if (state.perspective == StatisticsPerspective.consistency) return _consistency(context, state);
    if (!data.hasRecordedActivity) return Center(child: Text(l10n.statisticsChartEmpty));
    final selected = data.buckets.where((bucket) => bucket.start == state.selectedBucket).firstOrNull;
    final locale = Localizations.localeOf(context).toString();
    final label = selected == null
        ? l10n.statisticsPeriodTotal
        : data.period.unit == ActivityPeriodUnit.year
            ? DateFormat.yMMMM(locale).format(selected.start)
            : DateFormat.yMMMMd(locale).format(selected.start);
    final value = state.perspective.value(
      l10n,
      rounds: selected?.roundCount ?? data.roundCount,
      workMs: selected?.workDurationMs ?? data.workDurationMs,
      restMs: selected?.restDurationMs ?? data.restDurationMs,
    );
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s16,
          AppSpacing.s16,
          AppSpacing.s16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              liveRegion: true,
              child: Text('$label: $value', style: Theme.of(context).textTheme.titleMedium),
            ),
            const Gap(AppSpacing.s16),
            if (state.perspective == StatisticsPerspective.workVsRest) ...[
              Text(l10n.statisticsStackLegend),
              const Gap(AppSpacing.s8),
            ],
            ActivityChart(
              data: data,
              selected: state.selectedBucket,
              onSelected: _viewModel.selectBucket,
              maxY: _viewModel.chartMaxY,
              perspective: state.perspective,
            ),
          ],
        ),
      ),
    );
  }

  Widget _consistency(BuildContext context, StatisticsState state) {
    final l10n = context.l10n;
    final data = _viewModel.currentChartData;
    final selected = data.days.where((day) => day.date == state.selectedBucket).firstOrNull;
    final locale = Localizations.localeOf(context).toString();
    final label = selected == null ? l10n.statisticsPeriodTotal : DateFormat.yMMMMd(locale).format(selected.date);
    final value = selected == null
        ? l10n.statisticsActiveDays(data.activeDayCount)
        : selected.isActive
            ? '${l10n.statisticsWorkValue(Duration(milliseconds: selected.workDurationMs).formattedStatisticsDuration(l10n))} · ${l10n.statisticsRounds(selected.roundCount)}'
            : l10n.statisticsNoActivityDay;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s16,
          AppSpacing.s16,
          AppSpacing.s16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(liveRegion: true, child: Text('$label: $value', style: Theme.of(context).textTheme.titleMedium)),
            if (!data.hasRecordedActivity && selected == null) ...[
              const Gap(AppSpacing.s8),
              Text(l10n.statisticsChartEmpty),
            ],
            const Gap(AppSpacing.s16),
            Wrap(
              spacing: AppSpacing.s16,
              children: [
                for (final (icon, label) in [
                  (Icons.check_circle, l10n.statisticsCalendarActive),
                  (Icons.remove, l10n.statisticsCalendarInactive),
                  (Icons.schedule, l10n.statisticsCalendarFuture),
                ])
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Icon(icon, size: 16), const Gap(AppSpacing.s8), Flexible(child: Text(label))],
                  ),
              ],
            ),
            const Gap(AppSpacing.s8),
            ActivityConsistencyCalendar(
              data: data,
              selected: state.selectedBucket,
              onSelected: _viewModel.selectDay,
              onMonthSelected: _viewModel.openMonth,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartControls extends StatelessWidget {
  final StatisticsViewModel viewModel;
  final StatisticsState state;

  const _ChartControls({required this.viewModel, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final period = viewModel.period;
    final locale = Localizations.localeOf(context).toString();
    final label = switch (period.unit) {
      ActivityPeriodUnit.week =>
        '${DateFormat.yMMMd(locale).format(period.start)} – ${DateFormat.yMMMd(locale).format(period.endExclusive.subtract(const Duration(days: 1)))}',
      ActivityPeriodUnit.month => DateFormat.yMMMM(locale).format(period.start),
      ActivityPeriodUnit.year => DateFormat.y(locale).format(period.start),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        children: [
          DropdownButtonFormField<StatisticsPerspective>(
            isExpanded: true,
            initialValue: state.perspective,
            decoration: InputDecoration(labelText: l10n.statisticsPerspective),
            items: [
              for (final perspective in StatisticsPerspective.values)
                DropdownMenuItem(value: perspective, child: Text(perspective.label(l10n))),
            ],
            onChanged: (value) {
              if (value != null) viewModel.setPerspective(value);
            },
          ),
          const Gap(AppSpacing.s8),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              for (final unit in ActivityPeriodUnit.values)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
                  child: ChoiceChip(
                    selected: state.periodUnit == unit,
                    label: Text(
                      switch (unit) {
                        ActivityPeriodUnit.week => l10n.statisticsWeek,
                        ActivityPeriodUnit.month => l10n.statisticsMonth,
                        ActivityPeriodUnit.year => l10n.statisticsYear
                      },
                    ),
                    onSelected: (_) => viewModel.setPeriodUnit(unit),
                  ),
                ),
            ],
          ),
          Row(
            children: [
              IconButton(
                tooltip: l10n.statisticsPreviousPeriod,
                onPressed: viewModel.previousPeriod,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(child: Text(label, textAlign: TextAlign.center)),
              IconButton(
                tooltip: l10n.statisticsNextPeriod,
                onPressed: viewModel.canNavigateNext ? viewModel.nextPeriod : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
