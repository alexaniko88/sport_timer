import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/settings/settings_repository.dart';
import 'package:sport_timer/features/settings/timer_style.dart';

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
