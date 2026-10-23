import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/timer/timer_params.dart';
import 'package:sport_timer/features/timer/timer_schedule.dart';
import 'package:sport_timer/features/timer/timer_state.dart';

TimerParams _params({
  int preparation = 5,
  int round = 10,
  int rest = 4,
  int rounds = 3,
}) {
  return TimerParams(
    preparationTime: Duration(seconds: preparation),
    roundTime: Duration(seconds: round),
    restTime: Duration(seconds: rest),
    rounds: rounds,
  );
}

void main() {
  group('TimerSchedule.fromParams', () {
    test('orders the stages and numbers the rounds', () {
      final schedule = TimerSchedule.fromParams(_params());

      expect(
        schedule.stages.map((s) => (s.type, s.round, s.startSeconds, s.lengthSeconds)),
        [
          (TimerStatus.preparation, 1, 0, 5),
          (TimerStatus.round, 1, 5, 10),
          (TimerStatus.rest, 2, 15, 4),
          (TimerStatus.round, 2, 19, 10),
          (TimerStatus.rest, 3, 29, 4),
          (TimerStatus.round, 3, 33, 10),
        ],
      );
    });

    test('has the total of all stages', () {
      final schedule = TimerSchedule.fromParams(_params());

      expect(schedule.totalSeconds, 43);
      expect(schedule.totalDuration, const Duration(seconds: 43));
    });

    test('skips a preparation of 0 seconds', () {
      final schedule = TimerSchedule.fromParams(_params(preparation: 0));

      expect(schedule.stages.first.type, TimerStatus.round);
      expect(schedule.stages.first.startSeconds, 0);
      expect(schedule.totalSeconds, 38);
    });

    test('skips a rest of 0 seconds', () {
      final schedule = TimerSchedule.fromParams(_params(rest: 0));

      expect(schedule.stages.map((s) => s.type), [
        TimerStatus.preparation,
        TimerStatus.round,
        TimerStatus.round,
        TimerStatus.round,
      ]);
      expect(schedule.totalSeconds, 35);
    });

    test('has no rest for a single round', () {
      final schedule = TimerSchedule.fromParams(_params(rounds: 1));

      expect(schedule.stages.map((s) => s.type), [
        TimerStatus.preparation,
        TimerStatus.round,
      ]);
      expect(schedule.totalSeconds, 15);
    });
  });

  group('TimerSchedule.positionAt', () {
    final schedule = TimerSchedule.fromParams(_params());

    test('is the first stage at second 0', () {
      final position = schedule.positionAt(0);

      expect(position.status, TimerStatus.preparation);
      expect(position.round, 1);
      expect(position.secondsLeft, 5);
      expect(position.totalSecondsLeft, 43);
      expect(position.stageLengthSeconds, 5);
    });

    test('moves to the next stage exactly at its start', () {
      final last = schedule.positionAt(4);
      final first = schedule.positionAt(5);

      expect(last.status, TimerStatus.preparation);
      expect(last.secondsLeft, 1);
      expect(first.status, TimerStatus.round);
      expect(first.secondsLeft, 10);
      expect(first.totalSecondsLeft, 38);
    });

    test('shows the next round during a rest', () {
      final position = schedule.positionAt(15);

      expect(position.status, TimerStatus.rest);
      expect(position.round, 2);
      expect(position.secondsLeft, 4);
    });

    test('is finished at the total and after it', () {
      for (final elapsed in [43, 100]) {
        final position = schedule.positionAt(elapsed);

        expect(position.status, TimerStatus.finished);
        expect(position.round, 3);
        expect(position.secondsLeft, 0);
        expect(position.totalSecondsLeft, 0);
      }
    });

    test('is finished at second 0 when there is nothing to run', () {
      final empty = TimerSchedule.fromParams(_params(preparation: 0, round: 0, rest: 0));

      expect(empty.positionAt(0).status, TimerStatus.finished);
    });
  });
}
