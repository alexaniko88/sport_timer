import 'package:flutter/material.dart';
import 'package:sport_timer/core/extensions/duration_extension.dart';
import 'package:sport_timer/features/timer/domain/timer_status.dart';
import 'package:sport_timer/features/timer/presentation/extensions/color_scheme_extension.dart';
import 'package:sport_timer/features/timer/presentation/extensions/timer_status_extension.dart';
import 'package:sport_timer/features/timer/presentation/timer_state.dart';
import 'package:sport_timer/features/timer/presentation/widgets/timer_phase.dart';
import 'package:sport_timer/features/timer/presentation/widgets/timer_ring.dart';
import 'package:sport_timer/shared/presentation/extensions/l10n_context.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';
import 'package:sport_timer/shared/presentation/theme/app_text_styles.dart';

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

    final phase = state.timerStatus.phase(context);
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
                      trackColor: colorScheme.timerTrack(phase.color),
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
