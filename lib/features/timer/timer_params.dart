import 'package:sport_timer/features/settings/timer_style.dart';

class TimerParams {
  final Duration preparationTime;
  final Duration roundTime;
  final Duration restTime;
  final int rounds;
  final TimerStyle style;

  const TimerParams({
    required this.preparationTime,
    required this.roundTime,
    required this.restTime,
    required this.rounds,
    required this.style,
  });
}
