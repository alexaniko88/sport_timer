import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/shared/presentation/widgets/app_button.dart';
import 'package:sport_timer/shared/presentation/theme/sport_theme.dart';

const double _screenWidth = 400;
const Color _customColor = Colors.red;

Widget _app(Widget child) {
  return MaterialApp(
    theme: SportTheme.light,
    home: Scaffold(
      body: Align(alignment: Alignment.topLeft, child: child),
    ),
  );
}

void _setScreenSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(_screenWidth, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

BorderSide? _side(ButtonStyleButton button) => button.style?.side?.resolve({});

void main() {
  group('AppButton', () {
    group('primary', () {
      testWidgets('calls onPressed on tap', (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          _app(AppButton.primary(label: 'Go', onPressed: () => taps++)),
        );

        await tester.tap(find.byType(FilledButton));

        expect(taps, 1);
      });

      testWidgets('is disabled when onPressed is null', (tester) async {
        await tester.pumpWidget(_app(const AppButton.primary(label: 'Go', onPressed: null)));

        final button = tester.widget<FilledButton>(find.byType(FilledButton));

        expect(button.onPressed, isNull);
      });

      testWidgets('has no border', (tester) async {
        await tester.pumpWidget(_app(AppButton.primary(label: 'Go', onPressed: () {})));

        final button = tester.widget<FilledButton>(find.byType(FilledButton));

        expect(_side(button), isNull);
      });

      testWidgets('applies color to the fill', (tester) async {
        await tester.pumpWidget(
          _app(AppButton.primary(label: 'Go', color: _customColor, onPressed: () {})),
        );

        final button = tester.widget<FilledButton>(find.byType(FilledButton));

        expect(button.style?.backgroundColor?.resolve({}), _customColor);
      });

      testWidgets('is a FilledButton with no elevation at rest', (tester) async {
        await tester.pumpWidget(_app(AppButton.primary(label: 'Go', onPressed: () {})));

        final button = tester.widget<FilledButton>(find.byType(FilledButton));

        expect(button.style?.elevation?.resolve({}) ?? 0, 0);
      });

      testWidgets('is 40 dp high under the app theme', (tester) async {
        await tester.pumpWidget(_app(AppButton.primary(label: 'Go', onPressed: () {})));

        // The button itself is 40 dp; the 48 dp tap target is padding around it.
        final material = find.descendant(of: find.byType(FilledButton), matching: find.byType(Material));

        expect(tester.getSize(material.first).height, 40);
      });

      testWidgets('shows the icon when one is given', (tester) async {
        await tester.pumpWidget(
          _app(AppButton.primary(label: 'Go', icon: const Icon(Icons.add), onPressed: () {})),
        );

        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('takes the full width when isExpanded is true', (tester) async {
        _setScreenSize(tester);
        await tester.pumpWidget(
          _app(AppButton.primary(label: 'Go', isExpanded: true, onPressed: () {})),
        );

        expect(tester.getSize(find.byType(FilledButton)).width, _screenWidth);
      });

      testWidgets('wraps its content when isExpanded is false', (tester) async {
        _setScreenSize(tester);
        await tester.pumpWidget(_app(AppButton.primary(label: 'Go', onPressed: () {})));

        expect(tester.getSize(find.byType(FilledButton)).width, lessThan(_screenWidth));
      });
    });

    group('secondary', () {
      testWidgets('calls onPressed on tap', (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          _app(AppButton.secondary(label: 'Go', onPressed: () => taps++)),
        );

        await tester.tap(find.byType(OutlinedButton));

        expect(taps, 1);
      });

      testWidgets('is disabled when onPressed is null', (tester) async {
        await tester.pumpWidget(_app(const AppButton.secondary(label: 'Go', onPressed: null)));

        final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));

        expect(button.onPressed, isNull);
      });

      testWidgets('has a 1 px border', (tester) async {
        await tester.pumpWidget(_app(AppButton.secondary(label: 'Go', onPressed: () {})));

        final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));

        expect(_side(button)?.width, 1);
      });

      testWidgets('applies color to the border and the text', (tester) async {
        await tester.pumpWidget(
          _app(AppButton.secondary(label: 'Go', color: _customColor, onPressed: () {})),
        );

        final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));

        expect(_side(button)?.color, _customColor);
        expect(button.style?.foregroundColor?.resolve({}), _customColor);
      });

      testWidgets('has no elevation', (tester) async {
        await tester.pumpWidget(_app(AppButton.secondary(label: 'Go', onPressed: () {})));

        final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));

        expect(button.style?.elevation?.resolve({}) ?? 0, 0);
      });

      testWidgets('takes the full width when isExpanded is true', (tester) async {
        _setScreenSize(tester);
        await tester.pumpWidget(
          _app(AppButton.secondary(label: 'Go', isExpanded: true, onPressed: () {})),
        );

        expect(tester.getSize(find.byType(OutlinedButton)).width, _screenWidth);
      });

      testWidgets('does not overflow with a long label in a narrow expanded button', (tester) async {
        tester.view.physicalSize = const Size(120, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _app(
            AppButton.secondary(
              label: 'A very long label that does not fit in the button',
              icon: const Icon(Icons.add),
              isExpanded: true,
              onPressed: () {},
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    });
  });
}
