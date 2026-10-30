part of '../timer.dart';

class RoundsStripTimerView extends StatelessWidget {
  final TimerState state;
  final VoidCallback onTogglePause;

  const RoundsStripTimerView({
    super.key,
    required this.state,
    required this.onTogglePause,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final roundColor = context.timerColors.round;
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
                          TimerPhasePill(phase: phase),
                          TimerRoundNumber(state: state, color: phase.color),
                        ],
                      ),
                      TimerTimeText(
                        seconds: state.currentSeconds,
                        isPaused: state.isPaused,
                        style: AppTextStyles.roundsStripTime.copyWith(color: phase.color),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _RoundsStrip(
                            state: state,
                            color: roundColor,
                          ),
                          const SizedBox(height: AppSpacing.s12),
                          if (isFinished) ...[
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
                          ] else
                            Text(
                              l10n.timerTimeLeft(totalTime),
                              textAlign: TextAlign.center,
                              style: infoStyle,
                            ),
                        ],
                      ),
                      TimerPauseButton(
                        state: state,
                        phase: phase,
                        onPressed: onTogglePause,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One segment per round, filled only while its round runs.
class _RoundsStrip extends StatelessWidget {
  static const double _segmentHeight = 10;
  // Segments and gaps share the width by flex, so even the maximum number of rounds fits with no overflow.
  static const int _segmentFlex = 5;
  static const int _gapFlex = 1;

  final TimerState state;
  final Color color;

  const _RoundsStrip({
    required this.state,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final emptyColor = timerEmptySegmentColor(Theme.of(context).colorScheme);

    // Hidden when finished, but it keeps its space so the layout does not jump.
    return Visibility(
      visible: state.timerStatus != TimerStatus.finished,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var index = 0; index < state.totalRounds; index++) ...[
              if (index > 0) const Spacer(flex: _gapFlex),
              Expanded(
                flex: _segmentFlex,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_segmentHeight / 2),
                  child: SizedBox(
                    height: _segmentHeight,
                    child: ColoredBox(
                      color: emptyColor,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: state.roundFill(index + 1),
                          heightFactor: 1,
                          child: ColoredBox(color: color),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
