import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sport_timer/features/timer/timer_params.dart';
import 'package:sport_timer/features/timer/timer_state.dart';
import 'package:sport_timer/managers/audio_manager.dart';

class TimerViewModel {
  static const Duration _interval = Duration(seconds: 1);

  final TimerParams _params;
  final AudioManager _audioManager;
  final ValueNotifier<TimerState> _state;
  Timer? _timer;

  TimerViewModel(this._params, this._audioManager)
      : _state = ValueNotifier(
          TimerState(
            status: TimeCountdownStatus.initial,
            currentSeconds: _params.preparationTime.inSeconds,
            totalSeconds: _getTotalDuration(_params).inSeconds,
            currentRound: _params.rounds,
            timerStatus: TimerStatus.preparation,
            totalDuration: _getTotalDuration(_params),
          ),
        );

  ValueListenable<TimerState> get state => _state;

  bool get isActive => _timer?.isActive == true;

  static Duration _getTotalDuration(TimerParams params) {
    return Duration(
      seconds: params.preparationTime.inSeconds +
          params.roundTime.inSeconds * params.rounds +
          params.restTime.inSeconds * (params.rounds - 1),
    );
  }

  void togglePauseResume() {
    final timer = _timer;
    if (timer == null) return;
    if (timer.isActive) {
      debugPrint("$runtimeType:: paused");
      timer.cancel();
      _setState(_state.value.copyWith(status: TimeCountdownStatus.paused));
    } else {
      debugPrint("$runtimeType:: resumed");
      _setState(_state.value.copyWith(status: TimeCountdownStatus.resumed));
      start();
    }
  }

  void start() {
    if (isActive) {
      debugPrint("Timer already started");
      return;
    }

    if (_state.value.currentSeconds != 0) {
      _timer = Timer.periodic(_interval, _onTick);
    }
  }

  void dispose() {
    _timer?.cancel();
    _state.dispose();
  }

  void _onTick(Timer timer) {
    final state = _state.value;
    if (state.currentSeconds <= 0) {
      debugPrint(
          "$runtimeType:: current seconds on finish: ${state.currentSeconds}");
      timer.cancel();
      _setState(state.copyWith(status: TimeCountdownStatus.finished));
      _checkForNextTimer();
    } else {
      final currentSeconds = state.currentSeconds - _interval.inSeconds;
      debugPrint("$runtimeType:: current seconds: $currentSeconds");
      _setState(
        state.copyWith(
          currentSeconds: currentSeconds,
          totalSeconds: state.totalSeconds - _interval.inSeconds,
          status: _isAlmostFinishing()
              ? TimeCountdownStatus.almostFinishing
              : TimeCountdownStatus.getTime,
        ),
      );
    }
  }

  void _checkForNextTimer() {
    final state = _state.value;
    switch (state.timerStatus) {
      case TimerStatus.preparation:
        _setState(
          state.copyWith(
            currentSeconds: _params.roundTime.inSeconds - 1,
            totalSeconds: state.totalSeconds - 1,
            status: TimeCountdownStatus.next,
            timerStatus: TimerStatus.round,
          ),
        );
        start();
      case TimerStatus.round:
        final currentRound = state.currentRound - 1;
        if (currentRound > 0) {
          _setState(
            state.copyWith(
              currentSeconds: _params.restTime.inSeconds - 1,
              totalSeconds: state.totalSeconds - 1,
              currentRound: currentRound,
              status: TimeCountdownStatus.next,
              timerStatus: TimerStatus.rest,
            ),
          );
          start();
        } else {
          _setState(
            state.copyWith(
              currentSeconds: 0,
              totalSeconds: 0,
              currentRound: 0,
              status: TimeCountdownStatus.finished,
              timerStatus: TimerStatus.finished,
            ),
          );
        }
      case TimerStatus.rest:
        _setState(
          state.copyWith(
            currentSeconds: _params.roundTime.inSeconds - 1,
            totalSeconds: state.totalSeconds - 1,
            status: TimeCountdownStatus.next,
            timerStatus: TimerStatus.round,
          ),
        );
        start();
      case TimerStatus.finished:
        break;
    }
    debugPrint(
        "Current status is: ${_state.value.timerStatus} and round: ${_state.value.currentRound}");
  }

  bool _isAlmostFinishing() => _state.value.currentSeconds == 3;

  // Skips an equal state and plays the sound for the new status, like the old listener did.
  void _setState(TimerState next) {
    if (next == _state.value) return;
    _state.value = next;
    switch (next.status) {
      case TimeCountdownStatus.finished:
        _audioManager.playRoundFinishSound();
      case TimeCountdownStatus.almostFinishing:
        _audioManager.playPreparationSound();
      case TimeCountdownStatus.initial:
      case TimeCountdownStatus.getTime:
      case TimeCountdownStatus.paused:
      case TimeCountdownStatus.resumed:
      case TimeCountdownStatus.next:
      case TimeCountdownStatus.counterDone:
        break;
    }
  }
}
