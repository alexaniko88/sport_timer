import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sport_timer/features/settings/presentation/settings_state.dart';
import 'package:sport_timer/features/settings/presentation/settings_view_model.dart';
import 'package:sport_timer/features/templates/domain/built_in_templates.dart';
import 'package:sport_timer/features/templates/domain/workout_template.dart';
import 'package:sport_timer/features/templates/presentation/extensions/template_names_extension.dart';
import 'package:sport_timer/features/templates/presentation/templates_state.dart';
import 'package:sport_timer/features/templates/presentation/templates_view_model.dart';
import 'package:sport_timer/features/templates/presentation/widgets/template_tile.dart';
import 'package:sport_timer/shared/presentation/extensions/l10n_context.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';

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
        title: Text(l10n.templatesTitle),
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
                padding: const EdgeInsets.all(AppSpacing.s16),
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
                        final icon = switch (template.id) {
                          TemplateId.standard => Icons.assignment,
                          TemplateId.fullAbs => Icons.sports_gymnastics,
                          TemplateId.hyrox => Icons.directions_run,
                          TemplateId.stretching => Icons.self_improvement,
                          TemplateId.strength => Icons.fitness_center,
                        };

                        return TemplateTile(
                          name: l10n.templateName(template.id),
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
