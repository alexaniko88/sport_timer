import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:basic_flutter_helper/basic_flutter_helper.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

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
  bool _isRunning = false, _isFinished = false;
  late int _currentRound;

  final AssetsAudioPlayer _audioPlayer = AssetsAudioPlayer();

  @override
  void initState() {
    printLog("INITIALIZING!!");
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
          final timeDifference = oldTime.inMilliseconds - _currentTime.inMilliseconds;
          _totalTime = _totalTime - Duration(milliseconds: timeDifference);
        });
      });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Reset the stopwatch when the animation completes
        setState(() {
          _isRunning = false;
        });
        _controller.reset();
        _playSound();
        _checkForNextTimer();
      }
    });

    _controller.forward(from: _animation.value);
    _isRunning = true;
  }

  void _checkForNextTimer() {
    switch (_timerStatus) {
      case TimerStatus.preparation:
        _totalTime -= widget.timerParams.preparationTime;
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

  Future<void> _playSound() async {
    await _audioPlayer.open(Audio('assets/bell_ring.mp3'));
    await _audioPlayer.play();
  }

  void _toggleStartStop() {
    if(!_isFinished) {
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
    Color progressColor;
    if (_animation.value <= 0.90) {
      progressColor = Color.lerp(Colors.black, Colors.red, (_animation.value - 0.80) / 0.10)!;
    } else {
      progressColor = Colors.red;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: _toggleStartStop,
          child: SizedBox(
            width: MediaQuery.of(context).size.width / 1.5,
            height: MediaQuery.of(context).size.width / 1.5,
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width / 1.5),
              ),
              margin: EdgeInsets.zero,
              child: CustomPaint(
                painter: ArcPainter(
                  progress: _animation.value,
                  progressColor1: Colors.green,
                  progressColor2: Colors.yellow,
                  progressColor3: Colors.orange,
                  progressColor4: Colors.red,
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
        ),
        Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Card(
                    color: Colors.orangeAccent,
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
                    color: Colors.redAccent,
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
            const Gap(20),
            MaterialButton(
              onPressed: _toggleStartStop,
              color: Theme.of(context).colorScheme.primary,
              minWidth: MediaQuery.of(context).size.width / 2,
              height: MediaQuery.of(context).size.width / 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.pause,
                color: Colors.white,
                size: 50,
              ),
            ),
          ],
        )
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose(); // Don't forget to dispose of the audio player
    super.dispose();
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
