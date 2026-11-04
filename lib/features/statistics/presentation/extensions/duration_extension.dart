import 'package:sport_timer/l10n/app_localizations.dart';

extension StatisticsDurationExtension on Duration {
  String formattedStatisticsDuration(AppLocalizations l10n) {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);
    final milliseconds = inMilliseconds.remainder(1000);
    return [
      if (hours > 0) l10n.statisticsHours(hours),
      if (minutes > 0) l10n.statisticsMinutes(minutes),
      if (seconds > 0 || (hours == 0 && minutes == 0 && milliseconds == 0)) l10n.statisticsSeconds(seconds),
      if (milliseconds > 0) l10n.statisticsMilliseconds(milliseconds),
    ].join(' ');
  }
}
