import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gap/gap.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';
import 'package:sport_timer/shared/presentation/theme/sport_theme.dart';
import 'package:sport_timer/shared/presentation/widgets/app_tag.dart';

const Color _customColor = Colors.red;

Widget _app(Widget child, {ThemeData? theme, double? width}) {
  return MaterialApp(
    theme: theme ?? SportTheme.light,
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: width == null ? child : SizedBox(width: width, child: child),
      ),
    ),
  );
}

BoxDecoration _decoration(WidgetTester tester) {
  final box = find.descendant(of: find.byType(AppTag), matching: find.byType(DecoratedBox));
  return tester.widget<DecoratedBox>(box.first).decoration as BoxDecoration;
}

void main() {
  group('AppTag', () {
    for (final theme in [SportTheme.light, SportTheme.dark]) {
      testWidgets('draws an unfilled bordered box without color (${theme.brightness.name})', (tester) async {
        await tester.pumpWidget(_app(const AppTag(icon: Icons.tune, label: 'Custom'), theme: theme));

        final decoration = _decoration(tester);
        final border = decoration.border as Border;

        expect(decoration.color, isNull);
        expect(decoration.borderRadius, BorderRadius.circular(AppRadius.r8));
        expect(border.top.color, theme.colorScheme.outlineVariant);
        expect(border.top.width, AppBorderWidth.thin);
        final padding = tester.widget<Padding>(
          find.descendant(of: find.byType(AppTag), matching: find.byType(Padding)).first,
        );
        expect(padding.padding, const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: 4));
      });
    }

    testWidgets('fills the box with the given color', (tester) async {
      await tester.pumpWidget(_app(const AppTag(icon: Icons.tune, label: 'Custom', color: _customColor)));

      expect(_decoration(tester).color, _customColor);
    });

    testWidgets('shows a primary icon and a one-line label', (tester) async {
      await tester.pumpWidget(_app(const AppTag(icon: Icons.tune, label: 'Custom')));

      final theme = Theme.of(tester.element(find.byType(AppTag)));
      final icon = tester.widget<Icon>(find.byIcon(Icons.tune));
      final text = tester.widget<Text>(find.text('Custom'));

      expect(icon.size, 16);
      expect(icon.color, theme.colorScheme.primary);
      expect(find.descendant(of: find.byType(AppTag), matching: find.byType(Gap)), findsOneWidget);
      expect(tester.widget<Gap>(find.byType(Gap)).mainAxisExtent, AppSpacing.s8);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.style?.fontSize, theme.textTheme.labelMedium?.fontSize);
      expect(text.style?.color, theme.colorScheme.onSurface);
    });

    testWidgets('without onTap is plain text with an optional semantic label', (tester) async {
      await tester.pumpWidget(_app(const AppTag(icon: Icons.tune, label: 'Custom')));

      expect(find.byType(InkWell), findsNothing);
      expect(
        tester.getSemantics(find.text('Custom')),
        matchesSemantics(label: 'Custom', isButton: false),
      );

      await tester.pumpWidget(
        _app(const AppTag(icon: Icons.tune, label: 'Custom', semanticLabel: 'Template: Custom')),
      );

      expect(find.byType(InkWell), findsNothing);
      expect(find.bySemanticsLabel('Template: Custom'), findsOneWidget);
      expect(find.bySemanticsLabel('Custom'), findsNothing);
    });

    testWidgets('with onTap is one button that calls onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          AppTag(
            icon: Icons.tune,
            label: 'Custom',
            semanticLabel: 'Template: Custom',
            onTap: () => taps++,
          ),
        ),
      );

      expect(find.bySemanticsLabel('Template: Custom'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(InkWell)),
        matchesSemantics(
          label: 'Template: Custom',
          isButton: true,
          hasTapAction: true,
        ),
      );

      await tester.tap(find.byType(AppTag));

      expect(taps, 1);

      await tester.pumpWidget(_app(AppTag(icon: Icons.tune, label: 'Custom', onTap: () {})));

      expect(find.bySemanticsLabel('Custom'), findsOneWidget);
    });

    testWidgets('with onTap has a 48 dp tap area', (tester) async {
      await tester.pumpWidget(_app(AppTag(icon: Icons.tune, label: 'Custom', onTap: () {})));

      expect(tester.getSize(find.byType(InkWell)).height, greaterThanOrEqualTo(kMinInteractiveDimension));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('ellipsizes a long label in a narrow parent', (tester) async {
      await tester.pumpWidget(
        _app(
          const AppTag(icon: Icons.tune, label: 'A very long label that does not fit in the tag'),
          width: 120,
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      final renderParagraph = tester.renderObject<RenderParagraph>(find.byType(Text));

      expect(tester.takeException(), isNull);
      expect(text.maxLines, 1);
      expect(renderParagraph.didExceedMaxLines, isTrue);
      expect(tester.getSize(find.byType(AppTag)).width, lessThanOrEqualTo(120));
    });
  });
}
