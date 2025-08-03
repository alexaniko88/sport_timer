part of 'home.dart';

class WorkoutTemplate {
  final String name;
  final String description;
  final Duration preparationTime;
  final Duration roundTime;
  final Duration restTime;
  final int rounds;
  final IconData icon;
  final Color color;

  const WorkoutTemplate({
    required this.name,
    required this.description,
    required this.preparationTime,
    required this.roundTime,
    required this.restTime,
    required this.rounds,
    required this.icon,
    required this.color,
  });
}

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({super.key});

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
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
      color: Colors.blue,
    ),
    WorkoutTemplate(
      name: 'Full Abs',
      description: 'Intense abdominal workout with short rounds',
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(seconds: 30),
      restTime: Duration(seconds: 10),
      rounds: 20,
      icon: Icons.sports_gymnastics,
      color: Colors.orange,
    ),
    WorkoutTemplate(
      name: 'CrossFit',
      description: 'High-intensity functional fitness training',
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(minutes: 1),
      restTime: Duration(seconds: 20),
      rounds: 15,
      icon: Icons.fitness_center,
      color: Colors.red,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SettingsCubit>(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Choose a Workout Template'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a pre-configured workout to get started quickly.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const Gap(24),
              Expanded(
                child: ListView.builder(
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    final isSelected = _selectedTemplateName == template.name;
                    return _buildTemplateCard(context, template, isSelected);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, WorkoutTemplate template, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _applyTemplate(context, template),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                template.color.withValues(alpha: 0.1),
                template.color.withValues(alpha: 0.05),
              ],
            ),
            border: isSelected
                ? Border.all(
                    color: template.color,
                    width: 3,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: template.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      template.icon,
                      color: template.color,
                      size: 28,
                    ),
                  ),
                  const Gap(16),
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
                                color: template.color,
                              ),
                            ),
                            if (isSelected) ...[
                              const Gap(8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: template.color,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'APPLIED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const Gap(4),
                        Text(
                          template.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildTemplateDetail('Preparation', _formatDuration(template.preparationTime))),
                        Expanded(child: _buildTemplateDetail('Round Time', _formatDuration(template.roundTime))),
                      ],
                    ),
                    const Gap(8),
                    Row(
                      children: [
                        Expanded(child: _buildTemplateDetail('Rest Time', _formatDuration(template.restTime))),
                        Expanded(child: _buildTemplateDetail('Rounds', '${template.rounds}')),
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  BlocBuilder<SettingsCubit, SettingsState>(
                    builder: (context, state) {
                      return ElevatedButton.icon(
                        onPressed: () => _applyTemplate(context, template),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Use Template'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: template.color,
                          foregroundColor: Colors.white,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const Gap(2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
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

  void _applyTemplate(BuildContext context, WorkoutTemplate template) {
    final settingsCubit = context.read<SettingsCubit>();
    final timerSettings = TimerSettings(
      preparationTime: template.preparationTime,
      roundTime: template.roundTime,
      restTime: template.restTime,
      rounds: template.rounds,
    );

    setState(() {
      _selectedTemplateName = template.name;
    });

    settingsCubit.saveSettings(timerSettings);
  }
}
