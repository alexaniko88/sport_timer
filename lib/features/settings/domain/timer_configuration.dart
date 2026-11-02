import 'package:sport_timer/features/settings/domain/timer_settings.dart';

class TimerConfiguration {
  final TimerSettings settings;
  final String? selectedTemplateId;

  const TimerConfiguration(this.settings, this.selectedTemplateId);

  @override
  bool operator ==(Object other) =>
      other is TimerConfiguration && other.settings == settings && other.selectedTemplateId == selectedTemplateId;

  @override
  int get hashCode => Object.hash(settings, selectedTemplateId);
}
