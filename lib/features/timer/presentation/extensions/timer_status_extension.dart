import 'package:flutter/material.dart';
import 'package:sport_timer/features/timer/domain/timer_status.dart';
import 'package:sport_timer/features/timer/presentation/widgets/timer_phase.dart';
import 'package:sport_timer/shared/presentation/extensions/l10n_context.dart';
import 'package:sport_timer/shared/presentation/extensions/theme_context.dart';

extension TimerStatusPhase on TimerStatus {
  /// The label and colors of this status, shared by all timer views.
  TimerPhase phase(BuildContext context) {
    final l10n = context.l10n;
    final timerColors = context.timerColors;

    return switch (this) {
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
}
