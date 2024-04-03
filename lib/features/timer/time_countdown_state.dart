part of 'timer.dart';

@freezed
class TimeCountdownState with _$TimeCountdownState {
  const factory TimeCountdownState({
    required int currentSeconds,
    required int totalSeconds,
    required int currentRound,
    required Duration totalDuration,
    required TimerStatus timerStatus,
    required TimeCountdownStatus status,
  }) = _TimeCountdownState;
}

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


