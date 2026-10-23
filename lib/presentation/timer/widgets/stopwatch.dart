part of '../timer.dart';

class Stopwatch extends StatelessWidget {
  static const double _widthDivisor = 1.15;
  static const double _timeTop = 45;
  static const double _totalTop = 200;
  static const double _roundBorderWidth = 3;
  static const double _totalBorderWidth = 5;

  final TimerViewModel viewModel;

  const Stopwatch({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TimerState>(
      valueListenable: viewModel.state,
      builder: (context, state, _) {
        return GestureDetector(
          onTap: viewModel.togglePauseResume,
          child: SizedBox(
            width: MediaQuery.of(context).size.width / _widthDivisor,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.s12),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.r12),
                            border: Border.all(
                              color: context.timerColors.roundCounterBorder,
                              width: _roundBorderWidth,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.s8),
                            child: Text(
                              "${state.currentRound}",
                              style: AppTextStyles.stopwatchRound,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: _timeTop),
                      child: Text(
                        Duration(seconds: state.currentSeconds).asMinutesAndSeconds,
                        style: AppTextStyles.stopwatchTime,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: _totalTop),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.r12),
                            border: Border.all(
                              color: context.timerColors.totalTimeBorder,
                              width: _totalBorderWidth,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.s8),
                            child: Text(
                              Duration(seconds: state.totalSeconds).asMinutesAndSeconds,
                              style: AppTextStyles.stopwatchTotal,
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
        );
      },
    );
  }
}
