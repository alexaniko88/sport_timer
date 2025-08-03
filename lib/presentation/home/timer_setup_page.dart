part of 'home.dart';

class TimerSetupPage extends StatelessWidget {
  const TimerSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final timerStyle = Theme.of(context).extension<TimerStyle>()!;

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final settings = state.timerSettings!;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: const Text('Prepared for the new challenge?'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildOption(
                        context: context,
                        color: timerStyle.preparationColor,
                        timerStyle: timerStyle,
                        duration: settings.preparationTime,
                        label: "Preparation time",
                        maxMinutes: 5,
                        picketType: PicketType.time,
                        onDurationChanged: (duration) {
                          context.read<SettingsCubit>().updatePreparationTime(duration);
                        },
                      ),
                      const Gap(20),
                      _buildOption(
                        context: context,
                        color: timerStyle.roundColor,
                        timerStyle: timerStyle,
                        duration: settings.roundTime,
                        label: "Round time",
                        maxMinutes: 60,
                        picketType: PicketType.time,
                        onDurationChanged: (duration) {
                          context.read<SettingsCubit>().updateRoundTime(duration);
                        },
                      ),
                      const Gap(20),
                      _buildOption(
                        context: context,
                        color: timerStyle.restColor,
                        timerStyle: timerStyle,
                        duration: settings.restTime,
                        label: "Rest time",
                        maxMinutes: 60,
                        picketType: PicketType.time,
                        onDurationChanged: (duration) {
                          context.read<SettingsCubit>().updateRestTime(duration);
                        },
                      ),
                      const Gap(20),
                      _buildOption(
                        context: context,
                        color: timerStyle.roundsCountColor,
                        timerStyle: timerStyle,
                        label: "Rounds",
                        maxRounds: settings.rounds,
                        picketType: PicketType.rounds,
                        onRoundsChanged: (rounds) {
                          context.read<SettingsCubit>().updateRounds(rounds);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: FloatingActionButton.large(
            onPressed: state.status == SettingsStatus.saving
                ? null
                : () {
                    context.read<SettingsCubit>().saveSettings(settings);
                    context.pushNamed(
                      RoutePath.timer.value,
                      extra: TimerParams(
                        preparationTime: settings.preparationTime,
                        roundTime: settings.roundTime,
                        restTime: settings.restTime,
                        rounds: settings.rounds,
                      ),
                    );
                  },
            child: state.status == SettingsStatus.saving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.timer),
          ),
        );
      },
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required TimerStyle timerStyle,
    required PicketType picketType,
    required Color color,
    required String label,
    Duration? duration,
    int? maxMinutes,
    int? maxRounds,
    Function(Duration duration)? onDurationChanged,
    Function(int rounds)? onRoundsChanged,
  }) {
    return InkWell(
      onTap: () {
        TimerSettingsPicker.show(
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
      borderRadius: BorderRadius.circular(12),
      splashColor: color.withValues(alpha: 0.5),
      hoverColor: color.withValues(alpha: 0.5),
      focusColor: color.withValues(alpha: 0.5),
      highlightColor: color.withValues(alpha: 0.5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color,
            width: 3,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 20)),
            Text(
              duration?.asMinutesAndSeconds ?? maxRounds?.toString() ?? '',
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
