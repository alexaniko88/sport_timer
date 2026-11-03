import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/presentation/extensions/daily_activity_extension.dart';
import 'package:sport_timer/features/statistics/presentation/extensions/duration_extension.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';

class DailyActivityTile extends StatelessWidget {
  final DailyActivity activity;

  const DailyActivityTile({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = activity.formattedDate;
    final rounds = '${activity.roundCount} ${activity.roundCount == 1 ? 'round' : 'rounds'}';
    final work = Duration(milliseconds: activity.workDurationMs).formattedStatisticsDuration;
    final rest = Duration(milliseconds: activity.restDurationMs).formattedStatisticsDuration;
    final total = Duration(milliseconds: activity.totalDurationMs).formattedStatisticsDuration;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$date, $rounds, work $work, rest $rest, total $total',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Gap(AppSpacing.s8),
            Text(rounds),
            Text('Work: $work'),
            Text('Rest: $rest'),
            Text('Total: $total'),
          ],
        ),
      ),
    );
  }
}
