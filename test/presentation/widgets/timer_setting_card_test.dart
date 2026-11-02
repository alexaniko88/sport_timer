import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/presentation/widgets/timer_setting_card.dart';
import 'package:sport_timer/theme/app_spacing.dart';
import 'package:sport_timer/theme/sport_theme.dart';

Widget _app({required Widget child, ThemeData? theme}) => MaterialApp(
      theme: theme ?? SportTheme.light,
      home: Scaffold(body: Center(child: SizedBox(width: 180, height: 180, child: child))),
    );

TimerSettingCard _card(VoidCallback onPressed) => TimerSettingCard(
      label: 'Preparation time',
      value: '00:10',
      semanticHint: 'Opens selector',
      icon: Icons.hourglass_top,
      iconColor: Colors.amber,
      onPressed: onPressed,
    );

void main() {
  for (final theme in [SportTheme.light, SportTheme.dark]) {
    testWidgets('matches Templates surface in ${theme.brightness.name}', (tester) async {
      await tester.pumpWidget(_app(child: _card(() {}), theme: theme));
      final ink = tester.widget<Ink>(find.descendant(of: find.byType(TimerSettingCard), matching: find.byType(Ink)));
      final decoration = ink.decoration as BoxDecoration;
      final border = decoration.border as Border;
      expect(decoration.color, theme.colorScheme.surfaceContainer);
      expect(decoration.borderRadius, BorderRadius.circular(AppRadius.r12));
      expect(border.top.width, 1);
      expect(border.top.color, theme.colorScheme.outlineVariant);
      expect(tester.widget<Icon>(find.byIcon(Icons.hourglass_top)).color, Colors.amber);
      final labelStyle = tester.widget<Text>(find.text('Preparation time')).style;
      final valueStyle = tester.widget<Text>(find.text('00:10')).style;
      final resolvedTextTheme = Theme.of(tester.element(find.byType(TimerSettingCard))).textTheme;
      expect(labelStyle?.color, theme.colorScheme.onSurfaceVariant);
      expect(labelStyle?.fontWeight, FontWeight.w500);
      expect(labelStyle?.fontSize, resolvedTextTheme.titleMedium?.fontSize);
      expect(valueStyle?.color, isNot(Colors.amber));
      expect(valueStyle?.fontWeight, FontWeight.w700);
      expect(valueStyle?.fontSize, resolvedTextTheme.headlineSmall?.fontSize);
    });
  }

  testWidgets('the full surface and keyboard activate one accessible button', (tester) async {
    var activations = 0;
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(child: _card(() => activations++)));
    final card = find.byType(TimerSettingCard);
    final node = tester.getSemantics(card);
    expect(node.label, 'Preparation time');
    expect(node.value, '00:10');
    expect(node.hint, 'Opens selector');
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(node.childrenCount, 0);

    final rect = tester.getRect(card);
    await tester.tapAt(rect.topLeft + const Offset(4, 4));
    expect(activations, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activations, 2);
    handle.dispose();
  });

  for (final layout in [
    (width: 360.0, scale: 1.0, columns: 2, taller: false),
    (width: 800.0, scale: 2.0, columns: 2, taller: false),
    (width: 240.0, scale: 5.0, columns: 1, taller: true),
  ]) {
    testWidgets('grid keeps all cards equal at width ${layout.width}, scale ${layout.scale}', (tester) async {
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: SportTheme.light,
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(layout.scale)),
              child: SingleChildScrollView(
                child: Center(
                  child: SizedBox(
                    width: layout.width,
                    child: TimerSettingGrid(
                      children: [for (var index = 0; index < 4; index++) _card(() {})],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, layout.columns);
      final cards = find.byType(TimerSettingCard);
      expect(cards, findsNWidgets(4));
      final sizes = List.generate(4, (index) => tester.getSize(cards.at(index)));
      for (final size in sizes) {
        expect(size, sizes.first);
        if (layout.taller) {
          expect(size.height, greaterThan(size.width));
        } else {
          expect(size.height, size.width);
        }
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('truncated label and value retain their full semantics', (tester) async {
    const label = 'A very long setting label that cannot fit in the card';
    const value = '123456789012345678901234567890';
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        child: TimerSettingCard(
          label: label,
          value: value,
          semanticHint: 'Opens selector',
          icon: Icons.timer,
          iconColor: Colors.blue,
          onPressed: () {},
        ),
      ),
    );
    for (final text in [label, value]) {
      final finder = find.text(text);
      final widget = tester.widget<Text>(finder);
      expect(widget.maxLines, 1);
      expect(widget.overflow, TextOverflow.ellipsis);
      expect(tester.renderObject<RenderParagraph>(finder).didExceedMaxLines, isTrue);
    }
    final node = tester.getSemantics(find.byType(TimerSettingCard));
    expect(node.label, label);
    expect(node.value, value);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });
}
