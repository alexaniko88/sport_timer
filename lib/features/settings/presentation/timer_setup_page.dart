import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sport_timer/core/extensions/duration_extension.dart';
import 'package:sport_timer/features/account/presentation/account_avatar_button.dart';
import 'package:sport_timer/features/account/presentation/account_view_model.dart';
import 'package:sport_timer/features/settings/domain/timer_settings.dart';
import 'package:sport_timer/features/settings/presentation/settings_state.dart';
import 'package:sport_timer/features/settings/presentation/settings_view_model.dart';
import 'package:sport_timer/features/templates/presentation/extensions/template_names_extension.dart';
import 'package:sport_timer/features/settings/presentation/widgets/timer_setting_card.dart';
import 'package:sport_timer/features/settings/presentation/widgets/timer_settings_picker_wheel.dart';
import 'package:sport_timer/features/timer/domain/timer_params.dart';
import 'package:sport_timer/features/timer/domain/timer_schedule.dart';
import 'package:sport_timer/shared/presentation/extensions/l10n_context.dart';
import 'package:sport_timer/shared/presentation/extensions/text_theme_extension.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';
import 'package:sport_timer/shared/presentation/extensions/theme_context.dart';
import 'package:sport_timer/shared/presentation/widgets/app_button.dart';
import 'package:sport_timer/shared/presentation/widgets/app_surface.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                        child: Semantics(
                          button: true,
                          child: AppSurface(
                            onTap: onTemplatesPressed,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s16,
                              vertical: AppSpacing.s16,
                            ),
                            child: Text(
                              l10n.setupTemplateLabel(l10n.templateName(id)),
                              style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.primary),
                            ),
                          ),
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
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
        child: AppSurface(
          onTap: onStartPressed,
          excludeFromSemantics: true,
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: ExcludeSemantics(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.setupSessionLength,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.emphasizedLabel.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Text(
                      formattedDuration,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.tileValue,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s8),
                ExcludeFocus(
                  child: IgnorePointer(
                    child: FilledButtonTheme(
                      // A local button theme replaces the app one, so keep its shape and only change the size, padding, text, and icon.
                      data: FilledButtonThemeData(
                        style: (theme.filledButtonTheme.style ?? FilledButton.styleFrom()).copyWith(
                          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(
                              horizontal: AppSpacing.s24,
                              vertical: AppSpacing.s8,
                            ),
                          ),
                          textStyle: WidgetStatePropertyAll(textTheme.tileValue),
                          iconSize: const WidgetStatePropertyAll(AppSpacing.s40),
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
    );
  }
}
