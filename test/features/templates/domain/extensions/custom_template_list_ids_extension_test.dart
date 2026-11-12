import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/settings/domain/timer_settings.dart';
import 'package:sport_timer/features/templates/domain/custom_template.dart';
import 'package:sport_timer/features/templates/domain/custom_template_icon.dart';
import 'package:sport_timer/features/templates/domain/extensions/custom_template_list_ids_extension.dart';

void main() {
  CustomTemplate withId(String id) {
    return CustomTemplate(
      id: id,
      name: 'Name',
      icon: CustomTemplateIcon.timer,
      settings: const TimerSettings(
        preparationTime: Duration(seconds: 5),
        roundTime: Duration(seconds: 10),
        restTime: Duration(seconds: 4),
        rounds: 3,
      ),
    );
  }

  group('CustomTemplateListIds.nextId', () {
    test('nextId follows the highest number', () {
      expect(<CustomTemplate>[].nextId, 'custom-1');
      expect([withId('custom-1')].nextId, 'custom-2');
      expect([withId('custom-1'), withId('custom-7')].nextId, 'custom-8');
      expect([withId('custom-7'), withId('custom-1')].nextId, 'custom-8');
      expect([withId('custom-x'), withId('other-9'), withId('custom-2')].nextId, 'custom-3');
      expect([withId('custom-x')].nextId, 'custom-1');
    });
  });
}
