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
    _viewModel = TimerViewModel(widget.params, getIt(), getIt());
    // Keeps the screen on during a workout.
    WakelockPlus.enable();
  }

  // The localized title needs the context, which is not ready in initState.
  // The ViewModel ignores a second start.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel.start(notificationTitle: context.l10n.timerNotificationTitle);
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
      // Opaque so a tap anywhere on the screen pauses or resumes, even on empty areas.
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _viewModel.togglePauseResume,
        child: ValueListenableBuilder<TimerState>(
          valueListenable: _viewModel.state,
          builder: (context, state, _) {
            return switch (widget.params.style) {
              TimerStyle.ring => RingTimerView(state: state, onTogglePause: _viewModel.togglePauseResume),
              TimerStyle.fullColor => FullColorTimerView(state: state, onTogglePause: _viewModel.togglePauseResume),
              TimerStyle.roundsStrip => RoundsStripTimerView(state: state, onTogglePause: _viewModel.togglePauseResume),
            };
          },
        ),
      ),
    );
  }
}
