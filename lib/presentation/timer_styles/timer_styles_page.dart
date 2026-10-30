part of 'timer_styles.dart';

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
  static const double _borderWidth = 2;
  static const double _selectedFillAlpha = 0.08;

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
    // The same color as the app bar, so the cards match the rest of the app.
    final barColor = theme.appBarTheme.backgroundColor ?? colorScheme.surfaceContainer;
    final name = switch (style) {
      TimerStyle.ring => l10n.timerStyleRing,
      TimerStyle.fullColor => l10n.timerStyleFullColor,
      TimerStyle.roundsStrip => l10n.timerStyleRoundsStrip,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: name,
        // The border has the same width when selected, so the card does not change size.
        child: Material(
          color: isSelected ? colorScheme.primary.withValues(alpha: _selectedFillAlpha) : colorScheme.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r12),
            side: BorderSide(
              color: isSelected ? colorScheme.primary : barColor,
              width: _borderWidth,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s12),
              child: Row(
                children: [
                  ExcludeSemantics(child: TimerStylePreview(style: style)),
                  const SizedBox(width: AppSpacing.s16),
                  Expanded(child: Text(name, style: theme.textTheme.titleMedium)),
                  if (isSelected)
                    ExcludeSemantics(
                      child: Icon(Icons.check_circle, color: colorScheme.primary),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
