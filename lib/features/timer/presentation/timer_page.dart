import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/settings/domain/timer_style.dart';
import 'package:sport_timer/features/timer/domain/timer_params.dart';
import 'package:sport_timer/features/timer/domain/timer_activity_recorder.dart';
import 'package:sport_timer/features/timer/domain/timer_status.dart';
import 'package:sport_timer/features/timer/presentation/timer_state.dart';
import 'package:sport_timer/features/timer/presentation/timer_view_model.dart';
import 'package:sport_timer/features/timer/presentation/widgets/full_color_timer_view.dart';
import 'package:sport_timer/features/timer/presentation/widgets/ring_timer_view.dart';
import 'package:sport_timer/features/timer/presentation/widgets/rounds_strip_timer_view.dart';
import 'package:sport_timer/shared/presentation/extensions/l10n_context.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class TimerPage extends StatefulWidget {
  final TimerParams params;

  const TimerPage({
    super.key,
    required this.params,
  });

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  late final TimerViewModel _viewModel;
  bool _startFailed = false;
  bool _screenKeptOn = false;

  @override
  void initState() {
    super.initState();
    _viewModel = TimerViewModel(widget.params, getIt(), getIt(), activityRecorder: getIt<TimerActivityRecorder>());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _viewModel.reconcileProgress();
  }

  // The localized title needs the context, which is not ready in initState.
  // The ViewModel ignores a second start.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = context.l10n;
    final started = _viewModel.start(
      notificationTitle: l10n.timerNotificationTitle,
      notificationTextBuilder: (state) {
        final round = '${l10n.timerPhaseRound} ${l10n.timerRoundNumberOf(state.currentRound, state.totalRounds)}';
        return switch (state.timerStatus) {
          TimerStatus.preparation => l10n.timerPhasePreparation,
          TimerStatus.round => round,
          TimerStatus.rest => '$round · ${l10n.timerPhaseRest}',
          TimerStatus.finished => l10n.timerPhaseFinished,
        };
      },
    );
    _startFailed = !started;
    if (started && !_screenKeptOn) {
      _screenKeptOn = true;
      WakelockPlus.enable();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_screenKeptOn) WakelockPlus.disable();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_startFailed) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Could not start the workout. Check your account and try again.',
                  textAlign: TextAlign.center,
                ),
                TextButton(onPressed: () => context.pop(), child: const Text('Back')),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      // Opaque so a tap anywhere on the screen pauses or resumes, even on empty areas.
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _viewModel.togglePauseResume,
        child: ValueListenableBuilder<TimerState>(
          valueListenable: _viewModel.state,
          builder: (context, state, _) {
            return switch (widget.params.style) {
              TimerStyle.ring => RingTimerView(state: state, onTogglePause: _viewModel.togglePauseResume),
              TimerStyle.fullColor => FullColorTimerView(state: state, onTogglePause: _viewModel.togglePauseResume),
              TimerStyle.roundsStrip => RoundsStripTimerView(state: state, onTogglePause: _viewModel.togglePauseResume),
            };
          },
        ),
      ),
    );
  }
}
