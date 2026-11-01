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

  late TemplatesViewModel _templatesViewModel;

  @override
  void initState() {
    super.initState();
    _templatesViewModel = TemplatesViewModel(widget.viewModel);
  }

  @override
  void didUpdateWidget(covariant TemplatesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      _templatesViewModel.dispose();
      _templatesViewModel = TemplatesViewModel(widget.viewModel);
    }
  }

  @override
  void dispose() {
    _templatesViewModel.dispose();
    super.dispose();
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
          const Gap(AppSpacing.s8),
        ],
      ),
      body: ValueListenableBuilder<SettingsState>(
        valueListenable: widget.viewModel.state,
        builder: (context, settingsState, _) {
          final isLoading =
              settingsState.status == SettingsStatus.initial || settingsState.status == SettingsStatus.loading;
          return ValueListenableBuilder<TemplatesState>(
            valueListenable: _templatesViewModel.state,
            builder: (context, state, _) {
              final settings = state.timerSettings;
              final showCustom = !isLoading && state.selectedTemplateId == null;
              final totalTime = settings.preparationTime +
                  settings.roundTime * settings.rounds +
                  settings.restTime * (settings.rounds - 1);

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s16,
                  AppSpacing.s16,
                  _listBottomInset,
                ),
                children: [
                  AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : Durations.medium2,
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    ),
                    transitionBuilder: (child, animation) => SizeTransition(
                      sizeFactor: animation,
                      alignment: Alignment.topCenter,
                      child: child,
                    ),
                    child: showCustom
                        ? Padding(
                            key: const ValueKey('custom-header'),
                            padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                            child: TemplateTile(
                              key: const ValueKey('custom-template'),
                              name: l10n.templateCustomName,
                              icon: Icons.tune,
                              settings: settings,
                              totalTime: totalTime,
                              isCustom: true,
                            ),
                          )
                        : const SizedBox(key: ValueKey('no-custom-header'), width: double.infinity),
                  ),
                  for (final template in builtInTemplates) ...[
                    if (template != builtInTemplates.first) const Gap(AppSpacing.s8),
                    Builder(
                      key: ValueKey(template.id),
                      builder: (context) {
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
                          isSelected: !isLoading && template.id == state.selectedTemplateId,
                          onTap: () => _templatesViewModel.applyTemplate(template),
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
