import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sport_timer/features/statistics/domain/run_activity_summary.dart';
import 'package:sport_timer/features/statistics/presentation/extensions/duration_extension.dart';
import 'package:sport_timer/features/statistics/presentation/widgets/activity_values.dart';
import 'package:sport_timer/shared/presentation/extensions/l10n_context.dart';
import 'package:sport_timer/shared/presentation/extensions/text_theme_extension.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';
import 'package:sport_timer/shared/presentation/widgets/app_surface.dart';

class RunActivitySummaryTile extends StatelessWidget {
  final RunActivitySummary run;

  const RunActivitySummaryTile({super.key, required this.run});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final style = theme.textTheme.tileSecondary.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final session = run.session;
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dayDetailsActivity, style: theme.textTheme.tileTitle),
          const Gap(AppSpacing.s8),
          ActivityValues(activity: run.activity),
          const Gap(AppSpacing.s12),
          Text(l10n.dayDetailsConfiguration, style: theme.textTheme.tileTitle),
          const Gap(AppSpacing.s8),
          Text(
            l10n.statisticsRounds(session.roundCount),
            style: style,
          ),
          Text(
            l10n.statisticsWorkValue(
              Duration(milliseconds: session.workDurationMs).formattedStatisticsDuration(l10n),
            ),
            style: style,
          ),
          Text(
            l10n.statisticsRestValue(
              Duration(milliseconds: session.restDurationMs).formattedStatisticsDuration(l10n),
            ),
            style: style,
          ),
        ],
      ),
    );
  }
}
