import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The plugin's platform interface lets tests make the platform write fail.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/settings/domain/timer_settings.dart';
import 'package:sport_timer/features/templates/data/shared_preferences_custom_template_repository.dart';
import 'package:sport_timer/features/templates/domain/custom_template.dart';
import 'package:sport_timer/features/templates/domain/custom_template_icon.dart';

class _RecordingPreferencesStore extends InMemorySharedPreferencesStore {
  bool failWrite = false;
  bool throwWrite = false;

  _RecordingPreferencesStore() : super.empty();

  @override
  Future<bool> setValue(
    String valueType,
    String key,
    Object value,
  ) async {
    if (throwWrite) throw Exception('write failed');
    if (failWrite) return false;
    return super.setValue(valueType, key, value);
  }
}

void main() {
  const first = CustomTemplate(
    id: 'custom-1',
    name: 'Morning',
    icon: CustomTemplateIcon.yoga,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 5),
      roundTime: Duration(seconds: 10),
      restTime: Duration(seconds: 4),
      rounds: 3,
    ),
  );
  const second = CustomTemplate(
    id: 'custom-2',
    name: 'Evening',
    icon: CustomTemplateIcon.running,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(seconds: 60),
      restTime: Duration.zero,
      rounds: 8,
    ),
  );

  late SharedPreferencesCustomTemplateRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = SharedPreferencesCustomTemplateRepository();
  });

  List<CustomTemplate> templatesOf(Result<List<CustomTemplate>> result) {
    return switch (result) {
      Success(:final value) => value,
      Failure(:final error) => fail('Expected templates but got $error'),
    };
  }

  group('SharedPreferencesCustomTemplateRepository', () {
    test('empty storage gives an empty list', () async {
      expect(templatesOf(await repository.getTemplates()), isEmpty);
    });

    test('saved templates survive a restart', () async {
      expect(await repository.saveTemplates([first, second]), isA<Success<void>>());

      final restarted = SharedPreferencesCustomTemplateRepository();

      expect(templatesOf(await restarted.getTemplates()), [first, second]);
    });

    test('malformed data is a failure', () async {
      SharedPreferences.setMockInitialValues({'custom_templates': 'not json'});
      expect(await repository.getTemplates(), isA<Failure<List<CustomTemplate>>>());

      SharedPreferences.setMockInitialValues({'custom_templates': '{"id": "custom-1"}'});
      expect(await repository.getTemplates(), isA<Failure<List<CustomTemplate>>>());
    });

    test('unknown icon falls back to weights', () async {
      SharedPreferences.setMockInitialValues({
        'custom_templates':
            '[{"id":"custom-1","name":"Morning","icon":"unicorn","preparation":5,"round":10,"rest":4,"rounds":3}]',
      });

      expect(templatesOf(await repository.getTemplates()), [first.copyWith(icon: CustomTemplateIcon.weights)]);
    });

    test('rounds are clamped to the allowed range', () async {
      SharedPreferences.setMockInitialValues({
        'custom_templates':
            '[{"id":"custom-1","name":"A","icon":"timer","preparation":5,"round":10,"rest":4,"rounds":99},'
                '{"id":"custom-2","name":"B","icon":"timer","preparation":5,"round":10,"rest":4,"rounds":0}]',
      });

      final templates = templatesOf(await repository.getTemplates());

      expect(templates.map((template) => template.settings.rounds), [TimerSettings.maxRounds, 1]);
    });
  });

  group('SharedPreferencesCustomTemplateRepository failed writes', () {
    late _RecordingPreferencesStore store;
    late SharedPreferencesStorePlatform previousStore;

    setUp(() {
      previousStore = SharedPreferencesStorePlatform.instance;
      store = _RecordingPreferencesStore();
      SharedPreferencesStorePlatform.instance = store;
      SharedPreferences.resetStatic();
    });

    tearDown(() {
      SharedPreferencesStorePlatform.instance = previousStore;
      SharedPreferences.resetStatic();
    });

    test('failed write is a failure', () async {
      store.failWrite = true;
      expect(await repository.saveTemplates([first]), isA<Failure<void>>());

      store.failWrite = false;
      store.throwWrite = true;
      expect(await repository.saveTemplates([first]), isA<Failure<void>>());
    });
  });
}
