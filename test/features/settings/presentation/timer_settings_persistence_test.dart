import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/settings/domain/settings_repository.dart';
import 'package:sport_timer/features/settings/domain/timer_configuration.dart';
import 'package:sport_timer/features/settings/domain/timer_settings.dart';
import 'package:sport_timer/features/settings/domain/timer_style.dart';
import 'package:sport_timer/features/user/domain/user_repository.dart';
import 'package:sport_timer/features/user/domain/app_user.dart';
import 'package:sport_timer/l10n/app_localizations.dart';
import 'package:sport_timer/features/home/presentation/home_page.dart';
import 'package:sport_timer/features/settings/presentation/widgets/timer_setting_card.dart';
import 'package:sport_timer/features/settings/presentation/widgets/timer_settings_picker_wheel.dart';
import 'package:sport_timer/shared/presentation/theme/sport_theme.dart';

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
  AppUser? getCurrentUser() => null;

  @override
  bool isUserLoggedIn() => false;

  @override
  Future<Result<void>> signInWithGoogle() async => const Success(null);

  @override
  Future<Result<void>> signOut() async => const Success(null);
}

Widget _app({Locale locale = const Locale('en'), ThemeData? theme, double textScale = 1}) => MaterialApp(
      locale: locale,
      theme: theme ?? SportTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomePage(),
    );

Future<void> _openRoundsPicker(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Rounds'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Rounds'));
  await tester.pumpAndSettle();
}

Future<void> _scrollRounds(WidgetTester tester) async {
  await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -120));
  await tester.pumpAndSettle();
}

void main() {
  late _SettingsRepository repository;

  setUp(() async {
    await getIt.reset();
    repository = _SettingsRepository();
    getIt.registerSingleton<SettingsRepository>(repository);
    getIt.registerSingleton<UserRepository>(_UserRepository());
  });

  tearDown(() async => getIt.reset());

  for (final language in [
    (locale: const Locale('en'), timer: 'Timer', statistics: 'Statistics', rounds: 'Rounds'),
    (locale: const Locale('es'), timer: 'Temporizador', statistics: 'Estadísticas', rounds: 'Rondas'),
  ]) {
    for (final theme in [SportTheme.light, SportTheme.dark]) {
      testWidgets('timer destination works in ${language.locale} with ${theme.brightness} theme and large text',
          (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(_app(locale: language.locale, theme: theme, textScale: 1.5));
        await tester.pumpAndSettle();

        BottomNavigationBar bar() => tester.widget(find.byType(BottomNavigationBar));
        expect(bar().items.first.label, language.timer);
        expect(bar().items.first.tooltip, language.timer);
        expect((bar().items.first.icon as Icon).icon, Icons.timer_outlined);
        expect((bar().items.first.activeIcon as Icon).icon, Icons.timer);
        expect(bar().currentIndex, 0);
        expect(find.bySemanticsLabel(RegExp(language.timer)), findsWidgets);
        expect(find.text(language.rounds), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text(language.statistics));
        await tester.pumpAndSettle();
        expect(bar().currentIndex, 1);
        expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
        await tester.tap(find.text(language.timer));
        await tester.pumpAndSettle();
        expect(bar().currentIndex, 0);
        expect(find.byIcon(Icons.timer), findsOneWidget);
        expect(find.text(language.rounds), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      });
    }
  }

  final options = [
    (label: 'Preparation', duration: const Duration(seconds: 10), maxMinutes: 5, min: Duration.zero),
    (label: 'Work', duration: const Duration(seconds: 90), maxMinutes: 60, min: const Duration(seconds: 1)),
    (label: 'Rest', duration: const Duration(seconds: 15), maxMinutes: 60, min: Duration.zero),
    (label: 'Rounds', duration: Duration.zero, maxMinutes: 60, min: Duration.zero),
  ];

  for (final option in options) {
    testWidgets('${option.label} opens its picker and updates and saves its value', (tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      final card = find.byWidgetPredicate((widget) => widget is TimerSettingCard && widget.label == option.label);
      final oldValue = tester.widget<TimerSettingCard>(card).value;
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();

      final picker = tester.widget<TimerSettingsPickerWheel>(find.byType(TimerSettingsPickerWheel));
      final isRounds = option.label == 'Rounds';
      expect(picker.picketType, isRounds ? PicketType.rounds : PicketType.time);
      expect(picker.initialDuration, option.duration);
      expect(picker.minDuration, option.min);
      expect(picker.maxMinutes, option.maxMinutes);
      expect(picker.rounds, isRounds ? 3 : 2);
      expect(picker.maxRounds, TimerSettings.maxRounds);
      await tester.drag(find.byType(ListWheelScrollView).last, const Offset(0, -120));
      await tester.pumpAndSettle();
      final updatedValue = tester.widget<TimerSettingCard>(card).value;
      expect(updatedValue, isNot(oldValue));
      expect(repository.saves, isEmpty);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(repository.saves, hasLength(1));
      final saved = repository.stored;
      if (isRounds) {
        expect(saved.rounds.toString(), updatedValue);
      } else {
        final seconds = switch (option.label) {
          'Preparation' => saved.preparationTime.inSeconds,
          'Work' => saved.roundTime.inSeconds,
          _ => saved.restTime.inSeconds,
        };
        expect(seconds, option.duration.inSeconds + 2);
      }
    });
  }

  for (final dismissal in ['outside tap', 'Back', 'swipe']) {
    testWidgets('saves the final wheel selection on $dismissal without Start', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await _openRoundsPicker(tester);
      await _scrollRounds(tester);
      expect(repository.saves, isEmpty);

      if (dismissal == 'outside tap') {
        await tester.tapAt(const Offset(10, 10));
      } else if (dismissal == 'Back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.drag(find.text('Rounds').last, const Offset(0, 500));
      }
      await tester.pumpAndSettle();

      expect(find.byType(ListWheelScrollView), findsNothing);
      expect(repository.saves, hasLength(1));
      expect(repository.stored.rounds, 5);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      expect(find.text('5'), findsOneWidget);
      expect(repository.saves, hasLength(1));
    });
  }

  testWidgets('opening and closing the wheel without a change does not save', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _openRoundsPicker(tester);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(repository.saves, isEmpty);
  });

  testWidgets('backgrounding an open wheel saves once and later dismissal skips the duplicate', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await _openRoundsPicker(tester);
    await _scrollRounds(tester);
    expect(repository.saves, isEmpty);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(repository.saves, hasLength(1));
    expect(repository.stored.rounds, 5);
    expect(find.byType(ListWheelScrollView), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(repository.saves, hasLength(1));
  });

  testWidgets('duration wheel saves its final duration only after closing', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListWheelScrollView).last, const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(repository.saves, isEmpty);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(repository.saves, hasLength(1));
    expect(repository.stored.roundTime, const Duration(seconds: 92));
  });
}
