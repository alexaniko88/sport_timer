extension StatisticsDurationExtension on Duration {
  String get formattedStatisticsDuration {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);
    final parts = <String>[
      if (hours > 0) '$hours ${hours == 1 ? 'hour' : 'hours'}',
      if (minutes > 0) '$minutes ${minutes == 1 ? 'minute' : 'minutes'}',
      if (seconds > 0 || (hours == 0 && minutes == 0)) '$seconds ${seconds == 1 ? 'second' : 'seconds'}',
    ];
    return parts.join(' ');
  }
}
