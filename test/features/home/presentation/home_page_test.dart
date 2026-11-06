import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/home/presentation/home_page.dart';
import 'package:sport_timer/features/settings/domain/settings_repository.dart';
import 'package:sport_timer/features/settings/domain/timer_configuration.dart';
import 'package:sport_timer/features/settings/domain/timer_settings.dart';
import 'package:sport_timer/features/settings/domain/timer_style.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';
import 'package:sport_timer/features/templates/domain/built_in_templates.dart';
import 'package:sport_timer/features/templates/domain/workout_template.dart';
import 'package:sport_timer/features/user/domain/app_user.dart';
import 'package:sport_timer/features/user/domain/user_repository.dart';
import 'package:sport_timer/l10n/app_localizations.dart';
import 'package:sport_timer/navigation.dart';
import 'package:sport_timer/shared/presentation/theme/sport_theme.dart';
import 'package:sport_timer/shared/presentation/widgets/app_surface.dart';

import '../../statistics/fake_activity_repository.dart';

class _FakeSettingsRepository implements SettingsRepository {
  TimerSettings storedSettings = const TimerSettings(
    preparationTime: Duration(seconds: 10),
    roundTime: Duration(seconds: 90),
    restTime: Duration(seconds: 15),
    rounds: 3,
  );
  String? selectedTemplateId;
  TimerStyle storedStyle = TimerStyle.ring;

  // The view model drops a selection whose settings differ from the template's.
  void selectBuiltIn(TemplateId id) {
    final template = builtInTemplates.firstWhere((template) => template.id == id);
    storedSettings = template.settings;
    selectedTemplateId = id.name;
  }

  @override
  Future<Result<TimerConfiguration>> getTimerConfiguration() async {
    return Success(TimerConfiguration(storedSettings, selectedTemplateId));
  }

  @override
  Future<Result<void>> saveTimerConfiguration(TimerConfiguration configuration) async {
    storedSettings = configuration.settings;
    selectedTemplateId = configuration.selectedTemplateId;
    return const Success(null);
  }

  @override
  Future<Result<TimerSettings>> getTimerSettings() async => Success(storedSettings);

  @override
  Future<Result<void>> saveTimerSettings(TimerSettings settings) async {
    storedSettings = settings;
    return const Success(null);
  }

  @override
  Future<Result<TimerStyle>> getTimerStyle() async => Success(storedStyle);

  @override
  Future<Result<void>> saveTimerStyle(TimerStyle style) async {
    storedStyle = style;
    return const Success(null);
  }
}

class _FakeUserRepository implements UserRepository {
  @override
  AppUser? getCurrentUser() => null;

  @override
  bool isUserLoggedIn() => false;

  @override
  Future<Result<void>> signInWithGoogle() async => const Success(null);

  @override
  Future<Result<void>> signOut() async => const Success(null);
}

void main() {
  late _FakeSettingsRepository settings;
  late GoRouter router;

  setUp(() async {
    await getIt.reset();
    settings = _FakeSettingsRepository();
    getIt.registerSingleton<SettingsRepository>(settings);
    getIt.registerSingleton<UserRepository>(_FakeUserRepository());
    getIt.registerSingleton<ActivityRepository>(FakeEmptyActivityRepository());
    router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(
          path: RoutePath.templates.value,
          name: RoutePath.templates.value,
          builder: (context, state) => const Scaffold(body: Text('Templates destination')),
        ),
        GoRoute(
          path: RoutePath.timerStyles.value,
          name: RoutePath.timerStyles.value,
          builder: (context, state) => const Scaffold(body: Text('Styles destination')),
        ),
      ],
    );
  });

  tearDown(() async {
    router.dispose();
    await getIt.reset();
  });

  Future<void> openDrawer(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: theme ?? SportTheme.light,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
  }

  Finder tile(String title) => find.ancestor(of: find.text(title), matching: find.byType(AppSurface));

  Finder inDrawer(Finder finder) => find.descendant(of: find.byType(Drawer), matching: finder);

  testWidgets('drawer shows the header and two tiles with the active values', (tester) async {
    await openDrawer(tester);

    expect(find.byType(NavigationDrawer), findsNothing);
    expect(find.byType(Drawer), findsOneWidget);
    expect(inDrawer(find.byIcon(Icons.timer_outlined)), findsOneWidget);
    expect(inDrawer(find.text('Sport Timer')), findsOneWidget);
    expect(inDrawer(find.byType(Divider)), findsOneWidget);
    expect(inDrawer(find.byType(AppSurface)), findsNWidgets(2));
    expect(inDrawer(find.byIcon(Icons.chevron_right)), findsNWidgets(2));
    expect(inDrawer(find.byIcon(Icons.assignment_outlined)), findsOneWidget);
    expect(inDrawer(find.byIcon(Icons.style_outlined)), findsOneWidget);
    expect(tile('Templates'), findsOneWidget);
    expect(tile('Styles'), findsOneWidget);
    expect(inDrawer(find.text('Custom')), findsOneWidget);
    expect(inDrawer(find.text('Ring')), findsOneWidget);

    final texts = tester.widgetList<Text>(
      inDrawer(find.byType(Text)),
    );
    for (final text in texts) {
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    }
  });

  testWidgets('Templates subtitle shows the selected template name', (tester) async {
    settings.selectBuiltIn(TemplateId.hyrox);
    await openDrawer(tester);

    expect(inDrawer(find.text('Hyrox')), findsOneWidget);
    expect(inDrawer(find.text('Custom')), findsNothing);
  });

  for (final (style, label) in [
    (TimerStyle.ring, 'Ring'),
    (TimerStyle.fullColor, 'Full color'),
    (TimerStyle.roundsStrip, 'Rounds strip'),
  ]) {
    testWidgets('Styles subtitle shows $label for ${style.name}', (tester) async {
      settings.storedStyle = style;
      await openDrawer(tester);

      expect(inDrawer(find.text(label)), findsOneWidget);
    });
  }

  testWidgets('Spanish drawer shows Plantillas, Estilos and Personalizado', (tester) async {
    await openDrawer(tester, locale: const Locale('es'));

    expect(tile('Plantillas'), findsOneWidget);
    expect(tile('Estilos'), findsOneWidget);
    expect(inDrawer(find.text('Personalizado')), findsOneWidget);
    expect(inDrawer(find.text('Anillo')), findsOneWidget);
  });

  group('equal tile heights', () {
    Future<void> expectEqualHeights(WidgetTester tester, String first, String second) async {
      final firstSize = tester.getSize(tile(first));
      final secondSize = tester.getSize(tile(second));
      expect(firstSize.height, secondSize.height);
      expect(tester.takeException(), isNull);
    }

    testWidgets('in English', (tester) async {
      await openDrawer(tester);
      await expectEqualHeights(tester, 'Templates', 'Styles');
    });

    testWidgets('in Spanish', (tester) async {
      settings.selectBuiltIn(TemplateId.strength);
      settings.storedStyle = TimerStyle.roundsStrip;
      await openDrawer(tester, locale: const Locale('es'));
      await expectEqualHeights(tester, 'Plantillas', 'Estilos');
    });

    testWidgets('at 2x text scale', (tester) async {
      settings.selectBuiltIn(TemplateId.stretching);
      settings.storedStyle = TimerStyle.roundsStrip;
      await openDrawer(tester, textScale: 2);
      await expectEqualHeights(tester, 'Templates', 'Styles');
    });
  });

  testWidgets('tapping Templates closes the drawer and opens /templates', (tester) async {
    await openDrawer(tester);
    await tester.tap(tile('Templates'));
    await tester.pumpAndSettle();

    expect(find.text('Templates destination'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets('tapping Styles closes the drawer and opens /timer-styles', (tester) async {
    await openDrawer(tester);
    await tester.tap(tile('Styles'));
    await tester.pumpAndSettle();

    expect(find.text('Styles destination'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsNothing);
  });

  for (final (name, theme) in [('light', SportTheme.light), ('dark', SportTheme.dark)]) {
    testWidgets('open drawer meets accessibility guidelines in $name theme', (tester) async {
      final handle = tester.ensureSemantics();
      await openDrawer(tester, theme: theme);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }
}
