part of 'home.dart';

enum TemplateAccent {
  blue,
  orange,
  red,
}

class WorkoutTemplate {
  final String name;
  final String description;
  final Duration preparationTime;
  final Duration roundTime;
  final Duration restTime;
  final int rounds;
  final IconData icon;
  final TemplateAccent accent;

  const WorkoutTemplate({
    required this.name,
    required this.description,
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

  const TemplatesPage({
    super.key,
    required this.viewModel,
  });

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  static const double _listBottomInset = 100;
  static const double _selectedBorderWidth = 3;
  static const double _iconSize = 28;
  static const double _detailBorderWidth = 1;

  String? _selectedTemplateName;

  static const List<WorkoutTemplate> templates = [
    WorkoutTemplate(
      name: 'Default',
      description: 'Default workout with standard settings',
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(minutes: 1),
      restTime: Duration(seconds: 30),
      rounds: 5,
      icon: Icons.assignment,
      accent: TemplateAccent.blue,
    ),
    WorkoutTemplate(
      name: 'Full Abs',
      description: 'Intense abdominal workout with short rounds',
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(seconds: 30),
      restTime: Duration(seconds: 10),
      rounds: 20,
      icon: Icons.sports_gymnastics,
      accent: TemplateAccent.orange,
    ),
    WorkoutTemplate(
      name: 'CrossFit',
      description: 'High-intensity functional fitness training',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Workout Template'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a pre-configured workout to get started quickly.',
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
                  final isSelected = _selectedTemplateName == template.name;
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
                              template.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                                  'APPLIED',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                          template.description,
                          style: Theme.of(context).textTheme.bodyMedium,
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
                      'Total Workout Time',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Gap(AppSpacing.s4),
                    Text(
                      _formatTotalTime(totalTime),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                            'Preparation',
                            _formatDuration(template.preparationTime),
                          ),
                        ),
                        Expanded(
                          child: _buildTemplateDetail(
                            context,
                            'Round Time',
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
                            'Rest Time',
                            _formatDuration(template.restTime),
                          ),
                        ),
                        Expanded(
                          child: _buildTemplateDetail(
                            context,
                            'Rounds',
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
                  ElevatedButton.icon(
                    onPressed: () => _applyTemplate(template),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Use Template'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: timerColors.onAccent,
                    ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const Gap(AppSpacing.s2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
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
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
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
      _selectedTemplateName = template.name;
    });

    widget.viewModel.saveSettings(timerSettings);
  }
}
