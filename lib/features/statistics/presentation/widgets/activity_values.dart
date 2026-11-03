import 'package:flutter/material.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/presentation/extensions/duration_extension.dart';
import 'package:sport_timer/shared/presentation/extensions/l10n_context.dart';
import 'package:sport_timer/shared/presentation/extensions/text_theme_extension.dart';

class ActivityValues extends StatelessWidget {
  final DailyActivity activity;

  const ActivityValues({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final style = theme.textTheme.tileSecondary.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.statisticsRounds(activity.roundCount),
          style: style,
        ),
        Text(
          l10n.statisticsWorkValue(
            Duration(milliseconds: activity.workDurationMs).formattedStatisticsDuration(l10n),
          ),
          style: style,
        ),
        Text(
          l10n.statisticsRestValue(
            Duration(milliseconds: activity.restDurationMs).formattedStatisticsDuration(l10n),
          ),
          style: style,
        ),
        Text(
          l10n.statisticsTotalValue(
            Duration(milliseconds: activity.totalDurationMs).formattedStatisticsDuration(l10n),
          ),
          style: style,
        ),
      ],
    );
  }
}
