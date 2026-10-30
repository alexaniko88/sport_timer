part of 'timer.dart';

class TimerPage extends StatefulWidget {
  final TimerParams params;

  const TimerPage({
    super.key,
    required this.params,
  });

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  late final TimerViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TimerViewModel(widget.params, getIt())..start();
    // Keeps the screen on during a workout.
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Stopwatch(viewModel: _viewModel),
        ),
      ),
    );
  }
}
