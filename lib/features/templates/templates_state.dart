import 'package:sport_timer/features/settings/settings_repository.dart';
import 'package:sport_timer/features/templates/workout_template.dart';

typedef SelectedTemplateIdUpdate = TemplateId? Function();

class TemplatesState {
  final TimerSettings timerSettings;
  final TemplateId? selectedTemplateId;

  const TemplatesState({
    required this.timerSettings,
    required this.selectedTemplateId,
  });

  TemplatesState copyWith({
    TimerSettings? timerSettings,
    SelectedTemplateIdUpdate? selectedTemplateId,
  }) {
    return TemplatesState(
      timerSettings: timerSettings ?? this.timerSettings,
      selectedTemplateId: selectedTemplateId == null ? this.selectedTemplateId : selectedTemplateId(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplatesState && other.timerSettings == timerSettings && other.selectedTemplateId == selectedTemplateId;

  @override
  int get hashCode => Object.hash(timerSettings, selectedTemplateId);
}
