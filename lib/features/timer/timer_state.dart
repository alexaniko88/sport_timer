enum TimerStatus {
  preparation,
  round,
  rest,
  finished,
}

class TimerState {
  final int currentSeconds;
  final int totalSeconds;
  final int currentRound;
  final Duration totalDuration;
  final TimerStatus timerStatus;

  const TimerState({
    required this.currentSeconds,
    required this.totalSeconds,
    required this.currentRound,
    required this.totalDuration,
    required this.timerStatus,
  });

  double get progress {
    final total = totalDuration.inSeconds;
    return total == 0 ? 0 : 1 - totalSeconds / total;
  }

  TimerState copyWith({
    int? currentSeconds,
    int? totalSeconds,
    int? currentRound,
    Duration? totalDuration,
    TimerStatus? timerStatus,
  }) {
    return TimerState(
      currentSeconds: currentSeconds ?? this.currentSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      currentRound: currentRound ?? this.currentRound,
      totalDuration: totalDuration ?? this.totalDuration,
      timerStatus: timerStatus ?? this.timerStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerState &&
          other.currentSeconds == currentSeconds &&
          other.totalSeconds == totalSeconds &&
          other.currentRound == currentRound &&
          other.totalDuration == totalDuration &&
          other.timerStatus == timerStatus;

  @override
  int get hashCode => Object.hash(
        currentSeconds,
        totalSeconds,
        currentRound,
        totalDuration,
        timerStatus,
      );
}
