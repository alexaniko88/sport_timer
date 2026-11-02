import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/account/account_view_model.dart';
import 'package:sport_timer/features/settings/settings_repository.dart';
import 'package:sport_timer/features/settings/settings_view_model.dart';
import 'package:sport_timer/features/templates/workout_template.dart';
import 'package:sport_timer/features/settings/timer_style.dart';
import 'package:sport_timer/features/timer/timer_params.dart';
import 'package:sport_timer/features/user/user_repository.dart';
import 'package:sport_timer/l10n/app_localizations.dart';
import 'package:sport_timer/navigation.dart';
import 'package:sport_timer/presentation/home/home.dart';
import 'package:sport_timer/presentation/widgets/template_tile.dart';
import 'package:sport_timer/presentation/widgets/timer_setting_card.dart';
import 'package:sport_timer/theme/sport_theme.dart';
import 'package:sport_timer/theme/timer_colors.dart';

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
  User? getCurrentUser() => null;

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
      rounds: 5,
    ),
    values: ['00:20', '01:00', '00:30', '5'],
  ),
  (
    name: 'Full Abs',
    icon: Icons.sports_gymnastics,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(seconds: 30),
      restTime: Duration(seconds: 10),
      rounds: 20,
    ),
    values: ['00:20', '00:30', '00:10', '20'],
  ),
  (
    name: 'Hyrox',
    icon: Icons.directions_run,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 20),
      roundTime: Duration(minutes: 4),
      restTime: Duration(seconds: 30),
      rounds: 8,
    ),
    values: ['00:20', '04:00', '00:30', '8'],
  ),
  (
    name: 'Stretching',
    icon: Icons.self_improvement,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 10),
      roundTime: Duration(seconds: 45),
      restTime: Duration(seconds: 15),
      rounds: 10,
    ),
    values: ['00:10', '00:45', '00:15', '10'],
  ),
  (
    name: 'Strength',
    icon: Icons.fitness_center,
    settings: TimerSettings(
      preparationTime: Duration(seconds: 10),
      roundTime: Duration(seconds: 40),
      restTime: Duration(minutes: 1, seconds: 30),
      rounds: 6,
    ),
    values: ['00:10', '00:40', '01:30', '6'],
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

  for (final tab in ['Home', 'Templates']) {
    testWidgets('Start on $tab launches the latest wheel selection', (tester) async {
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
      if (tab == 'Templates') {
        await tester.tap(find.text('Templates'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(startedParams?.rounds, 5);
      expect(startedParams?.preparationTime, repository.stored.preparationTime);
      expect(startedParams?.roundTime, repository.stored.roundTime);
      expect(startedParams?.restTime, repository.stored.restTime);
    });
  }

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
        final home = locale == 'en' ? 'Home' : 'Inicio';
        final name = locale == 'en' ? 'Full Abs' : 'Abdominales completos';
        final label = locale == 'en' ? 'Template: Full Abs' : 'Plantilla: Abdominales completos';
        expect(find.textContaining(locale == 'en' ? 'Template:' : 'Plantilla:'), findsNothing);
        expect(find.text(tab), findsOneWidget);
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        await tester.tap(find.text(name));
        await tester.pumpAndSettle();
        expect(find.byType(TemplatesPage), findsOneWidget);
        await tester.tap(find.text(home));
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
        await tester.tap(find.text(home));
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

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      const labels = ['Preparation', 'Work', 'Rest', 'Rounds'];
      for (var index = 0; index < labels.length; index++) {
        final option = find.byWidgetPredicate((widget) => widget is TimerSettingCard && widget.label == labels[index]);
        expect(find.descendant(of: option, matching: find.text(item.values[index])), findsOneWidget);
      }

      await tester.tap(find.text('Start'));
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
    final account = AccountViewModel(_UserRepository());
    addTearDown(settings.dispose);
    addTearDown(account.dispose);
    await settings.loadSettings();
    await tester.pumpWidget(
      MaterialApp(
        theme: SportTheme.dark,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TemplatesPage(viewModel: settings, accountViewModel: account, onMenuPressed: () {}),
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
      final account = AccountViewModel(_UserRepository());
      addTearDown(settings.dispose);
      addTearDown(account.dispose);
      final handle = tester.ensureSemantics();
      await settings.loadSettings();
      await tester.pumpWidget(
        MaterialApp(
          theme: SportTheme.light,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TemplatesPage(viewModel: settings, accountViewModel: account, onMenuPressed: () {}),
        ),
      );
      settings.updatePreparationTime(const Duration(seconds: 25));
      await tester.pumpAndSettle();
      final custom = find.byKey(const ValueKey('custom-template'));
      expect(custom, findsOneWidget);
      expect(
        find.text(
          locale.languageCode == 'en'
              ? '0:25 prep · 1:00 work · 0:30 rest · 5 rounds'
              : '0:25 preparación · 1:00 trabajo · 0:30 descanso · 5 rondas',
        ),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(custom).label,
        contains(locale.languageCode == 'en' ? 'Preparation time 25s' : 'Tiempo de preparación 25s'),
      );
      expect(tester.widget<TemplateTile>(custom).totalTime, const Duration(minutes: 7, seconds: 25));
      handle.dispose();
    });
  }

  testWidgets('waits for persisted settings before showing the matching selection', (tester) async {
    repository.stored = _cases[2].settings;
    final gate = Completer<void>();
    repository.readGate = gate;
    final settings = SettingsViewModel(repository);
    final account = AccountViewModel(_UserRepository());
    addTearDown(settings.dispose);
    addTearDown(account.dispose);
    final loading = settings.loadSettings();

    await tester.pumpWidget(
      MaterialApp(
        theme: SportTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TemplatesPage(viewModel: settings, accountViewModel: account, onMenuPressed: () {}),
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
    final account = AccountViewModel(_UserRepository());
    addTearDown(settings.dispose);
    addTearDown(account.dispose);
    await settings.loadSettings();
    await tester.pumpWidget(
      MaterialApp(
        theme: SportTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TemplatesPage(viewModel: settings, accountViewModel: account, onMenuPressed: () {}),
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

    settings.updateRounds(5);
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
    settings.updateRounds(5);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    settings.updateRounds(7);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.widget<TemplateTile>(find.byKey(const ValueKey('custom-template'))).settings.rounds, 7);
    expect(tester.element(defaultRow), same(initialElement));
  });
}
