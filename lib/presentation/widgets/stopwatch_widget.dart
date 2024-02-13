import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';

class ArcStopwatch extends StatefulWidget {
  final Duration duration;

  ArcStopwatch({required this.duration});

  @override
  _ArcStopwatchState createState() => _ArcStopwatchState();
}

class _ArcStopwatchState extends State<ArcStopwatch>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Duration _currentTime;
  bool isRunning = false;

  final AssetsAudioPlayer _audioPlayer = AssetsAudioPlayer();

  @override
  void initState() {
    super.initState();
    _currentTime = widget.duration;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {
          _currentTime = Duration(
              milliseconds:
                  (widget.duration.inMilliseconds * (1 - _animation.value))
                      .round());
        });
      });

    // Set up the animation curve (linear for simplicity, can be changed as needed)
    _controller
      ..addListener(() {})
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // Reset the stopwatch when the animation completes
          setState(() {
            _currentTime = widget.duration;
            isRunning = false;
          });
          // Play a sound when the timer finishes
          _playSound();
        }
      });
  }

  Future<void> _playSound() async {
    await _audioPlayer.open(Audio('assets/bell_ring.mp3'));
    await _audioPlayer.play();
  }

  void _toggleStartStop() {
    setState(() {
      if (isRunning) {
        _controller.stop();
      } else {
        _controller.forward(from: _animation.value);
      }
      isRunning = !isRunning;
    });
  }

  void _restartTimer() {
    setState(() {
      _currentTime = widget.duration;
      _controller.reset();
      isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _toggleStartStop,
          child: Container(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: ArcPainter(_animation.value),
              child: Center(
                child: Text(
                  '${_currentTime.inMinutes}:${(_currentTime.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        Row(
          children: [
            ElevatedButton(
              onPressed: _toggleStartStop,
              child: Text(isRunning ? 'Stop' : 'Start'),
            ),
            ElevatedButton(
              onPressed: _restartTimer,
              child: Text('Restart'),
            ),
          ],
        ),
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

  ArcPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    double radius = size.width / 2;
    Offset center = Offset(size.width / 2, size.height / 2);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.5 * 3.14,
      2 * 3.14 * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
