import 'package:basic_flutter_helper/basic_flutter_helper.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lottie/lottie.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/managers/audio_manager.dart';
import 'package:collection/collection.dart';
import 'package:sport_timer/theme/styles/styles.dart';

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

enum TimerStatus {
  preparation,
  round,
  rest,
  finished,
}

class ArcStopwatch extends StatefulWidget {
  final TimerParams timerParams;

  const ArcStopwatch({
    super.key,
    required this.timerParams,
  });

  @override
  State<ArcStopwatch> createState() => _ArcStopwatchState();
}

class _ArcStopwatchState extends State<ArcStopwatch> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Duration _currentTime, _totalTime;
  late TimerStatus _timerStatus;
  bool _isRunning = false, _isFinished = false, _isPreparationReady = true;
  late int _currentRound;

  @override
  void initState() {
    _currentRound = widget.timerParams.rounds;
    _totalTime = widget.timerParams.preparationTime +
        widget.timerParams.roundTime * widget.timerParams.rounds +
        widget.timerParams.restTime * (widget.timerParams.rounds - 1);
    _timerStatus = TimerStatus.preparation;
    _setTimerForDurationAndStart(widget.timerParams.preparationTime);
    super.initState();
  }

  void _setTimerForDurationAndStart(Duration duration) {
    _currentTime = duration;
    _controller = AnimationController(
      vsync: this,
      duration: duration,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        final oldTime = _currentTime;
        setState(() {
          _currentTime = Duration(
            milliseconds: (duration.inMilliseconds * (1 - _animation.value)).round(),
          );
          _totalTime = _totalTime - Duration(milliseconds: oldTime.inMilliseconds - _currentTime.inMilliseconds);
          if (_currentTime.inSeconds <= 3 && _isPreparationReady) {
            getIt<AudioManager>().playPreparationSound();
            _isPreparationReady = false;
          }
        });
      });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Reset the stopwatch when the animation completes
        setState(() {
          _isRunning = false;
        });
        _controller.reset();
        _isPreparationReady = true;
        getIt<AudioManager>().playRoundFinishSound();
        _checkForNextTimer();
      }
    });

    _controller.forward(from: _animation.value);
    _isRunning = true;
  }

  void _checkForNextTimer() {
    switch (_timerStatus) {
      case TimerStatus.preparation:
        _setTimerForDurationAndStart(widget.timerParams.roundTime);
        _timerStatus = TimerStatus.round;
        break;
      case TimerStatus.round:
        _currentRound--;
        if (_currentRound > 0) {
          _totalTime -= widget.timerParams.roundTime;
          _setTimerForDurationAndStart(widget.timerParams.restTime);
          _timerStatus = TimerStatus.rest;
        } else {
          _timerStatus = TimerStatus.finished;
          _controller.reset();
          _currentTime = Duration.zero;
          _totalTime = Duration.zero;
          _isFinished = true;
        }
        break;
      case TimerStatus.rest:
        _totalTime -= widget.timerParams.restTime;
        _setTimerForDurationAndStart(widget.timerParams.roundTime);
        _timerStatus = TimerStatus.round;
        break;
      case TimerStatus.finished:
        break;
    }
    printLog("Current status is: $_timerStatus and round: $_currentRound");
  }

  void _toggleStartStop() {
    if (!_isFinished) {
      setState(() {
        if (_isRunning) {
          _controller.stop();
        } else {
          _controller.forward(from: _animation.value);
        }
        _isRunning = !_isRunning;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerStyle = Theme.of(context).extension<TimerStyle>()!;
    Color progressColor;
    if (_animation.value <= 0.90) {
      progressColor = Color.lerp(timerStyle.progressTextTimeStartColor, timerStyle.progressTextTimeEndColor, (_animation.value - 0.80) / 0.10)!;
    } else {
      progressColor = timerStyle.progressTextTimeEndColor;
    }
    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(seconds: 2),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: _getBackgroundColorByStatus(timerStyle),
        ),
        Visibility(
          visible: _timerStatus != TimerStatus.finished,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Gap(50),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Card(
                        color: timerStyle.roundsCountColor,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'Round $_currentRound',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap(20),
                    Expanded(
                      child: Card(
                        color: timerStyle.roundColor,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              _totalTime.asMinutesAndSeconds,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: _toggleStartStop,
                child: Container(
                  width: MediaQuery.of(context).size.width / 1.5,
                  height: MediaQuery.of(context).size.width / 1.5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: CustomPaint(
                    painter: ArcPainter(
                      progress: _animation.value,
                      progressColor1: timerStyle.progressTimer1Color,
                      progressColor2: timerStyle.progressTimer2Color,
                      progressColor3: timerStyle.progressTimer3Color,
                      progressColor4: timerStyle.progressTimer4Color,
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _currentTime.asMinutesAndSeconds,
                          style: TextStyle(fontSize: 40, color: progressColor),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Visibility(
          visible: _timerStatus == TimerStatus.round,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Lottie.asset(
              'assets/animation/round_animation.lottie',
              decoder: customDecoder,
              height: 200,
            ),
          ),
        ),
        Visibility(
          visible: _timerStatus == TimerStatus.preparation || _timerStatus == TimerStatus.rest,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Lottie.asset(
              'assets/animation/prepare_animation.lottie',
              decoder: customDecoder,
              height: 200,
            ),
          ),
        ),
        Visibility(
          visible: _timerStatus == TimerStatus.finished,
          child: Align(
            alignment: Alignment.center,
            child: Lottie.asset(
              'assets/animation/finish_animation.lottie',
              decoder: customDecoder,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColorByStatus(TimerStyle style) {
    switch (_timerStatus) {
      case TimerStatus.preparation:
        return style.preparationColor.withOpacity(0.6);
      case TimerStatus.round:
        return style.roundColor.withOpacity(0.6);
      case TimerStatus.rest:
        return style.restColor.withOpacity(0.6);
      case TimerStatus.finished:
        return style.finishColor.withOpacity(0.6);
    }
  }

  Future<LottieComposition?> customDecoder(List<int> bytes) {
    return LottieComposition.decodeZip(bytes, filePicker: (files) {
      return files.firstWhereOrNull((f) => f.name.startsWith('animations/') && f.name.endsWith('.json'));
    });
  }
}

class ArcPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor1;
  final Color progressColor2;
  final Color progressColor3;
  final Color progressColor4;

  ArcPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor1,
    required this.progressColor2,
    required this.progressColor3,
    required this.progressColor4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = backgroundColor;

    Color progressColor;
    if (progress <= 0.70) {
      progressColor = Color.lerp(progressColor1, progressColor3, progress / 0.70)!;
    } else if (progress <= 0.80) {
      progressColor = Color.lerp(progressColor3, progressColor3, (progress - 0.70) / 0.10)!;
    } else if (progress <= 0.90) {
      progressColor = Color.lerp(progressColor3, progressColor4, (progress - 0.80) / 0.10)!;
    } else {
      progressColor = progressColor4;
    }

    Paint progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    double radius = size.width / 2;
    Offset center = Offset(size.width / 2, size.height / 2);

    // Draw the background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.5 * 3.14,
      2 * 3.14,
      false,
      backgroundPaint,
    );

    // Draw the progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.5 * 3.14,
      2 * 3.14 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
