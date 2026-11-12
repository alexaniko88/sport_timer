import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/account/presentation/account_view_model.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/domain/run_activity_summary.dart';
import 'package:sport_timer/features/statistics/domain/timer_session.dart';
import 'package:sport_timer/features/statistics/presentation/day_details_page.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_page.dart';
import 'package:sport_timer/features/user/domain/app_user.dart';
import 'package:sport_timer/features/user/domain/user_repository.dart';
import 'package:sport_timer/l10n/app_localizations.dart';
import 'package:sport_timer/navigation.dart';

class _User implements UserRepository {
  @override
  AppUser? getCurrentUser() => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repository implements ActivityRepository {
  final changesController = StreamController<void>.broadcast(sync: true);
  final dayReads = <Completer<Result<List<RunActivitySummary>>>>[];
  final requestedDates = <String>[];

  @override
  Future<Result<void>> deleteAllActivity() async => const Success(null);

  @override
  Stream<void> get changes => changesController.stream;

  Future<void> closeChanges() => changesController.close();
  @override
  Future<Result<List<DailyActivity>>> readDailyActivity() async => const Success([
        DailyActivity(localDate: '2026-11-02', roundCount: 2, workDurationMs: 75000, restDurationMs: 10000),
      ]);
  @override
  Future<Result<List<RunActivitySummary>>> readDayActivity(String localDate) {
    requestedDates.add(localDate);
    final read = Completer<Result<List<RunActivitySummary>>>();
    dayReads.add(read);
    return read.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const newer = RunActivitySummary(
    session: TimerSession(
      id: 'newer',
      accountId: 'a',
      startedAtUtcMs: 2,
      preparationDurationMs: 0,
      workDurationMs: 45000,
      restDurationMs: 15000,
      roundCount: 3,
    ),
    activity: DailyActivity(localDate: '2026-11-02', roundCount: 1, workDurationMs: 45000, restDurationMs: 0),
  );
  const older = RunActivitySummary(
    session: TimerSession(
      id: 'older',
      accountId: 'a',
      startedAtUtcMs: 1,
      preparationDurationMs: 0,
      workDurationMs: 30000,
      restDurationMs: 10000,
      roundCount: 5,
    ),
    activity: DailyActivity(localDate: '2026-11-02', roundCount: 1, workDurationMs: 30000, restDurationMs: 10000),
  );
  late _Repository repository;
  late AccountViewModel account;
  late GoRouter router;
  setUp(() {
    repository = _Repository();
    getIt.registerSingleton<ActivityRepository>(repository);
    account = AccountViewModel(_User());
    router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => StatisticPage(accountViewModel: account, onMenuPressed: () {})),
        GoRoute(
          path: RoutePath.dayDetails.value,
          builder: (context, state) => DayDetailsPage(localDate: state.extra as String),
        ),
      ],
    );
  });
  tearDown(() async {
    router.dispose();
    account.dispose();
    await getIt.reset();
    await repository.closeChanges();
  });

  testWidgets('opens the selected day, displays distinct runs and returns to the list', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('November 2, 2026'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(repository.requestedDates, ['2026-11-02']);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.dayReads.single.complete(const Success([newer, older]));
    await tester.pumpAndSettle();
    expect(find.text('Work: 1 minute 15 seconds'), findsOneWidget);
    expect(find.text('3 rounds'), findsOneWidget);
    expect(find.text('Work: 45 seconds'), findsNWidgets(2));
    await tester.scrollUntilVisible(find.text('5 rounds'), 200);
    expect(find.text('5 rounds'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(StatisticPage), findsOneWidget);
  });

  testWidgets('shows error, retries and handles an empty day', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('November 2, 2026'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    repository.dayReads.single.complete(Failure(Exception('private')));
    await tester.pumpAndSettle();
    expect(find.textContaining('private'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    repository.dayReads.last.complete(const Success([]));
    await tester.pumpAndSettle();
    expect(find.text('No completed activity for this day.'), findsOneWidget);
  });
}
