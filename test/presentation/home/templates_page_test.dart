import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/settings/settings_repository.dart';
import 'package:sport_timer/features/settings/timer_style.dart';
import 'package:sport_timer/features/timer/timer_params.dart';
import 'package:sport_timer/features/user/user_repository.dart';
import 'package:sport_timer/l10n/app_localizations.dart';
import 'package:sport_timer/navigation.dart';
import 'package:sport_timer/presentation/home/home.dart';
import 'package:sport_timer/presentation/widgets/app_button.dart';
import 'package:sport_timer/presentation/widgets/template_tile.dart';
import 'package:sport_timer/theme/sport_theme.dart';

class _SettingsRepository implements SettingsRepository {
  final List<TimerSettings> saves = [];
  TimerSettings stored = const TimerSettings(
    preparationTime: Duration(seconds: 10),
    roundTime: Duration(seconds: 90),
    restTime: Duration(seconds: 15),
    rounds: 3,
  );

  @override
  Future<Result<TimerSettings>> getTimerSettings() async => Success(stored);

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

  testWidgets('shows the five templates in order with their icons and no selection', (tester) async {
    await openTemplates(tester);

    final tiles = tester.widgetList<TemplateTile>(find.byType(TemplateTile)).toList();
    expect(tiles, hasLength(5));
    expect(tiles.map((tile) => tile.name), _cases.map((item) => item.name));
    expect(tiles.map((tile) => tile.icon), _cases.map((item) => item.icon));
    expect(tiles.every((tile) => !tile.isSelected && !tile.isCustom), isTrue);
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
      expect(tester.widgetList<TemplateTile>(find.byType(TemplateTile)).every((tile) => !tile.isSelected), isTrue);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      const labels = ['Preparation time', 'Round time', 'Rest time', 'Rounds'];
      for (var index = 0; index < labels.length; index++) {
        final option = find.byWidgetPredicate((widget) => widget is AppButton && widget.label == labels[index]);
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
}
