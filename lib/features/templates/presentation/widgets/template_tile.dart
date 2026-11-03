import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sport_timer/shared/presentation/extensions/l10n_context.dart';
import 'package:sport_timer/features/settings/domain/timer_settings.dart';
import 'package:sport_timer/l10n/app_localizations.dart';
import 'package:sport_timer/shared/presentation/extensions/text_theme_extension.dart';
import 'package:sport_timer/shared/presentation/theme/app_alpha.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';
import 'package:sport_timer/shared/presentation/widgets/app_surface.dart';
import 'package:sport_timer/shared/presentation/extensions/theme_context.dart';

class TemplateTile extends StatelessWidget {
  static const double _phaseBarHeight = 6;

  final String name;
  final IconData icon;
  final TimerSettings settings;
  final Duration totalTime;
  final bool isSelected;
  final bool isCustom;
  final VoidCallback? onTap;

  const TemplateTile({
    super.key,
    required this.name,
    required this.icon,
    required this.settings,
    required this.totalTime,
    this.isSelected = false,
    this.isCustom = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final total = _formatDuration(l10n: l10n, duration: totalTime);
    final customColor = context.timerColors.roundCounterBorder;

    final Color? background = isCustom && !isSelected
        ? Color.alphaBlend(customColor.withValues(alpha: AppAlpha.tint), colorScheme.surfaceContainer)
        : null;
    final Color? borderColor = isCustom ? customColor : null;

    return Semantics(
      container: true,
      button: onTap != null,
      selected: isCustom ? null : isSelected,
      onTap: onTap,
      excludeSemantics: true,
      label: isCustom
          ? l10n.templateCustomTileSemantics(
              _formatDuration(l10n: l10n, duration: settings.preparationTime),
              _formatDuration(l10n: l10n, duration: settings.roundTime),
              _formatDuration(l10n: l10n, duration: settings.restTime),
              settings.rounds,
              total,
            )
          : l10n.templateTileSemantics(
              name,
              _formatDuration(l10n: l10n, duration: settings.roundTime),
              _formatDuration(l10n: l10n, duration: settings.restTime),
              settings.rounds,
              total,
            ),
      child: AppSurface(
        surfaceKey: const Key('template-tile-surface'),
        isSelected: isSelected,
        color: background,
        borderColor: borderColor,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary),
                const Gap(AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.tileTitle,
                      ),
                      Text(
                        isCustom
                            ? l10n.templateCustomTileSummary(
                                _formatClock(settings.preparationTime),
                                _formatClock(settings.roundTime),
                                _formatClock(settings.restTime),
                                settings.rounds,
                              )
                            : l10n.templateTileSummary(
                                _formatClock(settings.roundTime),
                                _formatClock(settings.restTime),
                                settings.rounds,
                              ),
                        maxLines: isCustom ? null : 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.tileSecondary.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const Gap(AppSpacing.s8),
                Visibility(
                  visible: isSelected,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Icon(Icons.check_circle, color: colorScheme.primary),
                ),
                const Gap(AppSpacing.s8),
                Text(
                  total,
                  maxLines: 1,
                  softWrap: false,
                  style: textTheme.tileTitle,
                ),
              ],
            ),
            const Gap(AppSpacing.s12),
            _PhaseBar(settings: settings),
          ],
        ),
      ),
    );
  }

  String _formatClock(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatDuration({required AppLocalizations l10n, required Duration duration}) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return l10n.durationHoursMinutesSeconds(hours, minutes, seconds);
    } else if (minutes > 0) {
      return l10n.durationMinutesSeconds(minutes, seconds);
    } else {
      return l10n.durationSeconds(seconds);
    }
  }
}

class _PhaseBar extends StatelessWidget {
  final TimerSettings settings;

  const _PhaseBar({required this.settings});

  @override
  Widget build(BuildContext context) {
    final colors = context.timerColors;
    final segments = <(Duration, Color)>[
      (settings.preparationTime, colors.preparation),
      for (var i = 0; i < settings.rounds; i++) ...[
        (settings.roundTime, colors.round),
        if (i < settings.rounds - 1) (settings.restTime, colors.rest),
      ],
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(TemplateTile._phaseBarHeight / 2),
      child: SizedBox(
        key: const Key('phase-bar'),
        height: TemplateTile._phaseBarHeight,
        child: Row(
          children: [
            for (final (duration, color) in segments)
              if (duration > Duration.zero)
                Expanded(
                  flex: duration.inMilliseconds,
                  child: ColoredBox(color: color),
                ),
          ],
        ),
      ),
    );
  }
}
