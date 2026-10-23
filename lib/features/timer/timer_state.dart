enum TimerStatus {
  preparation,
  round,
  rest,
  finished,
}

enum TimeCountdownStatus {
  initial,
  getTime,
  finished,
  paused,
  resumed,
  almostFinishing,
  next,
  counterDone,
}

class TimerState {
  final int currentSeconds;
  final int totalSeconds;
  final int currentRound;
  final Duration totalDuration;
  final TimerStatus timerStatus;
  final TimeCountdownStatus status;

  const TimerState({
    required this.currentSeconds,
    required this.totalSeconds,
    required this.currentRound,
    required this.totalDuration,
    required this.timerStatus,
    required this.status,
  });

  TimerState copyWith({
    int? currentSeconds,
    int? totalSeconds,
    int? currentRound,
    Duration? totalDuration,
    TimerStatus? timerStatus,
    TimeCountdownStatus? status,
  }) {
    return TimerState(
      currentSeconds: currentSeconds ?? this.currentSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      currentRound: currentRound ?? this.currentRound,
      totalDuration: totalDuration ?? this.totalDuration,
      timerStatus: timerStatus ?? this.timerStatus,
      status: status ?? this.status,
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
          other.timerStatus == timerStatus &&
          other.status == status;

  @override
  int get hashCode => Object.hash(
        currentSeconds,
        totalSeconds,
        currentRound,
        totalDuration,
        timerStatus,
        status,
      );
}
