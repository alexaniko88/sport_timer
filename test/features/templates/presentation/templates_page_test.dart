import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/settings/domain/settings_repository.dart';
import 'package:sport_timer/features/settings/domain/timer_configuration.dart';
import 'package:sport_timer/features/settings/domain/timer_settings.dart';
import 'package:sport_timer/features/settings/presentation/settings_view_model.dart';
import 'package:sport_timer/features/templates/domain/workout_template.dart';
import 'package:sport_timer/features/settings/domain/timer_style.dart';
import 'package:sport_timer/features/timer/domain/timer_params.dart';
import 'package:sport_timer/features/user/domain/user_repository.dart';
import 'package:sport_timer/features/user/domain/app_user.dart';
import 'package:sport_timer/l10n/app_localizations.dart';
import 'package:sport_timer/navigation.dart';
import 'package:sport_timer/features/home/presentation/home_page.dart';
import 'package:sport_timer/features/settings/presentation/timer_setup_page.dart';
import 'package:sport_timer/features/templates/presentation/templates_page.dart';
import 'package:sport_timer/features/templates/presentation/widgets/template_tile.dart';
import 'package:sport_timer/features/settings/presentation/widgets/timer_setting_card.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';
import 'package:sport_timer/shared/presentation/theme/sport_theme.dart';
import 'package:sport_timer/shared/presentation/theme/timer_colors.dart';

class _SettingsRepository implements SettingsRepository {
  String? selectedTemplateId;
  @override
  Future<Result<TimerConfiguration>> getTimerConfiguration() async {
    final result = await getTimerSettings();
    return switch (result) {
      Success(:final value) => Success(TimerConfiguration(value, selectedTemplateId)),
      Failure(:final error) => Failure(error),
    };
  }

  @override
  Future<Result<void>> saveTimerConfiguration(TimerConfiguration configuration) async {
    final result = await saveTimerSettings(configuration.settings);
    if (result is Success<void>) selectedTemplateId = configuration.selectedTemplateId;
    return result;
  }

  final List<TimerSettings> saves = [];
  Completer<void>? readGate;
  TimerSettings stored = const TimerSettings(
    preparationTime: Duration(seconds: 10),
    roundTime: Duration(seconds: 90),
    restTime: Duration(seconds: 15),
    rounds: 3,
  );

  @override
  Future<Result<TimerSettings>> getTimerSettings() async {
    await readGate?.future;
    return Success(stored);
  }

  @override
  Future<Result<void>> saveTimerSettings(TimerSettings settings) async {
    saves.add(settings);
    stored = settings;
    return const Success(null);
  }

  @override
  Future<Result<TimerStyle>> getTimerStyle() async => const Success(TimerStyle.ring);

  @override
  Future<Result<void>> saveTimerStyle(TimerStyle style) async => const Success(null);
}

class _UserRepository implements UserRepository {
  @override
  AppUser? getCurrentUser() => null;

  @override
  bool isUserLoggedIn() => false;

  @override
  Future<Result<void>> signInWithGoogle() async => const Success(null);

  @override
  Future<Result<void>> signOut() async => const Success(null);
}

const _cases = [
  (
    name: 'Default',
    icon: Icons.assignment,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(minutes: 1),
      restTime: Duration(seconds: 30),
      rounds: 12,
    ),
    values: ['00:20', '01:00', '00:30', '12'],
  ),
  (
    name: 'Full Abs',
    icon: Icons.sports_gymnastics,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(seconds: 40),
      restTime: Duration(seconds: 10),
      rounds: 12,
    ),
    values: ['00:20', '00:40', '00:10', '12'],
  ),
  (
    name: 'Hyrox',
    icon: Icons.directions_run,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(minutes: 5),
      restTime: Duration(minutes: 1),
      rounds: 8,
    ),
    values: ['00:20', '05:00', '01:00', '8'],
  ),
  (
    name: 'Stretching',
    icon: Icons.self_improvement,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(minutes: 1),
      restTime: Duration(seconds: 5),
      rounds: 10,
    ),
    values: ['00:20', '01:00', '00:05', '10'],
  ),
  (
    name: 'Strength',
    icon: Icons.fitness_center,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(minutes: 1, seconds: 30),
      restTime: Duration(seconds: 30),
      rounds: 8,
    ),
    values: ['00:20', '01:30', '00:30', '8'],
  ),
];

void main() {
  late _SettingsRepository repository;
  late GoRouter router;
  TimerParams? startedParams;

  setUp(() async {
    await getIt.reset();
    repository = _SettingsRepository();
    getIt.registerSingleton<SettingsRepository>(repository);
    getIt.registerSingleton<UserRepository>(_UserRepository());
    startedParams = null;
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: RoutePath.timer.value,
          name: RoutePath.timer.value,
          builder: (context, state) {
            startedParams = state.extra as TimerParams;
            return const Scaffold(body: Text('Timer destination'));
          },
        ),
        GoRoute(
          path: RoutePath.templates.value,
          name: RoutePath.templates.value,
          builder: (context, state) => TemplatesPage(viewModel: state.extra as SettingsViewModel),
        ),
        GoRoute(
          path: RoutePath.timerStyles.value,
          name: RoutePath.timerStyles.value,
          builder: (context, state) => const Scaffold(body: Text('Timer styles destination')),
        ),
      ],
    );
  });

  tearDown(() async {
    router.dispose();
    await getIt.reset();
  });

  Future<void> openTemplates(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: SportTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Templates'));
    await tester.pumpAndSettle();
  }

  testWidgets('Setup uses equal square cards in reading order', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: SportTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    final cards = find.byType(TimerSettingCard);
    expect(tester.widgetList<TimerSettingCard>(cards).map((card) => card.label), [
      'Preparation',
      'Work',
      'Rest',
      'Rounds',
    ]);
    final rects = List.generate(4, (index) => tester.getRect(cards.at(index)));
    for (final rect in rects) {
      expect(rect.width, rect.height);
      expect(rect.size, rects.first.size);
    }
    expect(rects[0].top, rects[1].top);
    expect(rects[2].top, rects[3].top);
    expect(rects[0].left, rects[2].left);
    expect(rects[1].left, rects[3].left);
    expect(rects[2].top, greaterThan(rects[0].bottom));
  });

  for (final locale in [const Locale('en'), const Locale('es')]) {
    for (final theme in [SportTheme.light, SportTheme.dark]) {
      testWidgets('Setup Start is fixed and accessible in ${locale.languageCode} ${theme.brightness.name}',
          (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        repository.selectedTemplateId = TemplateId.standard.name;
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            theme: theme,
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final label = locale.languageCode == 'en' ? 'Start' : 'Iniciar';
        final sessionLabel = find.text(locale.languageCode == 'en' ? 'Session length' : 'Duración de la sesión');
        expect(sessionLabel, findsOneWidget);
        expect(find.text('05:10'), findsOneWidget);
        final button = find.ancestor(of: find.text(label), matching: find.byType(FilledButton));
        expect(button, findsOneWidget);
        expect(find.byType(FloatingActionButton), findsNothing);
        expect(find.descendant(of: button, matching: find.byIcon(Icons.play_arrow)), findsOneWidget);
        final buttonRect = tester.getRect(button);
        final labelRect = tester.getRect(sessionLabel);
        expect(buttonRect.width, 256);
        final buttonContext = tester.element(button);
        final shape = FilledButtonTheme.of(buttonContext).style!.shape!.resolve({}) as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(AppRadius.r12));
        final material = tester.widget<Material>(find.descendant(of: button, matching: find.byType(Material)).first);
        expect(material.color, theme.colorScheme.primary);
        final node = tester.getSemantics(find.text(label));
        expect(node.label, label);
        expect(find.semantics.byLabel(label), findsOne);
        expect(node.value, contains('05:10'));
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        final scrollable = find.descendant(of: find.byType(TimerSetupPage), matching: find.byType(Scrollable)).first;
        await tester.scrollUntilVisible(
          find.text(locale.languageCode == 'en' ? 'Rounds' : 'Rondas'),
          120,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(button), buttonRect);
        expect(tester.getRect(sessionLabel), labelRect);
        expect(tester.getRect(find.byType(TimerSettingCard).last).bottom, lessThanOrEqualTo(labelRect.top));
        expect(buttonRect.bottom, lessThanOrEqualTo(tester.getTopLeft(find.byType(BottomNavigationBar)).dy));
        expect(tester.takeException(), isNull);
        tester.semantics.tap(find.semantics.byLabel(label));
        await tester.pumpAndSettle();
        expect(startedParams?.preparationTime, repository.stored.preparationTime);
        expect(startedParams?.roundTime, repository.stored.roundTime);
        expect(startedParams?.restTime, repository.stored.restTime);
        expect(startedParams?.rounds, repository.stored.rounds);
        expect(startedParams?.style, TimerStyle.ring);
        semantics.dispose();
      });
    }
  }

  testWidgets('Start visibility is limited to Timer Setup and hidden on Statistics and Templates', (tester) async {
    await openTemplates(tester);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Start'), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.tap(find.text('Timer'));
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('session length updates with settings and formats hours', (tester) async {
    repository.stored = const TimerSettings(
      preparationTime: Duration(seconds: 1),
      roundTime: Duration(hours: 1),
      restTime: Duration(seconds: 30),
      rounds: 2,
    );
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: SportTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2:00:31'), findsOneWidget);
    await tester.tap(find.text('Rounds'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('4:01:31'), findsOneWidget);
  });

  testWidgets('tapping the session summary starts the timer', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: SportTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Session length'));
    await tester.pumpAndSettle();
    expect(find.text('Timer destination'), findsOneWidget);
    expect(startedParams?.rounds, repository.stored.rounds);
  });

  for (final locale in [const Locale('en'), const Locale('es')]) {
    for (final theme in [SportTheme.light, SportTheme.dark]) {
      testWidgets(
          'Setup cards expose localized actions and phase colors in ${locale.languageCode} ${theme.brightness.name}',
          (tester) async {
        tester.view.physicalSize = const Size(400, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            theme: theme,
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        );
        await tester.pumpAndSettle();
        final colors = theme.extension<TimerColors>()!;
        final phaseColors = [colors.preparation, colors.round, colors.rest, colors.roundsCount];
        final cards = find.byType(TimerSettingCard);
        final labels = locale.languageCode == 'en'
            ? ['Preparation', 'Work', 'Rest', 'Rounds']
            : ['Preparación', 'Trabajo', 'Descanso', 'Rondas'];
        for (var index = 0; index < 4; index++) {
          final card = tester.widget<TimerSettingCard>(cards.at(index));
          final node = tester.getSemantics(cards.at(index));
          expect(card.label, labels[index]);
          expect(card.iconColor, phaseColors[index]);
          expect(node.label, labels[index]);
          expect(node.value, card.value);
          expect(node.hint, isNotEmpty);
          expect(node.flagsCollection.isButton, isTrue);
          expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
          expect(node.childrenCount, 0);
        }
        handle.dispose();
      });
    }
  }

  testWidgets('Start on Timer Setup launches the latest wheel selection', (tester) async {
    tester.view.physicalSize = const Size(400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: SportTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rounds'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.text('Start')));
    await tester.pumpAndSettle();
    expect(startedParams?.rounds, 5);
    expect(startedParams?.preparationTime, repository.stored.preparationTime);
    expect(startedParams?.roundTime, repository.stored.roundTime);
    expect(startedParams?.restTime, repository.stored.restTime);
    expect(startedParams?.style, TimerStyle.ring);
    expect(repository.saves.last.rounds, 5);
  });

  testWidgets('Spanish large text keeps all settings reachable on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: SportTheme.dark,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final cards = find.byType(TimerSettingCard);
    expect(cards, findsNWidgets(4));
    for (var index = 0; index < 4; index++) {
      await tester.ensureVisible(cards.at(index));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(cards.at(index));
      await tester.pumpAndSettle();
      expect(find.byType(ListWheelScrollView), findsWidgets);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  for (final locale in ['en', 'es']) {
    for (final dark in [false, true]) {
      testWidgets('localized shortcut navigates in $locale, dark: $dark', (tester) async {
        repository.stored = _cases.first.settings;
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: router,
            theme: dark ? SportTheme.dark : SportTheme.light,
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        );
        await tester.pumpAndSettle();
        final tab = locale == 'en' ? 'Templates' : 'Plantillas';
        final name = locale == 'en' ? 'Full Abs' : 'Abdominales completos';
        final label = locale == 'en' ? 'Template: Full Abs' : 'Plantilla: Abdominales completos';
        expect(find.textContaining(locale == 'en' ? 'Template:' : 'Plantilla:'), findsNothing);
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        expect(find.text(tab), findsOneWidget);
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        await tester.tap(find.text(name));
        await tester.pumpAndSettle();
        expect(find.byType(TemplatesPage), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        final shortcut = find.text(label);
        expect(shortcut, findsOneWidget);
        final node = tester.getSemantics(shortcut);
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        await tester.tap(shortcut);
        await tester.pumpAndSettle();
        expect(find.byType(TemplatesPage), findsOneWidget);
        expect(find.text(name), findsOneWidget);
        await tester.tap(find.text('Hyrox'));
        await tester.pumpAndSettle();
        expect(find.byType(TemplatesPage), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text(locale == 'en' ? 'Template: Hyrox' : 'Plantilla: Hyrox'), findsOneWidget);
        semantics.dispose();
      });
    }
  }

  for (final scale in [1.0, 1.5]) {
    testWidgets('selected setup scrolls at compact size with text scale $scale', (tester) async {
      repository.stored = _cases.first.settings;
      repository.selectedTemplateId = TemplateId.standard.name;
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          theme: SportTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Template: Default'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Rounds'),
        120,
        scrollable: find
            .descendant(
              of: find.byType(TimerSetupPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rounds'));
      await tester.pumpAndSettle();
      expect(find.byType(ListWheelScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows Custom first followed by the five templates in order', (tester) async {
    await openTemplates(tester);

    final tiles = tester.widgetList<TemplateTile>(find.byType(TemplateTile)).toList();
    expect(tiles, hasLength(6));
    expect(tiles.first.name, 'Custom');
    expect(tiles.first.isCustom, isTrue);
    expect(tiles.skip(1).map((tile) => tile.name), _cases.map((item) => item.name));
    expect(tiles.skip(1).map((tile) => tile.icon), _cases.map((item) => item.icon));
    expect(tiles.every((tile) => !tile.isSelected), isTrue);
    expect(find.text('Choose your template'), findsOneWidget);
  });

  for (final item in _cases) {
    testWidgets('${item.name} saves settings and supplies Setup and Start', (tester) async {
      await openTemplates(tester);
      await tester.tap(find.text(item.name));
      await tester.pumpAndSettle();

      expect(repository.saves, [item.settings]);
      expect(repository.stored, item.settings);
      expect(find.byType(TemplatesPage), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(startedParams, isNull);
      final selected = tester.widgetList<TemplateTile>(find.byType(TemplateTile)).where((tile) => tile.isSelected);
      expect(selected.map((tile) => tile.name), [item.name]);
      expect(find.text('Custom'), findsNothing);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      const labels = ['Preparation', 'Work', 'Rest', 'Rounds'];
      for (var index = 0; index < labels.length; index++) {
        final option = find.byWidgetPredicate((widget) => widget is TimerSettingCard && widget.label == labels[index]);
        expect(find.descendant(of: option, matching: find.text(item.values[index])), findsOneWidget);
      }

      await tester.tapAt(tester.getCenter(find.text('Start')));
      await tester.pumpAndSettle();
      expect(find.text('Timer destination'), findsOneWidget);
      expect(startedParams?.preparationTime, item.settings.preparationTime);
      expect(startedParams?.roundTime, item.settings.roundTime);
      expect(startedParams?.restTime, item.settings.restTime);
      expect(startedParams?.rounds, item.settings.rounds);
      expect(startedParams?.style, TimerStyle.ring);
    });
  }

  testWidgets('shows the Custom card label in Spanish', (tester) async {
    final settings = SettingsViewModel(repository);
    addTearDown(settings.dispose);
    await settings.loadSettings();
    await tester.pumpWidget(
      MaterialApp(
        theme: SportTheme.dark,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TemplatesPage(viewModel: settings),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Personalizado'), findsOneWidget);
  });

  for (final locale in [const Locale('en'), const Locale('es')]) {
    testWidgets('shows a preparation-only edit in ${locale.languageCode}', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      repository.stored = _cases.first.settings;
      final settings = SettingsViewModel(repository);
      addTearDown(settings.dispose);
      final handle = tester.ensureSemantics();
      await settings.loadSettings();
      await tester.pumpWidget(
        MaterialApp(
          theme: SportTheme.light,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TemplatesPage(viewModel: settings),
        ),
      );
      settings.updatePreparationTime(const Duration(seconds: 25));
      await tester.pumpAndSettle();
      final custom = find.byKey(const ValueKey('custom-template'));
      expect(custom, findsOneWidget);
      expect(
        find.text(
          locale.languageCode == 'en'
              ? '0:25 prep · 1:00 work · 0:30 rest · 12 rounds'
              : '0:25 preparación · 1:00 trabajo · 0:30 descanso · 12 rondas',
        ),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(custom).label,
        contains(locale.languageCode == 'en' ? 'Preparation time 25s' : 'Tiempo de preparación 25s'),
      );
      expect(tester.widget<TemplateTile>(custom).totalTime, const Duration(minutes: 17, seconds: 55));
      handle.dispose();
    });
  }

  testWidgets('waits for persisted settings before showing the matching selection', (tester) async {
    repository.stored = _cases[2].settings;
    final gate = Completer<void>();
    repository.readGate = gate;
    final settings = SettingsViewModel(repository);
    addTearDown(settings.dispose);
    final loading = settings.loadSettings();

    await tester.pumpWidget(
      MaterialApp(
        theme: SportTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TemplatesPage(viewModel: settings),
      ),
    );
    expect(tester.widgetList<TemplateTile>(find.byType(TemplateTile)).any((tile) => tile.isSelected), isFalse);
    expect(find.text('Custom'), findsNothing);

    gate.complete();
    await loading;
    await tester.pumpAndSettle();
    final selected = tester.widgetList<TemplateTile>(find.byType(TemplateTile)).where((tile) => tile.isSelected);
    expect(selected.map((tile) => tile.name), ['Hyrox']);
    expect(find.text('Custom'), findsNothing);
  });

  testWidgets('animates Custom for live changes and restores the matching row', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repository.stored = _cases.first.settings;
    final settings = SettingsViewModel(repository);
    addTearDown(settings.dispose);
    await settings.loadSettings();
    await tester.pumpWidget(
      MaterialApp(
        theme: SportTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TemplatesPage(viewModel: settings),
      ),
    );
    await tester.pumpAndSettle();

    final defaultRow = find.byKey(const ValueKey(TemplateId.standard));
    final initialElement = tester.element(defaultRow);
    final initialRect = tester.getRect(defaultRow);
    expect(
      tester.widgetList<TemplateTile>(find.byType(TemplateTile)).where((tile) => tile.isSelected).single.name,
      'Default',
    );
    expect(find.text('Custom'), findsNothing);

    settings.updateRounds(6);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final duringRect = tester.getRect(defaultRow);
    await tester.pumpAndSettle();
    final customRect = tester.getRect(defaultRow);
    expect(duringRect.top, greaterThan(initialRect.top));
    expect(duringRect.top, lessThan(customRect.top));
    expect(customRect.size, initialRect.size);
    expect(tester.element(defaultRow), same(initialElement));
    expect(tester.widgetList<TemplateTile>(find.byType(TemplateTile)).any((tile) => tile.isSelected), isFalse);
    final custom = tester.widget<TemplateTile>(find.byKey(const ValueKey('custom-template')));
    expect(custom.settings, _cases.first.settings.copyWith(rounds: 6));
    expect(custom.totalTime, const Duration(minutes: 8, seconds: 50));
    expect(find.text('0:20 prep · 1:00 work · 0:30 rest · 6 rounds'), findsOneWidget);
    expect(find.text('8m 50s'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('custom-template')),
        matching: find.byKey(const Key('phase-bar')),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    expect(repository.saves, isEmpty);
    expect(settings.state.value.timerSettings.rounds, 6);

    settings.updateRounds(12);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Custom'), findsOneWidget);
    expect(tester.widget<TemplateTile>(find.byKey(const ValueKey('custom-template'))).settings.rounds, 6);
    final restoringRect = tester.getRect(defaultRow);
    expect(restoringRect.top, lessThan(customRect.top));
    expect(restoringRect.top, greaterThan(initialRect.top));
    await tester.pumpAndSettle();
    expect(find.text('Custom'), findsNothing);
    expect(tester.element(defaultRow), same(initialElement));
    expect(tester.getRect(defaultRow), initialRect);
    expect(
      tester.widgetList<TemplateTile>(find.byType(TemplateTile)).where((tile) => tile.isSelected).single.name,
      'Default',
    );

    settings.updateRounds(6);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    settings.updateRounds(12);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    settings.updateRounds(7);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.widget<TemplateTile>(find.byKey(const ValueKey('custom-template'))).settings.rounds, 7);
    expect(tester.element(defaultRow), same(initialElement));
  });

  testWidgets('drawer lists Templates above Timer styles and opens Templates', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: SportTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    final destinations = find.byType(NavigationDrawerDestination);
    expect(destinations, findsNWidgets(2));
    final templatesDest = find.widgetWithText(NavigationDrawerDestination, 'Templates');
    final timerStylesDest = find.widgetWithText(NavigationDrawerDestination, 'Timer styles');
    expect(templatesDest, findsOneWidget);
    expect(timerStylesDest, findsOneWidget);
    expect(tester.getTopLeft(templatesDest).dy, lessThan(tester.getTopLeft(timerStylesDest).dy));

    await tester.tap(templatesDest);
    await tester.pumpAndSettle();
    expect(find.byType(TemplatesPage), findsOneWidget);
    expect(find.byType(NavigationDrawer), findsNothing);
    expect(find.text('Choose your template'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('Start'), findsNothing);
  });

  testWidgets('Templates opens from Statistics tab and Back returns to Statistics', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: SportTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();
    expect(find.text('Your statistics'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDrawerDestination, 'Templates'));
    await tester.pumpAndSettle();
    expect(find.byType(TemplatesPage), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Your statistics'), findsOneWidget);
    final navBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(navBar.currentIndex, 1);
  });

  testWidgets('reopening Templates preserves selected template and settings', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: SportTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDrawerDestination, 'Templates'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hyrox'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Template: Hyrox'), findsOneWidget);

    // Reopen without choosing
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDrawerDestination, 'Templates'));
    await tester.pumpAndSettle();
    final selected = tester.widgetList<TemplateTile>(find.byType(TemplateTile)).where((tile) => tile.isSelected);
    expect(selected.map((tile) => tile.name), ['Hyrox']);

    // Pop back without choosing
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Template: Hyrox'), findsOneWidget);
    expect(repository.stored, _cases.firstWhere((c) => c.name == 'Hyrox').settings);
  });
}
