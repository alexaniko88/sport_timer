part of '../timer.dart';

class TimerParams2 {
  const TimerParams2({
    required this.duration,
    required this.preparationTime,
    required this.roundTime,
    required this.restTime,
    required this.rounds,
  });

  final int duration;
  final Duration preparationTime;
  final Duration roundTime;
  final Duration restTime;
  final int rounds;
}

@injectable
class TimeCountdownCubit extends Cubit<TimeCountdownState> {
  TimeCountdownCubit(@factoryParam this._timerParams)
      : super(
          const TimeCountdownState(
            availabilitySlotsStatus: AvailabilitySlotsStatus.initial,
            formattedTime: '',
            currentTime: 0.0,
          ),
        );

  final interval = const Duration(milliseconds: 100);
  final TimerParams2 _timerParams;

  Timer? _timer;
  bool _isFinished = false;
  late int _timeout = _timerParams.duration;
  late int _currentMilliseconds = _timeout;
  DateTime? _pausedTimestamp;

  @override
  Future<void> close() {
    if (_timer?.isActive == true) {
      _timer?.cancel();
    }
    return super.close();
  }

  void restart() {
    _timer?.cancel();
    _isFinished = false;
    _currentMilliseconds = _timeout;
    emit(
      TimeCountdownState(
        availabilitySlotsStatus: AvailabilitySlotsStatus.getTime,
        formattedTime: _formattedTimeAsMinutesAndSeconds,
        currentTime: _currentTimeAsDoubleFractions,
      ),
    );
    _start();
  }

  void stop() {
    _timer?.cancel();
    _isFinished = false;
    _currentMilliseconds = _timeout;
  }

  void pause() {
    if (_timer?.isActive ?? false) {
      _pausedTimestamp = DateTime.now();
      print("$runtimeType:: paused with timestamp: ${_pausedTimestamp.toString()}");
      _timer?.cancel();
    }
  }

  void resume() {
    if (_pausedTimestamp != null) {
      final resumeTimestamp = DateTime.now().difference(_pausedTimestamp!).inSeconds;
      _currentMilliseconds = resumeTimestamp < _currentMilliseconds ? _currentMilliseconds - resumeTimestamp : 0;
      print(
        "$runtimeType:: resumed with passed seconds: "
        "$resumeTimestamp and current seconds: $_currentMilliseconds",
      );
      _pausedTimestamp = null;
      _start();
    }
  }

  bool get isActive => _timer?.isActive == true;

  void updateTimeout(int timeout) => _timeout = timeout;

  void _start() {
    if (_timer?.isActive == true) {
      print("Timer already started");
    }

    if (_currentMilliseconds != 0) {
      _timer = Timer.periodic(
        interval,
        (Timer timer) {
          if (_currentMilliseconds <= 0) {
            timer.cancel();
            _isFinished = true;
            emit(
              TimeCountdownState(
                availabilitySlotsStatus: AvailabilitySlotsStatus.countdownFinished,
                formattedTime: _formattedTimeAsMinutesAndSeconds,
                currentTime: _currentTimeAsDoubleFractions,
              ),
            );
          } else {
            _isFinished = false;
            _currentMilliseconds = _currentMilliseconds - interval.inMilliseconds;
            emit(
              TimeCountdownState(
                availabilitySlotsStatus: AvailabilitySlotsStatus.getTime,
                formattedTime: _formattedTimeAsMinutesAndSeconds,
                currentTime: _currentTimeAsDoubleFractions,
              ),
            );
          }
        },
      );
    } else {
      if (!_isFinished) {
        _isFinished = true;
        emit(
          TimeCountdownState(
            availabilitySlotsStatus: AvailabilitySlotsStatus.countdownFinished,
            formattedTime: _formattedTimeAsMinutesAndSeconds,
            currentTime: _currentTimeAsDoubleFractions,
          ),
        );
      } else {
        restart();
      }
    }
  }

  String get _formattedTimeAsMinutesAndSeconds => Duration(milliseconds: _currentMilliseconds).asMinutesAndSeconds;

  double get _currentTimeAsDoubleFractions => _currentMilliseconds / 1000 / (_timerParams.duration / 1000);
}
