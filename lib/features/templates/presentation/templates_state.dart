import 'package:flutter/foundation.dart';
import 'package:sport_timer/features/settings/domain/timer_settings.dart';
import 'package:sport_timer/features/templates/domain/custom_template.dart';
import 'package:sport_timer/features/templates/domain/workout_template.dart';

typedef SelectedTemplateIdUpdate = TemplateId? Function();

class TemplatesState {
  final TimerSettings timerSettings;
  final TemplateId? selectedTemplateId;
  final List<CustomTemplate> customTemplates;
  final String? selectedCustomTemplateId;

  const TemplatesState({
    required this.timerSettings,
    required this.selectedTemplateId,
    this.customTemplates = const [],
    this.selectedCustomTemplateId,
  });

  TemplatesState copyWith({
    TimerSettings? timerSettings,
    SelectedTemplateIdUpdate? selectedTemplateId,
    List<CustomTemplate>? customTemplates,
  }) {
    return TemplatesState(
      timerSettings: timerSettings ?? this.timerSettings,
      selectedTemplateId: selectedTemplateId == null ? this.selectedTemplateId : selectedTemplateId(),
      customTemplates: customTemplates ?? this.customTemplates,
      selectedCustomTemplateId: selectedCustomTemplateId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplatesState &&
          other.timerSettings == timerSettings &&
          other.selectedTemplateId == selectedTemplateId &&
          listEquals(other.customTemplates, customTemplates) &&
          other.selectedCustomTemplateId == selectedCustomTemplateId;

  @override
  int get hashCode => Object.hash(
        timerSettings,
        selectedTemplateId,
        Object.hashAll(customTemplates),
        selectedCustomTemplateId,
      );
}
