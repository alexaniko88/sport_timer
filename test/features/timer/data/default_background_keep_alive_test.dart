import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/timer/data/default_background_keep_alive.dart';

const _drawablePath = 'android/app/src/main/res/drawable/ic_stat_sport_timer.xml';
const _keepPath = 'android/app/src/main/res/raw/keep.xml';

const _barbellPath = 'M20.5,30 H24.5 A3.5,3.5 0 0 1 28,33.5 V48.5 A3.5,3.5 0 0 1 24.5,52 H20.5 A3.5,3.5 0 0 1 17,48.5 '
    'V33.5 A3.5,3.5 0 0 1 20.5,30 Z M75.5,30 H79.5 A3.5,3.5 0 0 1 83,33.5 V48.5 A3.5,3.5 0 0 1 79.5,52 '
    'H75.5 A3.5,3.5 0 0 1 72,48.5 V33.5 A3.5,3.5 0 0 1 75.5,30 Z M28,41 H72 M41,41 V72 M59,41 V72 M41,57 H59';

void main() {
  group('DefaultBackgroundKeepAlive.notificationConfig', () {
    test('uses the barbell drawable as the notification icon', () {
      expect(DefaultBackgroundKeepAlive.notificationConfig.androidNotificationIcon, 'drawable/ic_stat_sport_timer');
    });

    test('keeps the workout channel and foreground settings', () {
      const config = DefaultBackgroundKeepAlive.notificationConfig;

      expect(config.androidNotificationChannelId, 'sport_timer.workout');
      expect(config.androidNotificationChannelName, 'Workout');
      expect(config.androidStopForegroundOnPause, isFalse);
    });
  });

  group('Android notification resources', () {
    test('the notification icon drawable draws the barbell in white strokes only', () {
      final xml = File(_drawablePath).readAsStringSync();

      expect(xml, contains('<vector'));
      expect(RegExp(r'android:pathData="([^"]*)"').firstMatch(xml)?.group(1), _barbellPath);
      expect(xml, isNot(contains('fillColor')));
      final colors = RegExp(r'#[0-9A-Fa-f]{6,8}').allMatches(xml).map((match) => match.group(0)).toSet();
      expect(colors, {'#FFFFFFFF'});
    });

    test('keep.xml keeps only the notification icon', () {
      final xml = File(_keepPath).readAsStringSync();

      expect(RegExp(r'tools:keep="([^"]*)"').firstMatch(xml)?.group(1), '@drawable/ic_stat_sport_timer');
      expect(xml, isNot(contains('*')));
    });
  });
}
