import 'package:flutter/material.dart';
import 'package:sport_timer/features/settings/domain/timer_style.dart';
import 'package:sport_timer/features/settings/presentation/extensions/timer_style_names_extension.dart';
import 'package:sport_timer/features/settings/presentation/settings_state.dart';
import 'package:sport_timer/features/settings/presentation/settings_view_model.dart';
import 'package:sport_timer/features/settings/presentation/timer_styles/timer_style_previews.dart';
import 'package:sport_timer/shared/presentation/extensions/l10n_context.dart';
import 'package:sport_timer/shared/presentation/extensions/text_theme_extension.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';
import 'package:sport_timer/shared/presentation/widgets/app_surface.dart';

class TimerStylesPage extends StatelessWidget {
  final SettingsViewModel viewModel;

  const TimerStylesPage({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.timerStylesTitle)),
      body: ValueListenableBuilder<SettingsState>(
        valueListenable: viewModel.state,
        builder: (context, state, _) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              for (final style in TimerStyle.values)
                _TimerStyleTile(
                  style: style,
                  isSelected: style == state.timerStyle,
                  onTap: () => viewModel.selectTimerStyle(style),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TimerStyleTile extends StatelessWidget {
  final TimerStyle style;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimerStyleTile({
    required this.style,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = l10n.timerStyleName(style);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: name,
        child: AppSurface(
          isSelected: isSelected,
          onTap: onTap,
          child: Row(
            children: [
              ExcludeSemantics(child: TimerStylePreview(style: style)),
              const SizedBox(width: AppSpacing.s16),
              Expanded(child: Text(name, style: theme.textTheme.tileTitle)),
              if (isSelected)
                ExcludeSemantics(
                  child: Icon(Icons.check_circle, color: colorScheme.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
