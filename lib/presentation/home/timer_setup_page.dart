part of 'home.dart';

class TimerSetupPage extends StatelessWidget {
  final SettingsViewModel viewModel;
  final AccountViewModel accountViewModel;
  final VoidCallback onMenuPressed;
  final VoidCallback onTemplatesPressed;
  final VoidCallback onStartPressed;

  const TimerSetupPage({
    super.key,
    required this.viewModel,
    required this.accountViewModel,
    required this.onMenuPressed,
    required this.onTemplatesPressed,
    required this.onStartPressed,
  });

  @override
  Widget build(BuildContext context) {
    final timerColors = context.timerColors;
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<SettingsState>(
      valueListenable: viewModel.state,
      builder: (context, state, _) {
        final settings = state.timerSettings;
        final duration = TimerSchedule.fromParams(
          TimerParams(
            preparationTime: settings.preparationTime,
            roundTime: settings.roundTime,
            restTime: settings.restTime,
            rounds: settings.rounds,
            style: state.timerStyle,
          ),
        ).totalDuration;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: l10n.homeMenuTooltip,
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu),
            ),
            title: Text(l10n.timerSetupTitle),
            actions: [
              AccountAvatarButton(viewModel: accountViewModel),
              const SizedBox(width: AppSpacing.s8),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    AppSpacing.s16,
                    AppSpacing.s16,
                    AppSpacing.s16,
                  ),
                  children: [
                    if (state.selectedTemplateId case final id?) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: onTemplatesPressed,
                          style: TextButton.styleFrom(
                            backgroundColor: colorScheme.surfaceContainer,
                            side: BorderSide(color: colorScheme.outlineVariant),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.r12),
                            ),
                          ),
                          child: Text(l10n.setupTemplateLabel(_templateName(context, id))),
                        ),
                      ),
                      const Gap(AppSpacing.s8),
                    ],
                    TimerSettingGrid(
                      children: [
                        _buildOption(
                          context: context,
                          color: timerColors.preparation,
                          duration: settings.preparationTime,
                          label: l10n.setupPreparation,
                          icon: Icons.hourglass_top,
                          maxMinutes: 5,
                          picketType: PicketType.time,
                          onDurationChanged: (duration) {
                            viewModel.updatePreparationTime(duration);
                          },
                        ),
                        _buildOption(
                          context: context,
                          color: timerColors.round,
                          duration: settings.roundTime,
                          label: l10n.setupWork,
                          icon: Icons.fitness_center,
                          minDuration: const Duration(seconds: 1),
                          maxMinutes: 60,
                          picketType: PicketType.time,
                          onDurationChanged: (duration) {
                            viewModel.updateRoundTime(duration);
                          },
                        ),
                        _buildOption(
                          context: context,
                          color: timerColors.rest,
                          duration: settings.restTime,
                          label: l10n.setupRest,
                          icon: Icons.self_improvement,
                          maxMinutes: 60,
                          picketType: PicketType.time,
                          onDurationChanged: (duration) {
                            viewModel.updateRestTime(duration);
                          },
                        ),
                        _buildOption(
                          context: context,
                          color: timerColors.roundsCount,
                          label: l10n.commonRounds,
                          icon: Icons.repeat,
                          rounds: settings.rounds,
                          picketType: PicketType.rounds,
                          onRoundsChanged: (rounds) {
                            viewModel.updateRounds(rounds);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _SessionOverview(
                duration: duration,
                onStartPressed: onStartPressed,
              ),
            ],
          ),
        );
      },
    );
  }

  TimerSettingCard _buildOption({
    required BuildContext context,
    required PicketType picketType,
    required Color color,
    required String label,
    required IconData icon,
    Duration? duration,
    Duration? minDuration,
    int? maxMinutes,
    int? rounds,
    ValueChanged<Duration>? onDurationChanged,
    ValueChanged<int>? onRoundsChanged,
  }) {
    final l10n = context.l10n;

    return TimerSettingCard(
      label: label,
      icon: icon,
      semanticHint: l10n.commonOpensSelectorHint,
      value: duration?.asMinutesAndSeconds ?? rounds?.toString() ?? '',
      iconColor: color,
      onPressed: () async {
        await TimerSettingsPickerWheel.show(
          context: context,
          picketType: picketType,
          initialDuration: duration,
          minDuration: minDuration ?? Duration.zero,
          maxMinutes: maxMinutes ?? 60,
          rounds: rounds ?? 2,
          maxRounds: TimerSettings.maxRounds,
          buttonsColor: color,
          onDurationChanged: onDurationChanged,
          onRoundsChanged: onRoundsChanged,
        );
        await viewModel.flushSettings();
      },
    );
  }
}

class _SessionOverview extends StatelessWidget {
  final Duration duration;
  final VoidCallback onStartPressed;

  const _SessionOverview({required this.duration, required this.onStartPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.r12);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final formattedDuration = hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s16),
      child: Semantics(
        button: true,
        label: l10n.homeStartButton,
        value: '${l10n.setupSessionLength}: $formattedDuration',
        onTap: onStartPressed,
        child: Material(
          color: colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: InkWell(
            onTap: onStartPressed,
            excludeFromSemantics: true,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(l10n.setupSessionLength)),
                        const SizedBox(width: AppSpacing.s8),
                        Text(formattedDuration),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    ExcludeFocus(
                      child: IgnorePointer(
                        child: FilledButtonTheme(
                          data: FilledButtonThemeData(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(borderRadius: radius),
                            ),
                          ),
                          child: AppButton.primary(
                            label: l10n.homeStartButton,
                            icon: const Icon(Icons.play_arrow),
                            onPressed: onStartPressed,
                            isExpanded: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
