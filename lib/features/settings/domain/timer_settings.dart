class TimerSettings {
  static const int maxRounds = 30;

  final Duration preparationTime;
  final Duration roundTime;
  final Duration restTime;
  final int rounds;

  const TimerSettings({
    required this.preparationTime,
    required this.roundTime,
    required this.restTime,
    required this.rounds,
  });

  TimerSettings copyWith({
    Duration? preparationTime,
    Duration? roundTime,
    Duration? restTime,
    int? rounds,
  }) {
    return TimerSettings(
      preparationTime: preparationTime ?? this.preparationTime,
      roundTime: roundTime ?? this.roundTime,
      restTime: restTime ?? this.restTime,
      rounds: rounds ?? this.rounds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerSettings &&
          other.preparationTime == preparationTime &&
          other.roundTime == roundTime &&
          other.restTime == restTime &&
          other.rounds == rounds;

  @override
  int get hashCode => Object.hash(preparationTime, roundTime, restTime, rounds);
}
