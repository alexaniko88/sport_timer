import 'package:sport_timer/features/statistics/presentation/extensions/duration_extension.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_state.dart';
import 'package:sport_timer/l10n/app_localizations.dart';

extension StatisticsPerspectiveExtension on StatisticsPerspective {
  String label(AppLocalizations l10n) => switch (this) {
        StatisticsPerspective.workTime => l10n.statisticsWorkTime,
        StatisticsPerspective.rounds => l10n.statisticsPerspectiveRounds,
        StatisticsPerspective.workVsRest => l10n.statisticsWorkVsRest,
        StatisticsPerspective.totalTime => l10n.statisticsTotalTime,
        StatisticsPerspective.consistency => l10n.statisticsConsistency,
      };

  String value(AppLocalizations l10n, {required int rounds, required int workMs, required int restMs}) {
    final work = Duration(milliseconds: workMs).formattedStatisticsDuration(l10n);
    final rest = Duration(milliseconds: restMs).formattedStatisticsDuration(l10n);
    return switch (this) {
      StatisticsPerspective.workTime || StatisticsPerspective.consistency => work,
      StatisticsPerspective.rounds => l10n.statisticsRounds(rounds),
      StatisticsPerspective.workVsRest => '${l10n.statisticsWorkValue(work)} · ${l10n.statisticsRestValue(rest)}',
      StatisticsPerspective.totalTime => Duration(milliseconds: workMs + restMs).formattedStatisticsDuration(l10n),
    };
  }
}
