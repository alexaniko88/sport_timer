part of 'home.dart';

class TemplatesPage extends StatelessWidget {
  static const double _listBottomInset = 100;

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
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.homeMenuTooltip,
          onPressed: onMenuPressed,
          icon: const Icon(Icons.menu),
        ),
        title: Text(l10n.templatesTitle),
        actions: [
          AccountAvatarButton(viewModel: accountViewModel),
          const SizedBox(width: AppSpacing.s8),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s16,
          AppSpacing.s16,
          _listBottomInset,
        ),
        itemCount: builtInTemplates.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.s8),
        itemBuilder: (context, index) {
          final template = builtInTemplates[index];
          final (name, icon) = switch (template.id) {
            TemplateId.standard => (l10n.templateDefaultName, Icons.assignment),
            TemplateId.fullAbs => (l10n.templateAbsName, Icons.sports_gymnastics),
            TemplateId.hyrox => (l10n.templateHyroxName, Icons.directions_run),
            TemplateId.stretching => (l10n.templateStretchingName, Icons.self_improvement),
            TemplateId.strength => (l10n.templateStrengthName, Icons.fitness_center),
          };

          return TemplateTile(
            name: name,
            icon: icon,
            settings: template.settings,
            totalTime: template.totalTime,
            onTap: () => viewModel.saveSettings(template.settings),
          );
        },
      ),
    );
  }
}
