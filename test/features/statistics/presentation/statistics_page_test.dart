import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/account/presentation/account_view_model.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_page.dart';
import 'package:sport_timer/features/statistics/presentation/widgets/daily_activity_tile.dart';
import 'package:sport_timer/features/user/domain/app_user.dart';
import 'package:sport_timer/features/user/domain/user_repository.dart';
import 'package:sport_timer/l10n/app_localizations.dart';

class _FakeUserRepository implements UserRepository {
  @override
  AppUser? getCurrentUser() => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeActivityRepository implements ActivityRepository {
  final changesController = StreamController<void>.broadcast(sync: true);
  final reads = <Completer<Result<List<DailyActivity>>>>[];

  @override
  Stream<void> get changes => changesController.stream;

  @override
  Future<Result<List<DailyActivity>>> readDailyActivity() {
    final read = Completer<Result<List<DailyActivity>>>();
    reads.add(read);
    return read.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const first = DailyActivity(localDate: '2026-10-31', roundCount: 2, workDurationMs: 125000, restDurationMs: 30000);
  const second = DailyActivity(localDate: '2026-10-30', roundCount: 1, workDurationMs: 60000, restDurationMs: 0);
  late _FakeActivityRepository repository;
  late AccountViewModel account;

  setUp(() {
    repository = _FakeActivityRepository();
    getIt.registerSingleton<ActivityRepository>(repository);
    account = AccountViewModel(_FakeUserRepository());
  });

  tearDown(() async {
    account.dispose();
    await getIt.reset();
    await repository.changesController.close();
  });

  Future<void> showPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatisticPage(accountViewModel: account, onMenuPressed: () {}),
      ),
    );
  }

  testWidgets('loads daily tiles and clears old content while refreshing', (tester) async {
    await showPage(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.reads[0].complete(const Success([first, second]));
    await tester.pump();
    expect(find.text('31 October 2026'), findsOneWidget);
    expect(find.text('30 October 2026'), findsOneWidget);
    expect(find.text('2 rounds'), findsOneWidget);
    expect(find.text('Work: 2 minutes 5 seconds'), findsOneWidget);
    expect(find.text('Rest: 30 seconds'), findsOneWidget);
    expect(find.text('Total: 2 minutes 35 seconds'), findsOneWidget);

    repository.changesController.add(null);
    await tester.pump();
    expect(find.text('31 October 2026'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.reads[1].complete(const Success([]));
    await tester.pump();
    expect(find.text('No completed activity yet.'), findsOneWidget);
    repository.changesController.add(null);
    await tester.pump();
    repository.reads[2].complete(const Success([second]));
    await tester.pump();
    expect(find.text('No completed activity yet.'), findsNothing);
    expect(find.text('30 October 2026'), findsOneWidget);
  });

  testWidgets('shows an error and retries successfully', (tester) async {
    await showPage(tester);
    repository.reads[0].complete(Failure(Exception('private details')));
    await tester.pump();
    expect(find.text('Could not load your statistics.'), findsOneWidget);
    expect(find.textContaining('private details'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    repository.reads[1].complete(const Success([first]));
    await tester.pump();
    expect(find.text('31 October 2026'), findsOneWidget);
  });

  testWidgets('builds long histories lazily and reloads when reopened', (tester) async {
    await showPage(tester);
    repository.reads[0].complete(Success(List.filled(100, first)));
    await tester.pump();
    expect(find.byType(DailyActivityTile).evaluate().length, lessThan(100));
    await tester.pumpWidget(const SizedBox());
    await showPage(tester);
    expect(repository.reads.length, 2);
    repository.reads[1].complete(const Success([second]));
    await tester.pump();
    expect(find.text('30 October 2026'), findsOneWidget);
  });

  testWidgets('tile exposes all fields and fits large text', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const longActivity = DailyActivity(
      localDate: '2026-09-30',
      roundCount: 123,
      workDurationMs: 123456000,
      restDurationMs: 9876000,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(320, 800), textScaler: TextScaler.linear(2)),
          child: Scaffold(body: SingleChildScrollView(child: DailyActivityTile(activity: longActivity))),
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(
        '30 September 2026, 123 rounds, work 34 hours 17 minutes 36 seconds, '
        'rest 2 hours 44 minutes 36 seconds, total 37 hours 2 minutes 12 seconds',
      ),
      findsOneWidget,
    );
    expect(find.text('30 September 2026'), findsOneWidget);
    expect(find.text('Work: 34 hours 17 minutes 36 seconds'), findsOneWidget);
    expect(find.text('Total: 37 hours 2 minutes 12 seconds'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
