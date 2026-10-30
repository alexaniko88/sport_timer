part of '../timer.dart';

class Stopwatch extends StatelessWidget {
  static const double _ringSize = 280;
  static const double _ringStrokeWidth = 16;
  static const double _buttonSize = 72;
  static const double _buttonIconSize = 36;
  static const double _trackAlpha = 0.25;
  static const double _infoAlpha = 0.6;
  static const double _pausedOpacity = 0.4;

  final TimerViewModel viewModel;

  const Stopwatch({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final timerColors = context.timerColors;
    final colorScheme = Theme.of(context).colorScheme;
    final infoStyle = AppTextStyles.timerInfo.copyWith(color: colorScheme.onSurface.withValues(alpha: _infoAlpha));
    return ValueListenableBuilder<TimerState>(
      valueListenable: viewModel.state,
      builder: (context, state, _) {
        final (label, color, onColor) = switch (state.timerStatus) {
          TimerStatus.preparation => (l10n.timerPhasePreparation, timerColors.preparation, timerColors.onPhase),
          TimerStatus.round => (l10n.timerPhaseRound, timerColors.round, timerColors.onPhase),
          TimerStatus.rest => (l10n.timerPhaseRest, timerColors.rest, timerColors.onPhase),
          TimerStatus.finished => (l10n.timerPhaseFinished, timerColors.finished, timerColors.onFinished),
        };
        final isFinished = state.timerStatus == TimerStatus.finished;
        final totalTime = Duration(seconds: state.totalSeconds).asMinutesAndSeconds;

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: ShapeDecoration(
                          color: color,
                          shape: const StadiumBorder(),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s24,
                            vertical: AppSpacing.s8,
                          ),
                          child: Text(
                            label.toUpperCase(),
                            style: AppTextStyles.timerPhase.copyWith(color: onColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s32),
                      GestureDetector(
                        onTap: isFinished ? null : viewModel.togglePauseResume,
                        child: TimerRing(
                          progress: state.stageProgress,
                          size: _ringSize,
                          strokeWidth: _ringStrokeWidth,
                          color: color,
                          trackColor: Color.alphaBlend(color.withValues(alpha: _trackAlpha), colorScheme.surface),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.s32),
                            child: Opacity(
                              opacity: state.isPaused ? _pausedOpacity : 1,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  Duration(seconds: state.currentSeconds).asMinutesAndSeconds,
                                  style: AppTextStyles.stopwatchTime,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s32),
                      Text(
                        l10n.timerRoundOf(state.currentRound, state.totalRounds),
                        style: infoStyle,
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        l10n.timerTotal(totalTime),
                        style: infoStyle,
                      ),
                      const SizedBox(height: AppSpacing.s32),
                      // Keeps the space when finished so the layout does not jump.
                      Visibility(
                        visible: !isFinished,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: IconButton.filled(
                          tooltip: state.isPaused ? l10n.timerResume : l10n.timerPause,
                          onPressed: viewModel.togglePauseResume,
                          iconSize: _buttonIconSize,
                          style: IconButton.styleFrom(
                            fixedSize: const Size.square(_buttonSize),
                            backgroundColor: color,
                            foregroundColor: onColor,
                          ),
                          icon: Icon(state.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
