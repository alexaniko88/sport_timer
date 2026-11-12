import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/settings/domain/timer_settings.dart';
import 'package:sport_timer/features/templates/domain/custom_template.dart';
import 'package:sport_timer/features/templates/domain/custom_template_icon.dart';

void main() {
  const settings = TimerSettings(
    preparationTime: Duration(seconds: 5),
    roundTime: Duration(seconds: 10),
    restTime: Duration(seconds: 4),
    rounds: 3,
  );

  CustomTemplate build({
    String id = 'custom-1',
    String name = 'Morning',
    CustomTemplateIcon icon = CustomTemplateIcon.yoga,
    TimerSettings templateSettings = settings,
  }) {
    return CustomTemplate(id: id, name: name, icon: icon, settings: templateSettings);
  }

  group('CustomTemplate', () {
    test('equality uses every field', () {
      expect(build(), build());
      expect(build().hashCode, build().hashCode);
      expect(build(), isNot(build(id: 'custom-2')));
      expect(build(), isNot(build(name: 'Evening')));
      expect(build(), isNot(build(icon: CustomTemplateIcon.running)));
      expect(build(), isNot(build(templateSettings: settings.copyWith(rounds: 4))));
    });

    test('totalTime skips the last rest', () {
      // 5 + 10 * 3 + 4 * 2
      expect(build().totalTime, const Duration(seconds: 43));
    });
  });
}
