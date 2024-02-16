part of 'timer.dart';

class TimerPage extends StatelessWidget {
  const TimerPage({
    super.key,
    required this.timerParams,
  });

  final TimerParams timerParams;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ArcStopwatch(timerParams: timerParams),
    );
  }
}
