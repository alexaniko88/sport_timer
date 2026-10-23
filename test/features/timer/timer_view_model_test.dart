import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/timer/timer_params.dart';
import 'package:sport_timer/features/timer/timer_state.dart';
import 'package:sport_timer/features/timer/timer_view_model.dart';
import 'package:sport_timer/managers/audio_manager.dart';

class _FakeAudioManager extends AudioManager {
  final List<String> calls = [];

  @override
  void playRoundFinishSound() => calls.add('finish');

  @override
  void playRoundStartSound() => calls.add('start');

  @override
  void playPreparationSound() => calls.add('beep');

  @override
  Future<void> dispose() async {}
}

TimerParams _params({
  int preparation = 5,
  int round = 10,
  int rest = 4,
  int rounds = 2,
}) {
  return TimerParams(
    preparationTime: Duration(seconds: preparation),
    roundTime: Duration(seconds: round),
    restTime: Duration(seconds: rest),
    rounds: rounds,
  );
}

void main() {
  late _FakeAudioManager audio;

  setUp(() => audio = _FakeAudioManager());

  void run(
    TimerParams params,
    void Function(FakeAsync fake, TimerViewModel viewModel) body,
  ) {
    fakeAsync((fake) {
      final viewModel = TimerViewModel(
        params,
        audio,
        timeSource: () => fake.elapsed,
      );
      body(fake, viewModel);
      viewModel.dispose();
    });
  }

  group('TimerViewModel', () {
    test('runs each stage for exactly its time and ends at 0', () {
      run(_params(), (fake, viewModel) {
        final timeline = <(TimerStatus, int, int, int)>[];
        void record() {
          final s = viewModel.state.value;
          timeline.add((s.timerStatus, s.currentRound, s.currentSeconds, s.totalSeconds));
        }

        viewModel.start();
        record();
        for (var i = 0; i < 29; i++) {
          fake.elapse(const Duration(seconds: 1));
          record();
        }

        expect(timeline[0], (TimerStatus.preparation, 1, 5, 29));
        expect(timeline[4], (TimerStatus.preparation, 1, 1, 25));
        expect(timeline[5], (TimerStatus.round, 1, 10, 24));
        expect(timeline[14], (TimerStatus.round, 1, 1, 15));
        expect(timeline[15], (TimerStatus.rest, 2, 4, 14));
        expect(timeline[19], (TimerStatus.round, 2, 10, 10));
        expect(timeline[28], (TimerStatus.round, 2, 1, 1));
        expect(timeline[29], (TimerStatus.finished, 2, 0, 0));
        expect(viewModel.state.value.progress, 1);
      });
    });

    test('pause and resume keep the exact remaining time', () {
      run(_params(), (fake, viewModel) {
        viewModel.start();
        fake.elapse(const Duration(milliseconds: 2500));
        expect(viewModel.state.value.currentSeconds, 3);

        viewModel.togglePauseResume();
        fake.elapse(const Duration(seconds: 30));
        expect(viewModel.state.value.currentSeconds, 3);

        viewModel.togglePauseResume();
        fake.elapse(const Duration(milliseconds: 499));
        expect(viewModel.state.value.currentSeconds, 3);
        fake.elapse(const Duration(milliseconds: 1));
        expect(viewModel.state.value.currentSeconds, 2);
        fake.elapse(const Duration(seconds: 2));
        expect(viewModel.state.value.timerStatus, TimerStatus.round);
        expect(viewModel.state.value.currentSeconds, 10);
      });
    });

    test('starts on the first round when the preparation is 0', () {
      run(_params(preparation: 0), (fake, viewModel) {
        viewModel.start();

        expect(viewModel.state.value.timerStatus, TimerStatus.round);
        expect(viewModel.state.value.currentSeconds, 10);
        expect(audio.calls, ['start']);
      });
    });

    test('goes from a round to the next round when the rest is 0', () {
      run(_params(preparation: 0, rest: 0), (fake, viewModel) {
        viewModel.start();
        fake.elapse(const Duration(seconds: 10));

        expect(viewModel.state.value.timerStatus, TimerStatus.round);
        expect(viewModel.state.value.currentRound, 2);
        expect(viewModel.state.value.currentSeconds, 10);
        expect(audio.calls, ['start', 'beep', 'start']);
      });
    });

    test('plays each sound once per event over the whole workout', () {
      run(_params(), (fake, viewModel) {
        viewModel.start();
        fake.elapse(const Duration(seconds: 40));

        expect(audio.calls, [
          'beep', // preparation, 3 seconds left
          'start', // round 1
          'beep',
          'finish', // round 1 ends
          'beep', // rest, 3 seconds left
          'start', // round 2
          'beep',
          'finish', // round 2 ends, once
        ]);
      });
    });

    test('plays the countdown beep at 3 seconds left', () {
      run(_params(), (fake, viewModel) {
        viewModel.start();
        fake.elapse(const Duration(milliseconds: 1999));
        expect(audio.calls, isEmpty);

        fake.elapse(const Duration(milliseconds: 1));
        expect(viewModel.state.value.currentSeconds, 3);
        expect(audio.calls, ['beep']);
      });
    });

    test('does not beep in a stage of 3 seconds or less', () {
      run(_params(preparation: 3, round: 3, rest: 3, rounds: 1), (fake, viewModel) {
        viewModel.start();
        fake.elapse(const Duration(seconds: 6));

        expect(audio.calls, ['start', 'finish']);
      });
    });

    test('tapping after the end does nothing', () {
      run(_params(), (fake, viewModel) {
        viewModel.start();
        fake.elapse(const Duration(seconds: 40));
        final finished = viewModel.state.value;
        final calls = List.of(audio.calls);

        viewModel.togglePauseResume();
        fake.elapse(const Duration(seconds: 5));

        expect(finished.timerStatus, TimerStatus.finished);
        expect(viewModel.state.value, finished);
        expect(audio.calls, calls);
      });
    });

    test('finishes at once when the total duration is 0', () {
      run(_params(preparation: 0, round: 0, rest: 0), (fake, viewModel) {
        viewModel.start();

        expect(viewModel.state.value.timerStatus, TimerStatus.finished);
        expect(viewModel.state.value.progress, 0);
        expect(fake.nonPeriodicTimerCount, 0);
        expect(audio.calls, isEmpty);
      });
    });

    test('plays only the current start sound after a late tick', () {
      fakeAsync((fake) {
        var skew = Duration.zero;
        final viewModel = TimerViewModel(
          _params(),
          audio,
          timeSource: () => fake.elapsed + skew,
        )..start();
        // The clock jumps ahead while the timer is late, like after a locked screen.
        skew = const Duration(seconds: 6);

        fake.elapse(const Duration(seconds: 1));

        expect(viewModel.state.value.timerStatus, TimerStatus.round);
        expect(viewModel.state.value.currentSeconds, 8);
        expect(audio.calls, ['start']);
        viewModel.dispose();
      });
    });

    test('plays only the finish sound when a late tick lands after the end', () {
      fakeAsync((fake) {
        var skew = Duration.zero;
        final viewModel = TimerViewModel(
          _params(preparation: 0),
          audio,
          timeSource: () => fake.elapsed + skew,
        )..start();
        audio.calls.clear();
        skew = const Duration(seconds: 60);

        fake.elapse(const Duration(seconds: 1));

        expect(viewModel.state.value.timerStatus, TimerStatus.finished);
        expect(audio.calls, ['finish']);
        viewModel.dispose();
      });
    });

    test('plays no stale sound when a late tick lands in a rest', () {
      fakeAsync((fake) {
        var skew = Duration.zero;
        final viewModel = TimerViewModel(
          _params(preparation: 0),
          audio,
          timeSource: () => fake.elapsed + skew,
        )..start();
        audio.calls.clear();
        skew = const Duration(seconds: 12);

        fake.elapse(const Duration(seconds: 1));

        expect(viewModel.state.value.timerStatus, TimerStatus.rest);
        expect(audio.calls, isEmpty);
        viewModel.dispose();
      });
    });

    test('dispose cancels the timer', () {
      fakeAsync((fake) {
        final viewModel = TimerViewModel(
          _params(),
          audio,
          timeSource: () => fake.elapsed,
        )..start();
        expect(fake.nonPeriodicTimerCount, 1);

        viewModel.dispose();

        expect(fake.nonPeriodicTimerCount, 0);
      });
    });
  });
}
