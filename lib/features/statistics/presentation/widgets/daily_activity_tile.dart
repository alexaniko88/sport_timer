import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/presentation/extensions/daily_activity_extension.dart';
import 'package:sport_timer/features/statistics/presentation/extensions/duration_extension.dart';
import 'package:sport_timer/features/statistics/presentation/widgets/activity_values.dart';
import 'package:sport_timer/shared/presentation/extensions/l10n_context.dart';
import 'package:sport_timer/shared/presentation/extensions/text_theme_extension.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';
import 'package:sport_timer/shared/presentation/widgets/app_surface.dart';

class DailyActivityTile extends StatelessWidget {
  final DailyActivity activity;
  final VoidCallback? onTap;

  const DailyActivityTile({super.key, required this.activity, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final date = activity.formattedDate(Localizations.localeOf(context).toString());
    final rounds = l10n.statisticsRounds(activity.roundCount);
    final work = Duration(milliseconds: activity.workDurationMs).formattedStatisticsDuration(l10n);
    final rest = Duration(milliseconds: activity.restDurationMs).formattedStatisticsDuration(l10n);
    final total = Duration(milliseconds: activity.totalDurationMs).formattedStatisticsDuration(l10n);
    return Semantics(
      container: true,
      button: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      label: l10n.statisticsTileSemantics(date, rounds, work, rest, total),
      child: AppSurface(
        onTap: onTap,
        excludeFromSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date, style: Theme.of(context).textTheme.tileTitle),
            const Gap(AppSpacing.s8),
            ActivityValues(activity: activity),
          ],
        ),
      ),
    );
  }
}
