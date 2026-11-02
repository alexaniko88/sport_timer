import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/templates/domain/built_in_templates.dart';
import 'package:sport_timer/features/templates/domain/workout_template.dart';
import 'package:sport_timer/l10n/app_localizations.dart';
import 'package:sport_timer/features/templates/presentation/widgets/template_tile.dart';
import 'package:sport_timer/shared/presentation/theme/sport_theme.dart';
import 'package:sport_timer/shared/presentation/theme/timer_colors.dart';

const double _screenWidth = 400;

WorkoutTemplate _template(TemplateId id) => builtInTemplates.firstWhere((template) => template.id == id);

Widget _app(
  Widget child, {
  Locale locale = const Locale('en'),
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme ?? SportTheme.light,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Align(alignment: Alignment.topLeft, child: child),
    ),
  );
}

TemplateTile _tile(
  WorkoutTemplate template, {
  String name = 'Name',
  bool isSelected = false,
  bool isCustom = false,
  VoidCallback? onTap,
}) {
  return TemplateTile(
    name: name,
    icon: Icons.timer,
    settings: template.settings,
    totalTime: template.totalTime,
    isSelected: isSelected,
    isCustom: isCustom,
    onTap: onTap,
  );
}

void _setScreenSize(WidgetTester tester, {double width = _screenWidth}) {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

BoxDecoration _decoration(WidgetTester tester) {
  final ink = tester.widget<Ink>(find.byKey(const Key('template-tile-surface')));
  return ink.decoration! as BoxDecoration;
}

List<Expanded> _segments(WidgetTester tester) {
  return tester
      .widgetList<Expanded>(
        find.descendant(of: find.byKey(const Key('phase-bar')), matching: find.byType(Expanded)),
      )
      .toList();
}

void main() {
  group('TemplateTile', () {
    group('texts', () {
      testWidgets('shows summary and total time for Default', (tester) async {
        _setScreenSize(tester);
        await tester.pumpWidget(_app(_tile(_template(TemplateId.standard), name: 'Default')));

        expect(find.text('Default'), findsOneWidget);
        expect(find.text('1:00 work · 0:30 rest · 12 rounds'), findsOneWidget);
        expect(find.text('17m 50s'), findsOneWidget);
      });

      testWidgets('shows summary and total time for Full Abs', (tester) async {
        _setScreenSize(tester);
        await tester.pumpWidget(_app(_tile(_template(TemplateId.fullAbs), name: 'Full Abs')));

        expect(find.text('0:40 work · 0:10 rest · 12 rounds'), findsOneWidget);
        expect(find.text('10m 10s'), findsOneWidget);
      });

      testWidgets('shows summary and total time for Hyrox', (tester) async {
        _setScreenSize(tester);
        await tester.pumpWidget(_app(_tile(_template(TemplateId.hyrox), name: 'Hyrox')));

        expect(find.text('5:00 work · 1:00 rest · 8 rounds'), findsOneWidget);
        expect(find.text('47m 20s'), findsOneWidget);
      });

      testWidgets('uses the Spanish summary', (tester) async {
        _setScreenSize(tester);
        await tester.pumpWidget(
          _app(_tile(_template(TemplateId.standard)), locale: const Locale('es')),
        );

        expect(find.text('1:00 trabajo · 0:30 descanso · 12 rondas'), findsOneWidget);
      });
    });

    group('semantics', () {
      testWidgets('reads name and values in English', (tester) async {
        _setScreenSize(tester);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _app(_tile(_template(TemplateId.hyrox), name: 'Hyrox', onTap: () {})),
        );

        final data = tester.getSemantics(find.byType(TemplateTile));

        expect(
          data.label,
          'Hyrox. Round time 5m 0s, rest time 1m 0s, 8 rounds, total time 47m 20s',
        );
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isSelected, isNot(Tristate.isTrue));
        handle.dispose();
      });

      for (final locale in [const Locale('en'), const Locale('es')]) {
        for (final theme in [SportTheme.light, SportTheme.dark]) {
          testWidgets('announces selected and custom states in ${locale.languageCode}, ${theme.brightness.name}',
              (tester) async {
            _setScreenSize(tester);
            final handle = tester.ensureSemantics();
            await tester.pumpWidget(
              _app(
                _tile(_template(TemplateId.standard), name: 'Default', isSelected: true, onTap: () {}),
                locale: locale,
                theme: theme,
              ),
            );
            var data = tester.getSemantics(find.byType(TemplateTile));
            expect(data.flagsCollection.isSelected, Tristate.isTrue);
            expect(data.flagsCollection.isButton, isTrue);
            expect(data.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
            expect(find.byIcon(Icons.check_circle), findsOneWidget);

            await tester.pumpWidget(
              _app(
                _tile(_template(TemplateId.standard), name: 'Custom', isCustom: true),
                locale: locale,
                theme: theme,
              ),
            );
            data = tester.getSemantics(find.byType(TemplateTile));
            expect(
              data.label,
              startsWith(locale.languageCode == 'en' ? 'Custom settings.' : 'Ajustes personalizados.'),
            );
            expect(data.flagsCollection.isButton, isFalse);
            expect(data.flagsCollection.isSelected, isNot(Tristate.isTrue));
            expect(data.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
            final visibility = tester.widget<Visibility>(
              find.ancestor(
                of: find.byIcon(Icons.check_circle),
                matching: find.byType(Visibility),
              ),
            );
            expect(visibility.visible, isFalse);
            handle.dispose();
          });
        }
      }

      testWidgets('reads name and values in Spanish', (tester) async {
        _setScreenSize(tester);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _app(_tile(_template(TemplateId.hyrox), name: 'Hyrox'), locale: const Locale('es')),
        );

        expect(
          tester.getSemantics(find.byType(TemplateTile)).label,
          'Hyrox. Tiempo de ronda 5m 0s, tiempo de descanso 1m 0s, 8 rondas, tiempo total 47m 20s',
        );
        handle.dispose();
      });
    });

    group('states', () {
      testWidgets('selected has a thicker primary border', (tester) async {
        _setScreenSize(tester);
        await tester.pumpWidget(_app(_tile(_template(TemplateId.standard), isSelected: true)));

        final border = _decoration(tester).border! as Border;

        expect(border.top.width, 2);
        expect(border.top.color, SportTheme.light.colorScheme.primary);
      });

      testWidgets('unselected has a thin outline variant border', (tester) async {
        _setScreenSize(tester);
        await tester.pumpWidget(_app(_tile(_template(TemplateId.standard))));

        final border = _decoration(tester).border! as Border;

        expect(border.top.width, 1);
        expect(border.top.color, SportTheme.light.colorScheme.outlineVariant);
      });

      for (final theme in [SportTheme.light, SportTheme.dark]) {
        testWidgets('custom uses the timer color in ${theme.brightness.name} theme', (tester) async {
          _setScreenSize(tester);
          await tester.pumpWidget(_app(_tile(_template(TemplateId.standard), isCustom: true), theme: theme));

          final decoration = _decoration(tester);
          final border = decoration.border! as Border;
          final customColor = theme.extension<TimerColors>()!.roundCounterBorder;
          expect(border.top.color, customColor);
          expect(decoration.color, isNot(theme.colorScheme.surfaceContainer));
          expect(decoration.color, isNot(Colors.transparent));
        });
      }
    });

    group('phase bar', () {
      testWidgets('has one segment per phase without a rest after the last round', (tester) async {
        _setScreenSize(tester);
        await tester.pumpWidget(_app(_tile(_template(TemplateId.standard))));

        // 1 preparation + 12 rounds + 11 rests.
        expect(_segments(tester), hasLength(24));
      });

      testWidgets('Hyrox rounds are much longer than Full Abs rounds', (tester) async {
        _setScreenSize(tester);
        await tester.pumpWidget(_app(_tile(_template(TemplateId.hyrox))));
        final hyroxRoundFlex = _segments(tester)[1].flex;

        await tester.pumpWidget(_app(_tile(_template(TemplateId.fullAbs))));
        final absRoundFlex = _segments(tester)[1].flex;

        expect(hyroxRoundFlex, 300000);
        expect(absRoundFlex, 40000);
        expect(hyroxRoundFlex, greaterThan(absRoundFlex * 5));
      });
    });

    group('layout', () {
      testWidgets('builds in the dark theme', (tester) async {
        _setScreenSize(tester);
        await tester.pumpWidget(
          _app(_tile(_template(TemplateId.hyrox), isSelected: true), theme: SportTheme.dark),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(TemplateTile), findsOneWidget);
      });

      testWidgets('does not overflow on a narrow screen with a long Spanish name', (tester) async {
        _setScreenSize(tester, width: 320);
        await tester.pumpWidget(
          _app(
            SizedBox(
              width: 320,
              child: _tile(_template(TemplateId.hyrox), name: 'Entrenamiento de fuerza máxima'),
            ),
            locale: const Locale('es'),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('calls onTap on tap', (tester) async {
      _setScreenSize(tester);
      var taps = 0;
      await tester.pumpWidget(
        _app(_tile(_template(TemplateId.standard), onTap: () => taps++)),
      );

      await tester.tap(find.byType(TemplateTile));

      expect(taps, 1);
    });
  });
}
