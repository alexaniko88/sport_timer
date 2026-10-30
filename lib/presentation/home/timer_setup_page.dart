part of 'home.dart';

class TimerSetupPage extends StatelessWidget {
  final SettingsViewModel viewModel;

  const TimerSetupPage({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final timerColors = context.timerColors;
    final l10n = context.l10n;

    return ValueListenableBuilder<SettingsState>(
      valueListenable: viewModel.state,
      builder: (context, state, _) {
        final settings = state.timerSettings;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.timerSetupTitle),
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildOption(
                        context: context,
                        color: timerColors.preparation,
                        duration: settings.preparationTime,
                        label: l10n.commonPreparationTime,
                        icon: Icons.hourglass_top,
                        maxMinutes: 5,
                        picketType: PicketType.time,
                        onDurationChanged: (duration) {
                          viewModel.updatePreparationTime(duration);
                        },
                      ),
                      const Gap(AppSpacing.s20),
                      _buildOption(
                        context: context,
                        color: timerColors.round,
                        duration: settings.roundTime,
                        label: l10n.commonRoundTime,
                        icon: Icons.fitness_center,
                        maxMinutes: 60,
                        picketType: PicketType.time,
                        onDurationChanged: (duration) {
                          viewModel.updateRoundTime(duration);
                        },
                      ),
                      const Gap(AppSpacing.s20),
                      _buildOption(
                        context: context,
                        color: timerColors.rest,
                        duration: settings.restTime,
                        label: l10n.commonRestTime,
                        icon: Icons.pause,
                        maxMinutes: 60,
                        picketType: PicketType.time,
                        onDurationChanged: (duration) {
                          viewModel.updateRestTime(duration);
                        },
                      ),
                      const Gap(AppSpacing.s20),
                      _buildOption(
                        context: context,
                        color: timerColors.roundsCount,
                        label: l10n.commonRounds,
                        icon: Icons.repeat,
                        maxRounds: settings.rounds,
                        picketType: PicketType.rounds,
                        onRoundsChanged: (rounds) {
                          viewModel.updateRounds(rounds);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required PicketType picketType,
    required Color color,
    required String label,
    required IconData icon,
    Duration? duration,
    int? maxMinutes,
    int? maxRounds,
    ValueChanged<Duration>? onDurationChanged,
    ValueChanged<int>? onRoundsChanged,
  }) {
    final l10n = context.l10n;

    return AppButton.option(
      label: label,
      icon: Icon(icon),
      semanticHint: l10n.commonOpensSelectorHint,
      value: duration?.asMinutesAndSeconds ?? maxRounds?.toString() ?? '',
      color: color,
      onPressed: () {
        TimerSettingsPickerWheel.show(
          context: context,
          picketType: picketType,
          initialDuration: duration,
          maxMinutes: maxMinutes ?? 60,
          maxRounds: maxRounds ?? 2,
          buttonsColor: color,
          onDurationChanged: onDurationChanged,
          onRoundsChanged: onRoundsChanged,
        );
      },
    );
  }
}
