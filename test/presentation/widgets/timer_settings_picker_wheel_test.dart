import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/l10n/app_localizations.dart';
import 'package:sport_timer/presentation/widgets/timer_settings_picker_wheel.dart';
import 'package:sport_timer/theme/sport_theme.dart';

const double _itemExtent = 60;
const Color _color = Colors.red;

Widget _app() {
  return MaterialApp(
    theme: SportTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(),
  );
}

Future<void> _openTimePicker(
  WidgetTester tester, {
  required List<Duration> changes,
  required Duration initialDuration,
  Duration minDuration = Duration.zero,
  int maxMinutes = 60,
}) async {
  await tester.pumpWidget(_app());
  final context = tester.element(find.byType(Scaffold));
  TimerSettingsPickerWheel.show(
    context: context,
    picketType: PicketType.time,
    buttonsColor: _color,
    initialDuration: initialDuration,
    minDuration: minDuration,
    maxMinutes: maxMinutes,
    onDurationChanged: changes.add,
  );
  await tester.pumpAndSettle();
}

Future<void> _openRoundsPicker(
  WidgetTester tester, {
  required List<int> changes,
  required int rounds,
  int maxRounds = 100,
}) async {
  await tester.pumpWidget(_app());
  final context = tester.element(find.byType(Scaffold));
  TimerSettingsPickerWheel.show(
    context: context,
    picketType: PicketType.rounds,
    buttonsColor: _color,
    rounds: rounds,
    maxRounds: maxRounds,
    onRoundsChanged: changes.add,
  );
  await tester.pumpAndSettle();
}

/// Scrolls a wheel by [items] items; a positive value moves to a higher number.
Future<void> _scrollWheel(
  WidgetTester tester, {
  required Finder wheel,
  required int items,
}) async {
  await tester.drag(wheel, Offset(0, -items * _itemExtent));
  await tester.pumpAndSettle();
}

Finder get _minutesWheel => find.byType(ListWheelScrollView).first;
Finder get _secondsWheel => find.byType(ListWheelScrollView).last;

void main() {
  group('TimerSettingsPickerWheel', () {
    group('rounds picker', () {
      testWidgets('reports the new round count after scrolling', (tester) async {
        final changes = <int>[];
        await _openRoundsPicker(tester, changes: changes, rounds: 3);

        await _scrollWheel(tester, wheel: find.byType(ListWheelScrollView), items: 2);

        expect(changes.last, 5);
      });

      testWidgets('does not report a value before scrolling', (tester) async {
        final changes = <int>[];
        await _openRoundsPicker(tester, changes: changes, rounds: 3);

        expect(changes, isEmpty);
      });

      testWidgets('cannot scroll past maxRounds', (tester) async {
        final changes = <int>[];
        await _openRoundsPicker(tester, changes: changes, rounds: 4, maxRounds: 5);

        await _scrollWheel(tester, wheel: find.byType(ListWheelScrollView), items: 3);

        expect(changes.last, 5);
      });
    });

    group('time picker', () {
      testWidgets('keeps the seconds when the minutes change', (tester) async {
        final changes = <Duration>[];
        await _openTimePicker(
          tester,
          changes: changes,
          initialDuration: const Duration(minutes: 1, seconds: 30),
        );

        await _scrollWheel(tester, wheel: _minutesWheel, items: 1);

        expect(changes.last, const Duration(minutes: 2, seconds: 30));
      });

      testWidgets('keeps the minutes when the seconds change', (tester) async {
        final changes = <Duration>[];
        await _openTimePicker(
          tester,
          changes: changes,
          initialDuration: const Duration(minutes: 1, seconds: 10),
        );

        await _scrollWheel(tester, wheel: _secondsWheel, items: 5);

        expect(changes.last, const Duration(minutes: 1, seconds: 15));
      });

      testWidgets('can reach maxMinutes exactly', (tester) async {
        final changes = <Duration>[];
        await _openTimePicker(
          tester,
          changes: changes,
          initialDuration: const Duration(minutes: 1),
          maxMinutes: 2,
        );

        await _scrollWheel(tester, wheel: _minutesWheel, items: 1);

        expect(changes.last, const Duration(minutes: 2));
      });

      testWidgets('cannot go above maxMinutes', (tester) async {
        final changes = <Duration>[];
        await _openTimePicker(
          tester,
          changes: changes,
          initialDuration: const Duration(minutes: 2),
          maxMinutes: 2,
        );

        await _scrollWheel(tester, wheel: _secondsWheel, items: 5);

        expect(changes.last, const Duration(minutes: 2));
      });

      testWidgets('cannot go below minDuration', (tester) async {
        final changes = <Duration>[];
        await _openTimePicker(
          tester,
          changes: changes,
          initialDuration: const Duration(seconds: 1),
          minDuration: const Duration(seconds: 1),
        );

        await _scrollWheel(tester, wheel: _secondsWheel, items: -1);

        expect(changes.last, const Duration(seconds: 1));
      });

      testWidgets('allows zero when minDuration is zero', (tester) async {
        final changes = <Duration>[];
        await _openTimePicker(
          tester,
          changes: changes,
          initialDuration: const Duration(seconds: 1),
        );

        await _scrollWheel(tester, wheel: _secondsWheel, items: -1);

        expect(changes.last, Duration.zero);
      });

      testWidgets('does not report a value before scrolling', (tester) async {
        final changes = <Duration>[];
        await _openTimePicker(
          tester,
          changes: changes,
          initialDuration: const Duration(minutes: 1),
        );

        expect(changes, isEmpty);
      });
    });
  });
}
