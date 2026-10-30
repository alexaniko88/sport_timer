import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/presentation/widgets/app_button.dart';
import 'package:sport_timer/theme/sport_theme.dart';

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

    group('icon', () {
      testWidgets('calls onPressed on tap', (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          _app(
            AppButton.icon(
              icon: const Icon(Icons.timer),
              tooltip: 'Start',
              onPressed: () => taps++,
            ),
          ),
        );

        await tester.tap(find.byType(FloatingActionButton));

        expect(taps, 1);
      });

      testWidgets('sets the tooltip', (tester) async {
        await tester.pumpWidget(
          _app(AppButton.icon(icon: const Icon(Icons.timer), tooltip: 'Start', onPressed: () {})),
        );

        final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));

        expect(fab.tooltip, 'Start');
      });

      testWidgets('is disabled when onPressed is null', (tester) async {
        await tester.pumpWidget(
          _app(const AppButton.icon(icon: Icon(Icons.timer), tooltip: 'Start', onPressed: null)),
        );

        final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));

        expect(fab.onPressed, isNull);
      });

      testWidgets('applies color to the fill', (tester) async {
        await tester.pumpWidget(
          _app(
            AppButton.icon(
              icon: const Icon(Icons.timer),
              tooltip: 'Start',
              color: _customColor,
              onPressed: () {},
            ),
          ),
        );

        final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));

        expect(fab.backgroundColor, _customColor);
      });

      testWidgets('has no custom border', (tester) async {
        await tester.pumpWidget(
          _app(AppButton.icon(icon: const Icon(Icons.timer), tooltip: 'Start', onPressed: () {})),
        );

        final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));

        expect(fab.shape, isNull);
      });

      testWidgets('shows the icon when not loading', (tester) async {
        await tester.pumpWidget(
          _app(AppButton.icon(icon: const Icon(Icons.timer), tooltip: 'Start', onPressed: () {})),
        );

        expect(find.byIcon(Icons.timer), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('shows a spinner and is disabled when isLoading is true', (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          _app(
            AppButton.icon(
              icon: const Icon(Icons.timer),
              tooltip: 'Start',
              isLoading: true,
              onPressed: () => taps++,
            ),
          ),
        );

        final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.timer), findsNothing);
        expect(fab.onPressed, isNull);
        expect(taps, 0);
      });
    });

    group('option', () {
      Widget option({VoidCallback? onPressed}) {
        return _app(
          AppButton.option(
            label: 'Round',
            value: '03:00',
            color: _customColor,
            icon: const Icon(Icons.fitness_center),
            semanticHint: 'Opens a selector',
            onPressed: onPressed,
          ),
        );
      }

      Material tileMaterial(WidgetTester tester) {
        return tester.widget<Material>(
          find.descendant(of: find.byType(AppButton), matching: find.byType(Material)).first,
        );
      }

      testWidgets('calls onPressed on tap', (tester) async {
        var taps = 0;
        await tester.pumpWidget(option(onPressed: () => taps++));

        await tester.tap(find.byType(InkWell));

        expect(taps, 1);
      });

      testWidgets('does not react to taps when onPressed is null', (tester) async {
        await tester.pumpWidget(option());

        final inkWell = tester.widget<InkWell>(find.byType(InkWell));

        expect(inkWell.onTap, isNull);
      });

      testWidgets('shows the label, the value and the unfold icon', (tester) async {
        await tester.pumpWidget(option(onPressed: () {}));

        expect(find.text('Round'), findsOneWidget);
        expect(find.text('03:00'), findsOneWidget);
        expect(find.byIcon(Icons.unfold_more), findsOneWidget);
        expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      });

      testWidgets('is a flat tile with the primaryContainer of the given color', (tester) async {
        await tester.pumpWidget(option(onPressed: () {}));

        final scheme = ColorScheme.fromSeed(seedColor: _customColor);
        final material = tileMaterial(tester);

        expect(material.elevation, 0);
        expect(material.color, scheme.primaryContainer);
      });

      testWidgets('has no border', (tester) async {
        await tester.pumpWidget(option(onPressed: () {}));

        final boxes = tester.widgetList<DecoratedBox>(
          find.descendant(of: find.byType(InkWell), matching: find.byType(DecoratedBox)),
        );

        expect(boxes.every((box) => (box.decoration as BoxDecoration).border == null), isTrue);
      });

      testWidgets('exposes the semantic hint', (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(option(onPressed: () {}));

        final semantics = find.descendant(of: find.byType(AppButton), matching: find.byType(Semantics));

        expect(tester.getSemantics(semantics.first).hint, 'Opens a selector');
        handle.dispose();
      });
    });
  });
}
