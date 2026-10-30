part of '../timer.dart';

typedef TimerPhase = ({String label, Color color, Color onColor});

/// Alpha and opacity values shared by the timer views and the style previews.
abstract final class TimerAlpha {
  static const double paused = 0.4;
  static const double info = 0.6;
  static const double track = 0.25;
  static const double curtain = 0.40;
  static const double emptySegment = 0.14;
}

/// The unfilled part of the ring: the phase color faded over the surface.
Color timerTrackColor(Color phaseColor, ColorScheme colorScheme) {
  return Color.alphaBlend(phaseColor.withValues(alpha: TimerAlpha.track), colorScheme.surface);
}

/// The unfilled round segment: the text color faded over the surface.
Color timerEmptySegmentColor(ColorScheme colorScheme) {
  return Color.alphaBlend(colorScheme.onSurface.withValues(alpha: TimerAlpha.emptySegment), colorScheme.surface);
}

/// The label and colors of a timer status, shared by all timer views.
TimerPhase timerPhaseFor(BuildContext context, TimerStatus status) {
  final l10n = context.l10n;
  final timerColors = context.timerColors;

  return switch (status) {
    TimerStatus.preparation => (
        label: l10n.timerPhasePreparation,
        color: timerColors.preparation,
        onColor: timerColors.onPhase,
      ),
    TimerStatus.round => (
        label: l10n.timerPhaseRound,
        color: timerColors.round,
        onColor: timerColors.onPhase,
      ),
    TimerStatus.rest => (
        label: l10n.timerPhaseRest,
        color: timerColors.rest,
        onColor: timerColors.onPhase,
      ),
    TimerStatus.finished => (
        label: l10n.timerPhaseFinished,
        color: timerColors.finished,
        onColor: timerColors.onFinished,
      ),
  };
}

class TimerPhasePill extends StatelessWidget {
  final TimerPhase phase;

  const TimerPhasePill({
    super.key,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: phase.color,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s24,
          vertical: AppSpacing.s8,
        ),
        child: Text(
          phase.label.toUpperCase(),
          style: AppTextStyles.timerPhase.copyWith(color: phase.onColor),
        ),
      ),
    );
  }
}

/// The current round, as "N of M", under the phase label. It shows in the round and rest phases
/// (a rest shows the round that comes next) and always keeps its space so the layout does not jump.
class TimerRoundNumber extends StatelessWidget {
  final TimerState state;
  final Color color;

  const TimerRoundNumber({
    super.key,
    required this.state,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isShown = switch (state.timerStatus) {
      TimerStatus.round || TimerStatus.rest => true,
      TimerStatus.preparation || TimerStatus.finished => false,
    };

    return Visibility(
      visible: isShown,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.s8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            l10n.timerRoundNumberOf(state.currentRound, state.totalRounds),
            style: AppTextStyles.timerRoundNumber.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

class TimerPauseButton extends StatelessWidget {
  static const double _buttonSize = 72;
  static const double _buttonIconSize = 36;

  final TimerState state;
  final TimerPhase phase;
  final VoidCallback onPressed;

  const TimerPauseButton({
    super.key,
    required this.state,
    required this.phase,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Keeps the space when finished so the layout does not jump.
    return Visibility(
      visible: state.timerStatus != TimerStatus.finished,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: IconButton.filled(
        tooltip: state.isPaused ? l10n.timerResume : l10n.timerPause,
        onPressed: onPressed,
        iconSize: _buttonIconSize,
        style: IconButton.styleFrom(
          fixedSize: const Size.square(_buttonSize),
          backgroundColor: phase.color,
          foregroundColor: phase.onColor,
        ),
        icon: Icon(state.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
      ),
    );
  }
}

/// The time of the timer, dimmed while paused and scaled down to fit the width.
class TimerTimeText extends StatelessWidget {
  final int seconds;
  final bool isPaused;
  final TextStyle style;

  const TimerTimeText({
    super.key,
    required this.seconds,
    required this.isPaused,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isPaused ? TimerAlpha.paused : 1,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          Duration(seconds: seconds).asMinutesAndSeconds,
          style: style,
        ),
      ),
    );
  }
}
