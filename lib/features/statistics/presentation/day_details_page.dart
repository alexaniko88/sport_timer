import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/statistics/presentation/day_details_state.dart';
import 'package:sport_timer/features/statistics/presentation/day_details_view_model.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_state.dart';
import 'package:sport_timer/features/statistics/presentation/widgets/activity_values.dart';
import 'package:sport_timer/features/statistics/presentation/widgets/run_activity_summary_tile.dart';
import 'package:sport_timer/shared/presentation/extensions/l10n_context.dart';
import 'package:sport_timer/shared/presentation/extensions/text_theme_extension.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';
import 'package:sport_timer/shared/presentation/widgets/app_button.dart';
import 'package:sport_timer/shared/presentation/widgets/app_surface.dart';

class DayDetailsPage extends StatefulWidget {
  final String localDate;

  const DayDetailsPage({super.key, required this.localDate});

  @override
  State<DayDetailsPage> createState() => _DayDetailsPageState();
}

class _DayDetailsPageState extends State<DayDetailsPage> {
  late final DayDetailsViewModel _viewModel = DayDetailsViewModel(getIt(), widget.localDate);

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final date = DateTime.tryParse(widget.localDate);
    final title = date == null
        ? l10n.dayDetailsTitle
        : DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(date);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ValueListenableBuilder<DayDetailsState>(
        valueListenable: _viewModel.state,
        builder: (context, state, _) => switch (state.status) {
          StatisticsStatus.initial || StatisticsStatus.loading => const Center(child: CircularProgressIndicator()),
          StatisticsStatus.empty => Center(child: Text(l10n.dayDetailsEmpty)),
          StatisticsStatus.error => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.dayDetailsError),
                  const Gap(AppSpacing.s8),
                  AppButton.primary(label: l10n.statisticsRetryButton, onPressed: _viewModel.refresh),
                ],
              ),
            ),
          StatisticsStatus.content => ListView.separated(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.s16,
                AppSpacing.s16,
                AppSpacing.s16,
                AppSpacing.s16 + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: state.runs.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return AppSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.dayDetailsSummary, style: Theme.of(context).textTheme.tileTitle),
                        const Gap(AppSpacing.s8),
                        ActivityValues(activity: state.summary(widget.localDate)),
                      ],
                    ),
                  );
                }
                return RunActivitySummaryTile(run: state.runs[index - 1]);
              },
              separatorBuilder: (context, index) => const Gap(AppSpacing.s8),
            ),
        },
      ),
    );
  }
}
