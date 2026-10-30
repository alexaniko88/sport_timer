import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/timer/timer_state.dart';

TimerState _state({
  required TimerStatus status,
  required int currentRound,
  int currentSeconds = 5,
}) {
  return TimerState(
    currentSeconds: currentSeconds,
    totalSeconds: 100,
    currentRound: currentRound,
    totalRounds: 3,
    stageSeconds: 10,
    totalDuration: const Duration(seconds: 100),
    timerStatus: status,
  );
}

void main() {
  group('TimerState.roundFill', () {
    test('is empty for every round during the preparation', () {
      final state = _state(status: TimerStatus.preparation, currentRound: 1);

      expect([1, 2, 3].map(state.roundFill), [0, 0, 0]);
    });

    test('fills only the running round with the stage progress', () {
      final state = _state(status: TimerStatus.round, currentRound: 2);

      expect([1, 2, 3].map(state.roundFill), [1, 0.5, 0]);
    });

    test('keeps the round before a rest full and the next round empty during a rest', () {
      final state = _state(status: TimerStatus.rest, currentRound: 1);

      expect([1, 2, 3].map(state.roundFill), [1, 0, 0]);
    });

    test('is full for every round when finished', () {
      final state = _state(status: TimerStatus.finished, currentRound: 3, currentSeconds: 0);

      expect([1, 2, 3].map(state.roundFill), [1, 1, 1]);
    });
  });

  group('TimerState.totalTime', () {
    test('is the total time left while running', () {
      final state = _state(status: TimerStatus.round, currentRound: 1);

      expect(state.totalTime, const Duration(seconds: 100));
    });

    test('is the whole workout once finished', () {
      final state = _state(status: TimerStatus.finished, currentRound: 3, currentSeconds: 0).copyWith(totalSeconds: 0);

      expect(state.totalTime, const Duration(seconds: 100));
    });
  });
}
