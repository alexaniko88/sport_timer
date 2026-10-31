import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/templates/built_in_templates.dart';
import 'package:sport_timer/features/templates/workout_template.dart';
import 'package:sport_timer/l10n/app_localizations.dart';
import 'package:sport_timer/presentation/widgets/template_tile.dart';
import 'package:sport_timer/theme/sport_theme.dart';

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
        expect(find.text('1:00 work · 0:30 rest · 5 rounds'), findsOneWidget);
        expect(find.text('7m 20s'), findsOneWidget);
      });

      testWidgets('shows summary and total time for Full Abs', (tester) async {
        _setScreenSize(tester);
        await tester.pumpWidget(_app(_tile(_template(TemplateId.fullAbs), name: 'Full Abs')));

        expect(find.text('0:30 work · 0:10 rest · 20 rounds'), findsOneWidget);
        expect(find.text('13m 30s'), findsOneWidget);
      });

      testWidgets('shows summary and total time for Hyrox', (tester) async {
        _setScreenSize(tester);
        await tester.pumpWidget(_app(_tile(_template(TemplateId.hyrox), name: 'Hyrox')));

        expect(find.text('4:00 work · 0:30 rest · 8 rounds'), findsOneWidget);
        expect(find.text('35m 50s'), findsOneWidget);
      });

      testWidgets('uses the Spanish summary', (tester) async {
        _setScreenSize(tester);
        await tester.pumpWidget(
          _app(_tile(_template(TemplateId.standard)), locale: const Locale('es')),
        );

        expect(find.text('1:00 trabajo · 0:30 descanso · 5 rondas'), findsOneWidget);
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
          'Hyrox. Round time 4m 0s, rest time 30s, 8 rounds, total time 35m 50s',
        );
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isSelected, isNot(Tristate.isTrue));
        handle.dispose();
      });

      testWidgets('reads name and values in Spanish', (tester) async {
        _setScreenSize(tester);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _app(_tile(_template(TemplateId.hyrox), name: 'Hyrox'), locale: const Locale('es')),
        );

        expect(
          tester.getSemantics(find.byType(TemplateTile)).label,
          'Hyrox. Tiempo de ronda 4m 0s, tiempo de descanso 30s, 8 rondas, tiempo total 35m 50s',
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

      testWidgets('custom is outlined with a transparent background', (tester) async {
        _setScreenSize(tester);
        await tester.pumpWidget(_app(_tile(_template(TemplateId.standard), isCustom: true)));

        final decoration = _decoration(tester);
        final border = decoration.border! as Border;

        expect(decoration.color, Colors.transparent);
        expect(border.top.color, SportTheme.light.colorScheme.outline);
      });
    });

    group('phase bar', () {
      testWidgets('has one segment per phase without a rest after the last round', (tester) async {
        _setScreenSize(tester);
        await tester.pumpWidget(_app(_tile(_template(TemplateId.standard))));

        // 1 preparation + 5 rounds + 4 rests.
        expect(_segments(tester), hasLength(10));
      });

      testWidgets('Hyrox rounds are much longer than Full Abs rounds', (tester) async {
        _setScreenSize(tester);
        await tester.pumpWidget(_app(_tile(_template(TemplateId.hyrox))));
        final hyroxRoundFlex = _segments(tester)[1].flex;

        await tester.pumpWidget(_app(_tile(_template(TemplateId.fullAbs))));
        final absRoundFlex = _segments(tester)[1].flex;

        expect(hyroxRoundFlex, 240000);
        expect(absRoundFlex, 30000);
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
