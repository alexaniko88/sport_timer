part of '../timer.dart';

class RingTimerView extends StatelessWidget {
  static const double _ringSize = 280;
  static const double _ringStrokeWidth = 16;

  final TimerState state;
  final VoidCallback onTogglePause;

  const RingTimerView({
    super.key,
    required this.state,
    required this.onTogglePause,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final infoStyle = AppTextStyles.timerInfo.copyWith(color: colorScheme.onSurface.withValues(alpha: TimerAlpha.info));

    final phase = timerPhaseFor(context, state.timerStatus);
    final totalTime = state.totalTime.asMinutesAndSeconds;
    final isFinished = state.timerStatus == TimerStatus.finished;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TimerPhasePill(phase: phase),
                    TimerRoundNumber(state: state, color: colorScheme.onSurface),
                    const SizedBox(height: AppSpacing.s32),
                    TimerRing(
                      progress: state.stageProgress,
                      size: _ringSize,
                      strokeWidth: _ringStrokeWidth,
                      color: phase.color,
                      trackColor: timerTrackColor(phase.color, colorScheme),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s32),
                        child: TimerTimeText(
                          seconds: state.currentSeconds,
                          isPaused: state.isPaused,
                          style: AppTextStyles.stopwatchTime,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s32),
                    if (isFinished) Text(l10n.timerRoundsDone(state.totalRounds), style: infoStyle),
                    Text(
                      l10n.timerTotal(totalTime),
                      style: infoStyle,
                    ),
                    const SizedBox(height: AppSpacing.s32),
                    TimerPauseButton(
                      state: state,
                      phase: phase,
                      onPressed: onTogglePause,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
