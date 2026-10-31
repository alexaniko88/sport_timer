part of 'home.dart';

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

  String _templateName(TemplateId id) {
    final l10n = context.l10n;
    return switch (id) {
      TemplateId.standard => l10n.templateDefaultName,
      TemplateId.fullAbs => l10n.templateAbsName,
      TemplateId.hyrox => l10n.templateHyroxName,
      TemplateId.stretching => l10n.templateStretchingName,
      TemplateId.strength => l10n.templateStrengthName,
    };
  }

  IconData _templateIcon(TemplateId id) {
    return switch (id) {
      TemplateId.standard => Icons.assignment,
      TemplateId.fullAbs => Icons.sports_gymnastics,
      TemplateId.hyrox => Icons.directions_run,
      TemplateId.stretching => Icons.self_improvement,
      TemplateId.strength => Icons.fitness_center,
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
                itemCount: builtInTemplates.length,
                itemBuilder: (context, index) {
                  final template = builtInTemplates[index];
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
    final totalTime = template.totalTime;
    final timerColors = context.timerColors;
    final accentColor = timerColors.totalTimeBorder;

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
                      _templateIcon(template.id),
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
                            _formatDuration(template.settings.preparationTime),
                          ),
                        ),
                        Expanded(
                          child: _buildTemplateDetail(
                            context,
                            l10n.templatesRoundTime,
                            _formatDuration(template.settings.roundTime),
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
                            _formatDuration(template.settings.restTime),
                          ),
                        ),
                        Expanded(
                          child: _buildTemplateDetail(
                            context,
                            l10n.commonRounds,
                            '${template.settings.rounds}',
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
    setState(() {
      _selectedTemplateId = template.id;
    });

    widget.viewModel.saveSettings(template.settings);
  }
}
