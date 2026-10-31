import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/settings/settings_repository.dart';
import 'package:sport_timer/features/settings/timer_style.dart';
import 'package:sport_timer/features/user/user_repository.dart';
import 'package:sport_timer/l10n/app_localizations.dart';
import 'package:sport_timer/presentation/home/home.dart';
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

Widget _app() => MaterialApp(
      theme: SportTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomePage(),
    );

Future<void> _openRoundsPicker(WidgetTester tester) async {
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
    await tester.tap(find.text('Round time'));
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
