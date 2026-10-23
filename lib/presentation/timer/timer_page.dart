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
  static const double _progressBarHeight = 40;
  static const double _stopwatchTopInset = 100;

  late final TimerViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TimerViewModel(widget.params, getIt())..start();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerColors = context.timerColors;
    return Scaffold(
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            ValueListenableBuilder<TimerState>(
              valueListenable: _viewModel.state,
              builder: (context, state, _) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: _getBackgroundColorByStatus(
                    timerStatus: state.timerStatus,
                    timerColors: timerColors,
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: _stopwatchTopInset),
              child: Align(
                alignment: Alignment.topCenter,
                child: Stopwatch(viewModel: _viewModel),
              ),
            ),
            ValueListenableBuilder<TimerState>(
              valueListenable: _viewModel.state,
              builder: (context, state, _) {
                final progress = state.progress;
                return Visibility(
                  visible: state.timerStatus != TimerStatus.finished,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: LinearProgressIndicator(
                      value: progress,
                      color: _getProgressColor(
                        progress: progress,
                        timerColors: timerColors,
                      ),
                      backgroundColor: AppPalette.transparent,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(AppRadius.r4),
                        bottomRight: Radius.circular(AppRadius.r4),
                      ),
                      minHeight: _progressBarHeight,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColorByStatus({
    required TimerColors timerColors,
    required TimerStatus timerStatus,
  }) {
    return switch (timerStatus) {
      TimerStatus.preparation => timerColors.preparation.withValues(alpha: 0.2),
      TimerStatus.round => timerColors.round.withValues(alpha: 0.2),
      TimerStatus.rest => timerColors.rest.withValues(alpha: 0.2),
      TimerStatus.finished => timerColors.finished.withValues(alpha: 0.8),
    };
  }

  Color _getProgressColor({
    required double progress,
    required TimerColors timerColors,
  }) {
    return switch (progress) {
      <= 0.70 => Color.lerp(
          timerColors.progressStart,
          timerColors.progressMiddle,
          progress / 0.70,
        )!,
      <= 0.80 => timerColors.progressMiddle,
      <= 0.90 => Color.lerp(
          timerColors.progressMiddle,
          timerColors.progressEnd,
          (progress - 0.80) / 0.10,
        )!,
      _ => timerColors.progressEnd,
    };
  }
}
