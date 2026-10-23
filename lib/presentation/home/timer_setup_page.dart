part of 'home.dart';

class TimerSetupPage extends StatelessWidget {
  static const double _optionBorderWidth = 3;

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
    Duration? duration,
    int? maxMinutes,
    int? maxRounds,
    ValueChanged<Duration>? onDurationChanged,
    ValueChanged<int>? onRoundsChanged,
  }) {
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    return InkWell(
      onTap: () {
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
      borderRadius: BorderRadius.circular(AppRadius.r12),
      splashColor: color.withValues(alpha: 0.5),
      hoverColor: color.withValues(alpha: 0.5),
      focusColor: color.withValues(alpha: 0.5),
      highlightColor: color.withValues(alpha: 0.5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(
            color: color,
            width: _optionBorderWidth,
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: titleStyle),
            Text(
              duration?.asMinutesAndSeconds ?? maxRounds?.toString() ?? '',
              style: titleStyle,
            ),
          ],
        ),
      ),
    );
  }
}
