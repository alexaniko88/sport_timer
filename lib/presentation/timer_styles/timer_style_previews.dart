part of 'timer_styles.dart';

/// A small static phone-shaped preview of a timer style: the real timer view, shrunk.
class TimerStylePreview extends StatelessWidget {
  static const double _width = 90;
  static const double _height = 160;
  static const double _borderWidth = 2;
  // The logical phone size the real view is laid out at, before it is scaled down.
  static const Size _phoneSize = Size(360, 640);
  static const TimerState _sampleState = TimerState(
    currentSeconds: 90,
    totalSeconds: 1000,
    currentRound: 3,
    totalRounds: 8,
    stageSeconds: 150,
    totalDuration: Duration(seconds: 2400),
    timerStatus: TimerStatus.round,
  );

  final TimerStyle style;

  const TimerStylePreview({
    super.key,
    required this.style,
  });

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(AppRadius.r20);

    return Container(
      width: _width,
      height: _height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: borderRadius,
      ),
      // Painted over the content, so the square corners of the view never cover the border.
      foregroundDecoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: colorScheme.outline, width: _borderWidth),
      ),
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox.fromSize(
              size: _phoneSize,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: _phoneSize,
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                  viewInsets: EdgeInsets.zero,
                ),
                // The real views use buttons, which need a Material ancestor.
                child: Material(
                  type: MaterialType.transparency,
                  child: switch (style) {
                    TimerStyle.ring => const RingTimerView(state: _sampleState, onTogglePause: _noop),
                    TimerStyle.fullColor => const FullColorTimerView(state: _sampleState, onTogglePause: _noop),
                    TimerStyle.roundsStrip => const RoundsStripTimerView(state: _sampleState, onTogglePause: _noop),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
