part of 'timer.dart';

class TimerParams {
  const TimerParams({
    required this.preparationTime,
    required this.roundTime,
    required this.restTime,
    required this.rounds,
  });

  final Duration preparationTime;
  final Duration roundTime;
  final Duration restTime;
  final int rounds;
}

@injectable
class TimeCountdownCubit extends Cubit<TimeCountdownState> {
  TimeCountdownCubit(@factoryParam this.timerParams)
      : super(
          TimeCountdownState(
            status: TimeCountdownStatus.initial,
            currentSeconds: timerParams.preparationTime.inSeconds,
            totalSeconds: _getTotalDuration(timerParams).inSeconds,
            currentRound: timerParams.rounds,
            timerStatus: TimerStatus.preparation,
            totalDuration: _getTotalDuration(timerParams),
          ),
        );

  static Duration _getTotalDuration(TimerParams timerParams) {
    return Duration(
        seconds: timerParams.preparationTime.inSeconds +
            timerParams.roundTime.inSeconds * timerParams.rounds +
            timerParams.restTime.inSeconds * (timerParams.rounds - 1));
  }

  final TimerParams timerParams;
  final interval = const Duration(seconds: 1);
  Timer? _timer;

  @override
  Future<void> close() {
    if (_timer?.isActive == true) {
      _timer?.cancel();
    }
    return super.close();
  }

  void togglePauseResume() {
    if (_timer != null) {
      if (_timer!.isActive) {
        printLog("$runtimeType:: paused");
        _timer?.cancel();
        emit(
          TimeCountdownState(
            status: TimeCountdownStatus.paused,
            currentSeconds: state.currentSeconds,
            currentRound: state.currentRound,
            totalSeconds: state.totalSeconds,
            timerStatus: state.timerStatus,
            totalDuration: state.totalDuration,
          ),
        );
      } else {
        printLog("$runtimeType:: resumed");
        emit(
          TimeCountdownState(
            status: TimeCountdownStatus.resumed,
            currentSeconds: state.currentSeconds,
            currentRound: state.currentRound,
            totalSeconds: state.totalSeconds,
            timerStatus: state.timerStatus,
            totalDuration: state.totalDuration,
          ),
        );
        start();
      }
    }
  }

  bool get isActive => _timer?.isActive == true;

  void start() {
    if (_timer?.isActive == true) {
      printLog("Timer already started");
    }

    if (state.currentSeconds != 0) {
      _timer = Timer.periodic(
        interval,
        (Timer timer) {
          if (state.currentSeconds <= 0) {
            printLog("$runtimeType:: current seconds on finish: ${state.currentSeconds}");
            timer.cancel();
            emit(TimeCountdownState(
              currentSeconds: state.currentSeconds,
              currentRound: state.currentRound,
              totalSeconds: state.totalSeconds,
              status: TimeCountdownStatus.finished,
              timerStatus: state.timerStatus,
              totalDuration: state.totalDuration,
            ));
            _checkForNextTimer();
          } else {
            final currentSeconds = state.currentSeconds - interval.inSeconds;
            final totalSeconds = state.totalSeconds - interval.inSeconds;
            printLog("$runtimeType:: current seconds: $currentSeconds");
            emit(TimeCountdownState(
              currentSeconds: currentSeconds,
              currentRound: state.currentRound,
              totalSeconds: totalSeconds,
              status: _isAlmostFinishing() ? TimeCountdownStatus.almostFinishing : TimeCountdownStatus.getTime,
              timerStatus: state.timerStatus,
              totalDuration: state.totalDuration,
            ));
          }
        },
      );
    }
  }

  void _checkForNextTimer() {
    switch (state.timerStatus) {
      case TimerStatus.preparation:
        emit(TimeCountdownState(
          currentSeconds: timerParams.roundTime.inSeconds - 1,
          totalSeconds: state.totalSeconds - 1,
          currentRound: state.currentRound,
          status: TimeCountdownStatus.next,
          timerStatus: TimerStatus.round,
          totalDuration: state.totalDuration,
        ));
        start();
        break;
      case TimerStatus.round:
        final currentRound = state.currentRound - 1;
        if (currentRound > 0) {
          emit(TimeCountdownState(
            currentSeconds: timerParams.restTime.inSeconds - 1,
            totalSeconds: state.totalSeconds - 1,
            currentRound: currentRound,
            status: TimeCountdownStatus.next,
            timerStatus: TimerStatus.rest,
            totalDuration: state.totalDuration,
          ));
          start();
        } else {
          emit(TimeCountdownState(
            currentSeconds: 0,
            totalSeconds: 0,
            currentRound: 0,
            status: TimeCountdownStatus.finished,
            timerStatus: TimerStatus.finished,
            totalDuration: state.totalDuration,
          ));
        }
        break;
      case TimerStatus.rest:
        emit(TimeCountdownState(
          currentSeconds: timerParams.roundTime.inSeconds - 1,
          totalSeconds: state.totalSeconds - 1,
          currentRound: state.currentRound,
          status: TimeCountdownStatus.next,
          timerStatus: TimerStatus.round,
          totalDuration: state.totalDuration,
        ));
        start();
        break;
      case TimerStatus.finished:
        break;
    }
    printLog("Current status is: ${state.timerStatus} and round: ${state.currentRound}");
  }

  bool _isAlmostFinishing() => state.currentSeconds == 3;
}
