import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sport_timer/features/timer/timer_params.dart';
import 'package:sport_timer/features/timer/timer_schedule.dart';
import 'package:sport_timer/features/timer/timer_state.dart';
import 'package:sport_timer/managers/audio_manager.dart';
import 'package:sport_timer/managers/background_keep_alive.dart';

/// Returns the time since a fixed start. It must be monotonic.
typedef TimeSource = Duration Function();

/// Builds the second line of the background notification for a state.
typedef NotificationTextBuilder = String Function(TimerState state);

class TimerViewModel {
  static const int _countdownSeconds = 3;
  static const int _millisecondsPerSecond = 1000;
  // A tick further apart than this was late (for example a locked screen),
  // so the sounds of the seconds it skipped are no longer worth playing.
  static const Duration _staleGap = Duration(seconds: 2);

  final TimerSchedule _schedule;
  final AudioManager _audioManager;
  final BackgroundKeepAlive _keepAlive;
  final TimeSource _timeSource;
  final ValueNotifier<TimerState> _state;
  Timer? _timer;
  Duration? _runningSince;
  Duration _elapsedBeforeRun = Duration.zero;
  Duration _lastTickElapsed = Duration.zero;
  TimerState? _lastTicked;
  NotificationTextBuilder? _notificationTextBuilder;
  TimerStatus? _notifiedStatus;
  int? _notifiedRound;
  bool _hasStarted = false;
  bool _disposed = false;

  TimerViewModel(
    TimerParams params,
    AudioManager audioManager,
    BackgroundKeepAlive keepAlive, {
    TimeSource? timeSource,
  }) : this._(
          TimerSchedule.fromParams(params),
          audioManager,
          keepAlive,
          timeSource ?? _stopwatchTimeSource(),
        );

  TimerViewModel._(this._schedule, this._audioManager, this._keepAlive, this._timeSource)
      : _state = ValueNotifier(_stateFrom(_schedule, _schedule.positionAt(0)));

  ValueListenable<TimerState> get state => _state;

  // A Stopwatch is monotonic, so changing the device clock cannot move the timer.
  static TimeSource _stopwatchTimeSource() {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }

  static TimerState _stateFrom(TimerSchedule schedule, TimerPosition position) {
    return TimerState(
      currentSeconds: position.secondsLeft,
      totalSeconds: position.totalSecondsLeft,
      currentRound: position.round,
      totalRounds: schedule.rounds,
      stageSeconds: position.stageLengthSeconds,
      totalDuration: schedule.totalDuration,
      timerStatus: position.status,
    );
  }

  Duration get _elapsed {
    final runningSince = _runningSince;
    return runningSince == null ? _elapsedBeforeRun : _elapsedBeforeRun + _timeSource() - runningSince;
  }

  void start({
    required String notificationTitle,
    required NotificationTextBuilder notificationTextBuilder,
  }) {
    if (_disposed || _hasStarted) return;
    _hasStarted = true;
    _notificationTextBuilder = notificationTextBuilder;
    _notifiedStatus = _state.value.timerStatus;
    _notifiedRound = _state.value.currentRound;
    _keepAlive.start(
      notificationTitle: notificationTitle,
      notificationText: notificationTextBuilder(_state.value),
      onPause: _pauseIfRunning,
      onResume: _resumeIfPaused,
    );
    _run();
  }

  void togglePauseResume() {
    if (_disposed || !_hasStarted || _state.value.timerStatus == TimerStatus.finished) return;
    if (_runningSince == null) {
      debugPrint("$runtimeType:: resumed");
      _keepAlive.setPaused(isPaused: false);
      _run();
    } else {
      debugPrint("$runtimeType:: paused");
      _elapsedBeforeRun = _elapsed;
      _runningSince = null;
      _timer?.cancel();
      _state.value = _state.value.copyWith(isPaused: true);
      _keepAlive.setPaused(isPaused: true);
    }
  }

  // Taps on the notification can arrive late, so each one checks the current state first.
  void _pauseIfRunning() {
    if (_runningSince != null) togglePauseResume();
  }

  void _resumeIfPaused() {
    if (_runningSince == null) togglePauseResume();
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _keepAlive.stop();
    _state.dispose();
  }

  void _run() {
    _runningSince = _timeSource();
    _tick();
  }

  // Each tick reads the time source instead of counting ticks, so a late tick
  // still shows the right time.
  void _tick() {
    if (_disposed) return;
    final elapsed = _elapsed;
    final position = _schedule.positionAt(elapsed.inSeconds);
    final next = _stateFrom(_schedule, position);
    _state.value = next;
    _playSounds(
      previous: _lastTicked,
      next: next,
      stageLengthSeconds: position.stageLengthSeconds,
      isStale: elapsed - _lastTickElapsed > _staleGap,
    );
    _lastTicked = next;
    _lastTickElapsed = elapsed;

    _updateNotificationText(next);

    if (next.timerStatus == TimerStatus.finished) {
      _runningSince = null;
      _elapsedBeforeRun = elapsed;
      _keepAlive.stop();
      return;
    }
    final millisecondsToNextSecond = _millisecondsPerSecond - elapsed.inMilliseconds % _millisecondsPerSecond;
    _timer = Timer(Duration(milliseconds: millisecondsToNextSecond), _tick);
  }

  // The text only changes with the stage, so it is sent on a stage change and not every second.
  void _updateNotificationText(TimerState next) {
    final builder = _notificationTextBuilder;
    if (builder == null || next.timerStatus == TimerStatus.finished) return;
    if (next.timerStatus == _notifiedStatus && next.currentRound == _notifiedRound) return;
    _notifiedStatus = next.timerStatus;
    _notifiedRound = next.currentRound;
    _keepAlive.updateText(text: builder(next));
  }

  // Compares the old and new state, so a sound plays once per event. A null
  // [previous] is the first tick. After a stale tick only the sounds of the
  // current position play: the start of a round, or the end of the workout.
  void _playSounds({
    required TimerState? previous,
    required TimerState next,
    required int stageLengthSeconds,
    required bool isStale,
  }) {
    final stageChanged =
        previous == null || previous.timerStatus != next.timerStatus || previous.currentRound != next.currentRound;
    final isRoundStart = next.timerStatus == TimerStatus.round && stageChanged;
    final isWorkoutEnd =
        previous != null && previous.timerStatus == TimerStatus.round && next.timerStatus == TimerStatus.finished;
    final isRoundEnd = previous != null &&
        previous.timerStatus == TimerStatus.round &&
        stageChanged &&
        !isWorkoutEnd &&
        !isStale &&
        !isRoundStart;

    if (isWorkoutEnd) _audioManager.playWorkoutDoneSound();
    if (isRoundEnd) _audioManager.playRoundFinishSound();
    if (isRoundStart) _audioManager.playRoundStartSound();

    final isCountdown = !isStale &&
        next.timerStatus != TimerStatus.finished &&
        stageLengthSeconds > _countdownSeconds &&
        next.currentSeconds <= _countdownSeconds;
    if (isCountdown && (previous == null || stageChanged || previous.currentSeconds > _countdownSeconds)) {
      _audioManager.playPreparationSound();
    }
  }
}
