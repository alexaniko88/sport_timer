import 'package:flutter/material.dart';
import 'package:sport_timer/core/l10n_context.dart';
import 'package:sport_timer/features/settings/settings_repository.dart';
import 'package:sport_timer/l10n/app_localizations.dart';
import 'package:sport_timer/theme/app_spacing.dart';
import 'package:sport_timer/theme/theme_context.dart';

class TemplateTile extends StatelessWidget {
  static const double _phaseBarHeight = 6;
  static const double _selectedBorderWidth = 2;
  static const double _borderWidth = 1;

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
    final borderRadius = BorderRadius.circular(AppRadius.r12);
    final total = _formatDuration(l10n: l10n, duration: totalTime);

    final Color background;
    final Color borderColor;
    final double borderWidth;
    if (isSelected) {
      background = colorScheme.surfaceContainerHigh;
      borderColor = colorScheme.primary;
      borderWidth = _selectedBorderWidth;
    } else if (isCustom) {
      background = Colors.transparent;
      borderColor = colorScheme.outline;
      borderWidth = _borderWidth;
    } else {
      background = colorScheme.surfaceContainer;
      borderColor = colorScheme.outlineVariant;
      borderWidth = _borderWidth;
    }

    return Semantics(
      container: true,
      button: onTap != null,
      selected: isSelected,
      onTap: onTap,
      excludeSemantics: true,
      label: l10n.templateTileSemantics(
        name,
        _formatDuration(l10n: l10n, duration: settings.roundTime),
        _formatDuration(l10n: l10n, duration: settings.restTime),
        settings.rounds,
        total,
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          key: const Key('template-tile-surface'),
          decoration: BoxDecoration(
            color: background,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onTap,
            child: Padding(
              // Selected has a thicker border, so the padding shrinks by the same amount to keep the tile size.
              padding: EdgeInsets.all(AppSpacing.s12 - (borderWidth - _borderWidth)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: colorScheme.primary),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              l10n.templateTileSummary(
                                _formatClock(settings.roundTime),
                                _formatClock(settings.restTime),
                                settings.rounds,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Text(
                        total,
                        maxLines: 1,
                        softWrap: false,
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _PhaseBar(settings: settings),
                ],
              ),
            ),
          ),
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
