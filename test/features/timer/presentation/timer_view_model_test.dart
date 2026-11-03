import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/settings/domain/timer_style.dart';
import 'package:sport_timer/features/timer/domain/timer_activity_recorder.dart';
import 'package:sport_timer/features/timer/domain/timer_params.dart';
import 'package:sport_timer/features/timer/domain/timer_status.dart';
import 'package:sport_timer/features/timer/presentation/timer_view_model.dart';
import 'package:sport_timer/features/timer/domain/audio_manager.dart';
import 'package:sport_timer/features/timer/domain/background_keep_alive.dart';

class _FakeAudioManager extends AudioManager {
  final List<String> calls = [];

  @override
  void playRoundFinishSound() => calls.add('finish');

  @override
  void playWorkoutDoneSound() => calls.add('done');

  @override
  void playRoundStartSound() => calls.add('start');

  @override
  void playPreparationSound() => calls.add('beep');

  @override
  Future<void> dispose() async {}
}

class _FakeBackgroundKeepAlive extends BackgroundKeepAlive {
  int starts = 0;
  @override
  Future<void> start({
    required String notificationTitle,
    required String notificationText,
    required VoidCallback onPause,
    required VoidCallback onResume,
  }) async {
    starts++;
  }

  @override
  Future<void> setPaused({required bool isPaused}) async {}

  @override
  Future<void> updateText({required String text}) async {}

  @override
  Future<void> stop() async {}
}

class _FakeActivityRecorder implements TimerActivityRecorder {
  final run = _FakeActivityRun();
  int starts = 0;
  bool fail = false;

  @override
  Result<TimerActivityRun> start(TimerParams params) {
    starts++;
    if (fail) return Failure(Exception('No signed-in account'));
    return Success(run);
  }

  @override
  Stream<Exception> get failures => const Stream.empty();

  @override
  void retryPendingWrites() {}
}

class _FakeActivityRun implements TimerActivityRun {
  final reconciled = <Duration>[];
  final pauses = <Duration>[];
  final ends = <Duration>[];
  int resumes = 0;

  @override
  void reconcile(Duration elapsed) => reconciled.add(elapsed);

  @override
  void pause(Duration elapsed) => pauses.add(elapsed);

  @override
  void resume() => resumes++;

  @override
  void end(Duration elapsed) => ends.add(elapsed);
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
    style: TimerStyle.ring,
  );
}

void main() {
  late _FakeAudioManager audio;
  late _FakeBackgroundKeepAlive keepAlive;

  setUp(() {
    audio = _FakeAudioManager();
    keepAlive = _FakeBackgroundKeepAlive();
  });

  void run(
    TimerParams params,
    void Function(FakeAsync fake, TimerViewModel viewModel) body,
  ) {
    fakeAsync((fake) {
      final viewModel = TimerViewModel(
        params,
        audio,
        keepAlive,
        timeSource: () => fake.elapsed,
      );
      body(fake, viewModel);
      viewModel.dispose();
    });
  }

  group('TimerViewModel', () {
    test('does not start without a captured owner and can retry', () {
      fakeAsync((fake) {
        final recorder = _FakeActivityRecorder()..fail = true;
        final viewModel = TimerViewModel(
          _params(),
          audio,
          keepAlive,
          timeSource: () => fake.elapsed,
          activityRecorder: recorder,
        );
        expect(
          viewModel.start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text'),
          isFalse,
        );
        viewModel.togglePauseResume();
        fake.elapse(const Duration(seconds: 3));
        expect(fake.nonPeriodicTimerCount, 0);
        expect(keepAlive.starts, 0);
        expect(recorder.run.reconciled, isEmpty);
        expect(recorder.run.resumes, 0);
        recorder.fail = false;
        expect(
          viewModel.start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text'),
          isTrue,
        );
        expect(keepAlive.starts, 1);
        expect(recorder.starts, 2);
        expect(fake.nonPeriodicTimerCount, 1);
        viewModel.dispose();
      });
    });
    test('reconciles elapsed time on pause, resume and disposal without a new run', () {
      fakeAsync((fake) {
        final recorder = _FakeActivityRecorder();
        var skew = Duration.zero;
        final viewModel = TimerViewModel(
          _params(),
          audio,
          keepAlive,
          timeSource: () => fake.elapsed + skew,
          activityRecorder: recorder,
        )..start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');
        skew = const Duration(seconds: 16);
        viewModel.togglePauseResume();
        expect(recorder.run.pauses, [const Duration(seconds: 16)]);
        expect(recorder.run.reconciled.last, const Duration(seconds: 16));
        fake.elapse(const Duration(seconds: 30));
        viewModel.togglePauseResume();
        expect(recorder.starts, 1);
        expect(recorder.run.resumes, 1);
        skew += const Duration(seconds: 2);
        viewModel.dispose();
        expect(recorder.run.ends, [const Duration(seconds: 18)]);
      });
    });

    test('reconciles a delayed lifecycle update and finishes a run only once', () {
      fakeAsync((fake) {
        final recorder = _FakeActivityRecorder();
        var skew = Duration.zero;
        final viewModel = TimerViewModel(
          _params(),
          audio,
          keepAlive,
          timeSource: () => fake.elapsed + skew,
          activityRecorder: recorder,
        )..start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');
        skew = const Duration(seconds: 40);
        viewModel.reconcileProgress();
        expect(recorder.run.reconciled.last, const Duration(seconds: 40));
        expect(recorder.run.ends, [const Duration(seconds: 40)]);
        expect(viewModel.state.value.timerStatus, TimerStatus.finished);
        expect(fake.nonPeriodicTimerCount, 0);
        viewModel.dispose();
        expect(recorder.run.ends, hasLength(1));
      });
    });

    test('reconciling a running timer replaces its pending tick', () {
      fakeAsync((fake) {
        final recorder = _FakeActivityRecorder();
        final viewModel = TimerViewModel(
          _params(),
          audio,
          keepAlive,
          timeSource: () => fake.elapsed,
          activityRecorder: recorder,
        )..start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');
        viewModel.reconcileProgress();
        viewModel.reconcileProgress();
        expect(fake.nonPeriodicTimerCount, 1);
        viewModel.dispose();
      });
    });

    test('runs each stage for exactly its time and ends at 0', () {
      run(_params(), (fake, viewModel) {
        final timeline = <(TimerStatus, int, int, int)>[];
        void record() {
          final s = viewModel.state.value;
          timeline.add((s.timerStatus, s.currentRound, s.currentSeconds, s.totalSeconds));
        }

        viewModel.start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');
        record();
        for (var i = 0; i < 29; i++) {
          fake.elapse(const Duration(seconds: 1));
          record();
        }

        expect(timeline[0], (TimerStatus.preparation, 1, 5, 29));
        expect(timeline[4], (TimerStatus.preparation, 1, 1, 25));
        expect(timeline[5], (TimerStatus.round, 1, 10, 24));
        expect(timeline[14], (TimerStatus.round, 1, 1, 15));
        expect(timeline[15], (TimerStatus.rest, 1, 4, 14));
        expect(timeline[19], (TimerStatus.round, 2, 10, 10));
        expect(timeline[28], (TimerStatus.round, 2, 1, 1));
        expect(timeline[29], (TimerStatus.finished, 2, 0, 0));
        expect(viewModel.state.value.progress, 1);
      });
    });

    test('pause and resume keep the exact remaining time', () {
      run(_params(), (fake, viewModel) {
        viewModel.start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');
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

    test('isPaused is true after a pause and false after a resume', () {
      run(_params(), (fake, viewModel) {
        viewModel.start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');
        expect(viewModel.state.value.isPaused, isFalse);

        viewModel.togglePauseResume();
        expect(viewModel.state.value.isPaused, isTrue);
        fake.elapse(const Duration(seconds: 3));
        expect(viewModel.state.value.isPaused, isTrue);

        viewModel.togglePauseResume();
        expect(viewModel.state.value.isPaused, isFalse);
        fake.elapse(const Duration(seconds: 1));
        expect(viewModel.state.value.isPaused, isFalse);
      });
    });

    test('isPaused stays false when toggling after the end', () {
      run(_params(), (fake, viewModel) {
        viewModel.start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');
        fake.elapse(const Duration(seconds: 40));

        viewModel.togglePauseResume();

        expect(viewModel.state.value.timerStatus, TimerStatus.finished);
        expect(viewModel.state.value.isPaused, isFalse);
      });
    });

    test('starts on the first round when the preparation is 0', () {
      run(_params(preparation: 0), (fake, viewModel) {
        viewModel.start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');

        expect(viewModel.state.value.timerStatus, TimerStatus.round);
        expect(viewModel.state.value.currentSeconds, 10);
        expect(audio.calls, ['start']);
      });
    });

    test('goes from a round to the next round when the rest is 0', () {
      run(_params(preparation: 0, rest: 0), (fake, viewModel) {
        viewModel.start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');
        fake.elapse(const Duration(seconds: 10));

        expect(viewModel.state.value.timerStatus, TimerStatus.round);
        expect(viewModel.state.value.currentRound, 2);
        expect(viewModel.state.value.currentSeconds, 10);
        expect(audio.calls, ['start', 'beep', 'start']);
      });
    });

    test('plays each sound once per event over the whole workout', () {
      run(_params(), (fake, viewModel) {
        viewModel.start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');
        fake.elapse(const Duration(seconds: 40));

        expect(audio.calls, [
          'beep', // preparation, 3 seconds left
          'start', // round 1
          'beep',
          'finish', // round 1 ends
          'beep', // rest, 3 seconds left
          'start', // round 2
          'beep',
          'done', // workout ends, once
        ]);
      });
    });

    test('plays the countdown beep at 3 seconds left', () {
      run(_params(), (fake, viewModel) {
        viewModel.start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');
        fake.elapse(const Duration(milliseconds: 1999));
        expect(audio.calls, isEmpty);

        fake.elapse(const Duration(milliseconds: 1));
        expect(viewModel.state.value.currentSeconds, 3);
        expect(audio.calls, ['beep']);
      });
    });

    test('does not beep in a stage of 3 seconds or less', () {
      run(_params(preparation: 3, round: 3, rest: 3, rounds: 1), (fake, viewModel) {
        viewModel.start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');
        fake.elapse(const Duration(seconds: 6));

        expect(audio.calls, ['start', 'done']);
      });
    });

    test('tapping after the end does nothing', () {
      run(_params(), (fake, viewModel) {
        viewModel.start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');
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
        viewModel.start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');

        expect(viewModel.state.value.timerStatus, TimerStatus.finished);
        expect(viewModel.state.value.progress, 0);
        expect(fake.nonPeriodicTimerCount, 0);
        expect(audio.calls, isEmpty);
      });
    });

    test('exposes the stage length, the round count and no progress at the start of a stage', () {
      run(_params(), (fake, viewModel) {
        viewModel.start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');

        final state = viewModel.state.value;
        expect(state.timerStatus, TimerStatus.preparation);
        expect(state.stageSeconds, 5);
        expect(state.totalRounds, 2);
        expect(state.stageProgress, 0);

        fake.elapse(const Duration(seconds: 5));

        expect(viewModel.state.value.timerStatus, TimerStatus.round);
        expect(viewModel.state.value.stageSeconds, 10);
        expect(viewModel.state.value.stageProgress, 0);
      });
    });

    test('stageProgress follows the current stage only', () {
      run(_params(), (fake, viewModel) {
        viewModel.start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');
        fake.elapse(const Duration(seconds: 7));

        final state = viewModel.state.value;
        expect(state.timerStatus, TimerStatus.round);
        expect(state.currentSeconds, 8);
        expect(state.stageProgress, closeTo(0.2, 0.0001));
      });
    });

    test('stageProgress is 1 when the workout is finished', () {
      run(_params(), (fake, viewModel) {
        viewModel.start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');
        fake.elapse(const Duration(seconds: 40));

        final state = viewModel.state.value;
        expect(state.timerStatus, TimerStatus.finished);
        expect(state.stageSeconds, 0);
        expect(state.totalRounds, 2);
        expect(state.stageProgress, 1);
      });
    });

    test('plays only the current start sound after a late tick', () {
      fakeAsync((fake) {
        var skew = Duration.zero;
        final viewModel = TimerViewModel(
          _params(),
          audio,
          keepAlive,
          timeSource: () => fake.elapsed + skew,
        )..start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');
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
          keepAlive,
          timeSource: () => fake.elapsed + skew,
        )..start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');
        audio.calls.clear();
        skew = const Duration(seconds: 60);

        fake.elapse(const Duration(seconds: 1));

        expect(viewModel.state.value.timerStatus, TimerStatus.finished);
        expect(audio.calls, ['done']);
        viewModel.dispose();
      });
    });

    test('plays no stale sound when a late tick lands in a rest', () {
      fakeAsync((fake) {
        var skew = Duration.zero;
        final viewModel = TimerViewModel(
          _params(preparation: 0),
          audio,
          keepAlive,
          timeSource: () => fake.elapsed + skew,
        )..start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');
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
          keepAlive,
          timeSource: () => fake.elapsed,
        )..start(notificationTitle: 'Workout', notificationTextBuilder: (_) => 'Text');
        expect(fake.nonPeriodicTimerCount, 1);

        viewModel.dispose();

        expect(fake.nonPeriodicTimerCount, 0);
      });
    });
  });
}
