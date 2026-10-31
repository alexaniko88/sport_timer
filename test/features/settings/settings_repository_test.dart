import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The plugin's platform interface lets tests observe actual persistence calls.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/settings/settings_repository.dart';
import 'package:sport_timer/features/settings/timer_style.dart';

class _RecordingPreferencesStore extends InMemorySharedPreferencesStore {
  final List<String> writtenKeys = [];
  bool failWrite = false;
  bool throwWrite = false;

  _RecordingPreferencesStore() : super.empty();

  @override
  Future<bool> setValue(
    String valueType,
    String key,
    Object value,
  ) async {
    writtenKeys.add(key);
    if (throwWrite) throw Exception('write failed');
    if (failWrite) return false;
    return super.setValue(valueType, key, value);
  }
}

void main() {
  late SharedPreferencesSettingsRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = SharedPreferencesSettingsRepository();
  });

  TimerStyle styleOf(Result<TimerStyle> result) {
    return switch (result) {
      Success(:final value) => value,
      Failure(:final error) => fail('Expected a style but got $error'),
    };
  }

  group('SharedPreferencesSettingsRepository timer style', () {
    test('defaults to ring when nothing is saved', () async {
      expect(styleOf(await repository.getTimerStyle()), TimerStyle.ring);
    });

    test('returns the saved style', () async {
      await repository.saveTimerStyle(TimerStyle.roundsStrip);

      expect(styleOf(await repository.getTimerStyle()), TimerStyle.roundsStrip);
    });

    test('falls back to ring when the stored value is unknown', () async {
      SharedPreferences.setMockInitialValues({'timer_style': 'neon'});

      expect(styleOf(await repository.getTimerStyle()), TimerStyle.ring);
    });
  });

  group('SharedPreferencesSettingsRepository efficient saves', () {
    late _RecordingPreferencesStore store;
    late SharedPreferencesStorePlatform previousStore;
    const defaults = TimerSettings(
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(seconds: 60),
      restTime: Duration(seconds: 30),
      rounds: 5,
    );

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

    test('does not write defaults or an unchanged persisted selection', () async {
      await repository.saveTimerSettings(defaults);
      expect(store.writtenKeys, isEmpty);
      final selected = defaults.copyWith(rounds: 8);
      await repository.saveTimerSettings(selected);
      store.writtenKeys.clear();
      await repository.saveTimerSettings(selected);

      expect(store.writtenKeys, isEmpty);
    });

    test('writes only changed keys and restores them in a new session', () async {
      final selected = defaults.copyWith(roundTime: const Duration(seconds: 120), rounds: 8);
      await repository.saveTimerSettings(selected);
      expect(store.writtenKeys, ['flutter.round_time', 'flutter.rounds']);

      SharedPreferences.resetStatic();
      final nextSession = SharedPreferencesSettingsRepository();
      final result = await nextSession.getTimerSettings();
      expect(result, isA<Success<TimerSettings>>());
      if (result case Success(:final value)) expect(value, selected);
    });

    test('false platform results fail and retry despite the changed cache', () async {
      final selected = defaults.copyWith(rounds: 8);
      store.failWrite = true;
      expect(await repository.saveTimerSettings(selected), isA<Failure<void>>());
      store.failWrite = false;
      expect(await repository.saveTimerSettings(selected), isA<Success<void>>());

      expect(store.writtenKeys, ['flutter.rounds', 'flutter.rounds']);
      SharedPreferences.resetStatic();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('rounds'), 8);
    });

    test('thrown platform errors fail and retry despite the changed cache', () async {
      final selected = defaults.copyWith(restTime: const Duration(seconds: 45));
      store.throwWrite = true;
      expect(await repository.saveTimerSettings(selected), isA<Failure<void>>());
      store.throwWrite = false;
      expect(await repository.saveTimerSettings(selected), isA<Success<void>>());

      expect(store.writtenKeys, ['flutter.rest_time', 'flutter.rest_time']);
    });
  });

  group('SharedPreferencesSettingsRepository rounds', () {
    Future<int> loadedRounds() async {
      return switch (await repository.getTimerSettings()) {
        Success(:final value) => value.rounds,
        Failure(:final error) => fail('Expected settings but got $error'),
      };
    }

    test('limits a stored value above the maximum', () async {
      SharedPreferences.setMockInitialValues({'rounds': 100});

      expect(await loadedRounds(), TimerSettings.maxRounds);
    });

    test('raises a stored value below one to one', () async {
      SharedPreferences.setMockInitialValues({'rounds': 0});

      expect(await loadedRounds(), 1);
    });
  });
}
