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

  String get compactStatisticsDuration {
    final totalSeconds = inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = totalSeconds % 3600 ~/ 60;
    final seconds = totalSeconds % 60;
    final parts = [
      if (hours > 0) '${hours}h',
      if (minutes > 0) '${minutes}m',
      if (seconds > 0) '${seconds}s',
    ];
    return parts.isEmpty ? '0s' : parts.join(' ');
  }
}
