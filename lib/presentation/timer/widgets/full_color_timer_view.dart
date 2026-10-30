part of '../timer.dart';

class FullColorTimerView extends StatelessWidget {
  final TimerState state;
  final VoidCallback onTogglePause;

  const FullColorTimerView({
    super.key,
    required this.state,
    required this.onTogglePause,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final phase = timerPhaseFor(context, state.timerStatus);
    final isFinished = state.timerStatus == TimerStatus.finished;
    final textColor = phase.onColor;
    final totalTime = state.totalTime.asMinutesAndSeconds;
    final infoStyle = AppTextStyles.timerInfo.copyWith(color: textColor, fontWeight: FontWeight.w500);

    return ColoredBox(
      color: phase.color,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExcludeSemantics(
            child: Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                heightFactor: isFinished ? 0 : state.stageProgress,
                widthFactor: 1,
                child: ColoredBox(color: Colors.black.withValues(alpha: TimerAlpha.curtain)),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16,
                          vertical: AppSpacing.s32,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  phase.label.toUpperCase(),
                                  style: AppTextStyles.fullColorPhase.copyWith(color: textColor),
                                ),
                                TimerRoundNumber(state: state, color: textColor),
                              ],
                            ),
                            Semantics(
                              container: true,
                              button: true,
                              label: state.isPaused ? l10n.timerResume : l10n.timerPause,
                              onTap: isFinished ? null : onTogglePause,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TimerTimeText(
                                    seconds: state.currentSeconds,
                                    isPaused: state.isPaused,
                                    style: AppTextStyles.fullColorTime.copyWith(color: textColor),
                                  ),
                                  const SizedBox(height: AppSpacing.s8),
                                  // Keeps the space when not paused so the layout does not jump.
                                  Visibility(
                                    visible: state.isPaused,
                                    maintainSize: true,
                                    maintainAnimation: true,
                                    maintainState: true,
                                    child: Text(l10n.timerPausedHint, style: infoStyle),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isFinished)
                                  Text(
                                    l10n.timerRoundsDone(state.totalRounds),
                                    textAlign: TextAlign.center,
                                    style: infoStyle,
                                  ),
                                Text(
                                  l10n.timerTotal(totalTime),
                                  textAlign: TextAlign.center,
                                  style: infoStyle,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
