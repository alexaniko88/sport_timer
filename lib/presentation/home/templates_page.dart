part of 'home.dart';

enum TemplateAccent {
  blue,
  orange,
  red,
}

enum TemplateId {
  standard,
  fullAbs,
  crossFit,
}

class WorkoutTemplate {
  final TemplateId id;
  final Duration preparationTime;
  final Duration roundTime;
  final Duration restTime;
  final int rounds;
  final IconData icon;
  final TemplateAccent accent;

  const WorkoutTemplate({
    required this.id,
    required this.preparationTime,
    required this.roundTime,
    required this.restTime,
    required this.rounds,
    required this.icon,
    required this.accent,
  });
}

class TemplatesPage extends StatefulWidget {
  final SettingsViewModel viewModel;
  final AccountViewModel accountViewModel;
  final VoidCallback onMenuPressed;

  const TemplatesPage({
    super.key,
    required this.viewModel,
    required this.accountViewModel,
    required this.onMenuPressed,
  });

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  static const double _listBottomInset = 100;
  static const double _selectedBorderWidth = 3;
  static const double _iconSize = 28;
  static const double _detailBorderWidth = 1;

  TemplateId? _selectedTemplateId;

  static const List<WorkoutTemplate> templates = [
    WorkoutTemplate(
      id: TemplateId.standard,
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(minutes: 1),
      restTime: Duration(seconds: 30),
      rounds: 5,
      icon: Icons.assignment,
      accent: TemplateAccent.blue,
    ),
    WorkoutTemplate(
      id: TemplateId.fullAbs,
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(seconds: 30),
      restTime: Duration(seconds: 10),
      rounds: 20,
      icon: Icons.sports_gymnastics,
      accent: TemplateAccent.orange,
    ),
    WorkoutTemplate(
      id: TemplateId.crossFit,
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(minutes: 1),
      restTime: Duration(seconds: 20),
      rounds: 15,
      icon: Icons.fitness_center,
      accent: TemplateAccent.red,
    ),
  ];

  Color _resolveAccent({
    required TemplateAccent accent,
    required TimerColors timerColors,
  }) {
    return switch (accent) {
      TemplateAccent.blue => timerColors.totalTimeBorder,
      TemplateAccent.orange => timerColors.roundCounterBorder,
      TemplateAccent.red => timerColors.progressEnd,
    };
  }

  String _templateName(TemplateId id) {
    final l10n = context.l10n;
    return switch (id) {
      TemplateId.standard => l10n.templateDefaultName,
      TemplateId.fullAbs => l10n.templateAbsName,
      TemplateId.crossFit => l10n.templateCrossFitName,
    };
  }

  String _templateDescription(TemplateId id) {
    final l10n = context.l10n;
    return switch (id) {
      TemplateId.standard => l10n.templateDefaultDescription,
      TemplateId.fullAbs => l10n.templateAbsDescription,
      TemplateId.crossFit => l10n.templateCrossFitDescription,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.homeMenuTooltip,
          onPressed: widget.onMenuPressed,
          icon: const Icon(Icons.menu),
        ),
        title: Text(l10n.templatesTitle),
        actions: [
          AccountAvatarButton(viewModel: widget.accountViewModel),
          const SizedBox(width: AppSpacing.s8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.templatesSubtitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const Gap(AppSpacing.s8),
            Expanded(
              child: ListView.builder(
                // Bottom padding keeps the last card clear of the FAB.
                padding: const EdgeInsets.only(bottom: _listBottomInset),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  final isSelected = _selectedTemplateId == template.id;
                  return _buildTemplateCard(
                    context: context,
                    template: template,
                    isSelected: isSelected,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard({
    required BuildContext context,
    required WorkoutTemplate template,
    required bool isSelected,
  }) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final totalTime = _calculateTotalWorkoutTime(template);
    final timerColors = context.timerColors;
    final accentColor = _resolveAccent(
      accent: template.accent,
      timerColors: timerColors,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: InkWell(
        onTap: () => _applyTemplate(template),
        borderRadius: BorderRadius.circular(AppRadius.r12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.r12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withValues(alpha: 0.1),
                accentColor.withValues(alpha: 0.05),
              ],
            ),
            border: isSelected
                ? Border.all(
                    color: accentColor,
                    width: _selectedBorderWidth,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.r8),
                    ),
                    child: Icon(
                      template.icon,
                      color: accentColor,
                      size: _iconSize,
                    ),
                  ),
                  const Gap(AppSpacing.s16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _templateName(template.id),
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                            if (isSelected) ...[
                              const Gap(AppSpacing.s8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.s8,
                                  vertical: AppSpacing.s4,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(AppRadius.r12),
                                ),
                                child: Text(
                                  l10n.templatesApplied,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: timerColors.onAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const Gap(AppSpacing.s4),
                        Text(
                          _templateDescription(template.id),
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(AppSpacing.s16),
              // Total workout time - most prominent
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                    width: _detailBorderWidth,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.templatesTotalWorkoutTime,
                      style: textTheme.labelMedium?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(AppSpacing.s4),
                    Text(
                      _formatTotalTime(totalTime),
                      style: textTheme.headlineMedium?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.s16),
              // Detailed breakdown
              Container(
                padding: const EdgeInsets.all(AppSpacing.s12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.r8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTemplateDetail(
                            context,
                            l10n.templatesPreparation,
                            _formatDuration(template.preparationTime),
                          ),
                        ),
                        Expanded(
                          child: _buildTemplateDetail(
                            context,
                            l10n.templatesRoundTime,
                            _formatDuration(template.roundTime),
                          ),
                        ),
                      ],
                    ),
                    const Gap(AppSpacing.s8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTemplateDetail(
                            context,
                            l10n.templatesRestTime,
                            _formatDuration(template.restTime),
                          ),
                        ),
                        Expanded(
                          child: _buildTemplateDetail(
                            context,
                            l10n.commonRounds,
                            '${template.rounds}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.s12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.primary(
                    icon: const Icon(Icons.play_arrow),
                    label: l10n.templatesUseButton,
                    color: accentColor,
                    foregroundColor: timerColors.onAccent,
                    onPressed: () => _applyTemplate(template),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateDetail(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Gap(AppSpacing.s2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final l10n = context.l10n;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return l10n.durationMinutesSeconds(minutes, seconds);
    }
    return l10n.durationSeconds(seconds);
  }

  Duration _calculateTotalWorkoutTime(WorkoutTemplate template) {
    // Preparation time (once) + (Round time + Rest time) * rounds - last rest time
    final preparationSeconds = template.preparationTime.inSeconds;
    final roundSeconds = template.roundTime.inSeconds;
    final restSeconds = template.restTime.inSeconds;
    final rounds = template.rounds;

    // Total = preparation + (round + rest) * rounds - final rest (since there's no rest after the last round)
    final totalSeconds = preparationSeconds + (roundSeconds + restSeconds) * rounds - restSeconds;

    return Duration(seconds: totalSeconds);
  }

  String _formatTotalTime(Duration duration) {
    final l10n = context.l10n;
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

  void _applyTemplate(WorkoutTemplate template) {
    final timerSettings = TimerSettings(
      preparationTime: template.preparationTime,
      roundTime: template.roundTime,
      restTime: template.restTime,
      rounds: template.rounds,
    );

    setState(() {
      _selectedTemplateId = template.id;
    });

    widget.viewModel.saveSettings(timerSettings);
  }
}
