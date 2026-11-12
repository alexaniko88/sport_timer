import 'package:sport_timer/features/settings/domain/timer_settings.dart';
import 'package:sport_timer/features/templates/domain/custom_template_icon.dart';

class CustomTemplate {
  static const int maxCount = 20;
  static const int maxNameLength = 30;

  final String id;
  final String name;
  final CustomTemplateIcon icon;
  final TimerSettings settings;

  const CustomTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.settings,
  });

  Duration get totalTime =>
      settings.preparationTime + settings.roundTime * settings.rounds + settings.restTime * (settings.rounds - 1);

  CustomTemplate copyWith({
    String? id,
    String? name,
    CustomTemplateIcon? icon,
    TimerSettings? settings,
  }) {
    return CustomTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      settings: settings ?? this.settings,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomTemplate &&
          other.id == id &&
          other.name == name &&
          other.icon == icon &&
          other.settings == settings;

  @override
  int get hashCode => Object.hash(id, name, icon, settings);
}
