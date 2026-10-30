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
  final int totalRounds;
  final int stageSeconds;
  final Duration totalDuration;
  final TimerStatus timerStatus;
  final bool isPaused;

  const TimerState({
    required this.currentSeconds,
    required this.totalSeconds,
    required this.currentRound,
    required this.totalRounds,
    required this.stageSeconds,
    required this.totalDuration,
    required this.timerStatus,
    this.isPaused = false,
  });

  double get progress {
    final total = totalDuration.inSeconds;
    return total == 0 ? 0 : 1 - totalSeconds / total;
  }

  // Progress of the current stage only, from 0 to 1. A finished workout is a full ring.
  double get stageProgress {
    if (timerStatus == TimerStatus.finished) return 1;
    return stageSeconds == 0 ? 0 : 1 - currentSeconds / stageSeconds;
  }

  TimerState copyWith({
    int? currentSeconds,
    int? totalSeconds,
    int? currentRound,
    int? totalRounds,
    int? stageSeconds,
    Duration? totalDuration,
    TimerStatus? timerStatus,
    bool? isPaused,
  }) {
    return TimerState(
      currentSeconds: currentSeconds ?? this.currentSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      stageSeconds: stageSeconds ?? this.stageSeconds,
      totalDuration: totalDuration ?? this.totalDuration,
      timerStatus: timerStatus ?? this.timerStatus,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerState &&
          other.currentSeconds == currentSeconds &&
          other.totalSeconds == totalSeconds &&
          other.currentRound == currentRound &&
          other.totalRounds == totalRounds &&
          other.stageSeconds == stageSeconds &&
          other.totalDuration == totalDuration &&
          other.timerStatus == timerStatus &&
          other.isPaused == isPaused;

  @override
  int get hashCode => Object.hash(
        currentSeconds,
        totalSeconds,
        currentRound,
        totalRounds,
        stageSeconds,
        totalDuration,
        timerStatus,
        isPaused,
      );
}
