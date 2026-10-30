import 'package:sport_timer/features/timer/timer_params.dart';
import 'package:sport_timer/features/timer/timer_state.dart';

/// One part of the workout. [round] is the round the screen shows during it:
/// preparation shows round 1 and a rest shows the round that just finished.
class TimerStage {
  final TimerStatus type;
  final int round;
  final int startSeconds;
  final int lengthSeconds;

  const TimerStage({
    required this.type,
    required this.round,
    required this.startSeconds,
    required this.lengthSeconds,
  });

  int get endSeconds => startSeconds + lengthSeconds;
}

/// Where the workout is at a given elapsed second.
class TimerPosition {
  final TimerStatus status;
  final int round;
  final int secondsLeft;
  final int totalSecondsLeft;
  final int stageLengthSeconds;

  const TimerPosition({
    required this.status,
    required this.round,
    required this.secondsLeft,
    required this.totalSecondsLeft,
    required this.stageLengthSeconds,
  });
}

/// The ordered stages of a workout. It has no timers and no state.
class TimerSchedule {
  final List<TimerStage> stages;
  final int rounds;
  final int totalSeconds;

  const TimerSchedule._({
    required this.stages,
    required this.rounds,
    required this.totalSeconds,
  });

  factory TimerSchedule.fromParams(TimerParams params) {
    final stages = <TimerStage>[];
    var offset = 0;

    void add({
      required TimerStatus type,
      required int round,
      required int lengthSeconds,
    }) {
      if (lengthSeconds <= 0) return;
      stages.add(
        TimerStage(
          type: type,
          round: round,
          startSeconds: offset,
          lengthSeconds: lengthSeconds,
        ),
      );
      offset += lengthSeconds;
    }

    add(
      type: TimerStatus.preparation,
      round: 1,
      lengthSeconds: params.preparationTime.inSeconds,
    );
    for (var round = 1; round <= params.rounds; round++) {
      add(
        type: TimerStatus.round,
        round: round,
        lengthSeconds: params.roundTime.inSeconds,
      );
      if (round < params.rounds) {
        add(
          type: TimerStatus.rest,
          round: round,
          lengthSeconds: params.restTime.inSeconds,
        );
      }
    }
    return TimerSchedule._(
      stages: List.unmodifiable(stages),
      rounds: params.rounds,
      totalSeconds: offset,
    );
  }

  Duration get totalDuration => Duration(seconds: totalSeconds);

  TimerPosition positionAt(int elapsedSeconds) {
    final elapsed = elapsedSeconds < 0 ? 0 : elapsedSeconds;
    for (final stage in stages) {
      if (elapsed < stage.endSeconds) {
        return TimerPosition(
          status: stage.type,
          round: stage.round,
          secondsLeft: stage.endSeconds - elapsed,
          totalSecondsLeft: totalSeconds - elapsed,
          stageLengthSeconds: stage.lengthSeconds,
        );
      }
    }
    return TimerPosition(
      status: TimerStatus.finished,
      round: rounds,
      secondsLeft: 0,
      totalSecondsLeft: 0,
      stageLengthSeconds: 0,
    );
  }
}
