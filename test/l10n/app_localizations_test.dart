import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/l10n_context.dart';
import 'package:sport_timer/l10n/app_localizations.dart';

Widget _app(Locale locale) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Column(
        children: [
          Text(context.l10n.appTitle),
          Text(context.l10n.authErrorTooManyRequests),
        ],
      ),
    ),
  );
}

void main() {
  group('AppLocalizations', () {
    testWidgets('shows the Spanish strings under the es locale', (tester) async {
      await tester.pumpWidget(_app(const Locale('es')));
      await tester.pumpAndSettle();

      expect(find.text('Sport Timer'), findsOneWidget);
      expect(find.text('Demasiados intentos. Inténtalo de nuevo más tarde.'), findsOneWidget);
    });

    testWidgets('shows the English strings under the en locale', (tester) async {
      await tester.pumpWidget(_app(const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Sport Timer'), findsOneWidget);
      expect(find.text('Too many attempts. Try again later.'), findsOneWidget);
    });
  });
}
