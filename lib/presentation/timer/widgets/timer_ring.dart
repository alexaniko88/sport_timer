part of '../timer.dart';

/// A ring that fills clockwise from the top, with [child] in the middle.
class TimerRing extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final Widget child;

  const TimerRing({
    super.key,
    required this.progress,
    required this.size,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _TimerRingPainter(
        progress: progress,
        strokeWidth: strokeWidth,
        color: color,
        trackColor: trackColor,
      ),
      child: SizedBox.square(
        dimension: size,
        child: Center(child: child),
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  static const double _startAngle = -math.pi / 2;
  static const double _fullCircle = 2 * math.pi;

  final double progress;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  const _TimerRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // The stroke is centred on the path, so the rect is inset by half of it to stay inside the box.
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, _fullCircle, false, paint..color = trackColor);
    if (progress > 0) {
      canvas.drawArc(rect, _startAngle, _fullCircle * progress, false, paint..color = color);
    }
  }

  @override
  bool shouldRepaint(_TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
