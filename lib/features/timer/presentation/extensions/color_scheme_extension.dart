import 'package:flutter/material.dart';
import 'package:sport_timer/features/timer/presentation/widgets/timer_phase.dart';

extension TimerColorScheme on ColorScheme {
  /// The unfilled part of the ring: the phase color faded over the surface.
  Color timerTrack(Color phaseColor) {
    return Color.alphaBlend(phaseColor.withValues(alpha: TimerAlpha.track), surface);
  }

  /// The unfilled round segment: the text color faded over the surface.
  Color get timerEmptySegment {
    return Color.alphaBlend(onSurface.withValues(alpha: TimerAlpha.emptySegment), surface);
  }
}
