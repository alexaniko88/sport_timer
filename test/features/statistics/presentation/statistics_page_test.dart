import "dart:ui" show SemanticsAction;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/account/presentation/account_view_model.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';
import 'package:sport_timer/features/statistics/domain/activity_period.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_page.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_state.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_view_model.dart';
import 'package:sport_timer/shared/presentation/theme/sport_theme.dart';
import 'package:flutter/services.dart';
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

  Future<void> closeChanges() => changesController.close();

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
    await repository.closeChanges();
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
    expect(find.text('October 31, 2026'), findsOneWidget);
    expect(find.text('October 30, 2026'), findsOneWidget);
    expect(find.text('2 rounds'), findsOneWidget);
    expect(find.text('Work: 2 minutes 5 seconds'), findsOneWidget);
    expect(find.text('Rest: 30 seconds'), findsOneWidget);
    expect(find.text('Total: 2 minutes 35 seconds'), findsOneWidget);

    repository.changesController.add(null);
    await tester.pump();
    expect(find.text('October 31, 2026'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.reads[1].complete(const Success([]));
    await tester.pump();
    expect(find.text('No completed activity yet.'), findsOneWidget);
    repository.changesController.add(null);
    await tester.pump();
    repository.reads[2].complete(const Success([second]));
    await tester.pump();
    expect(find.text('No completed activity yet.'), findsNothing);
    expect(find.text('October 30, 2026'), findsOneWidget);
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
    expect(find.text('October 31, 2026'), findsOneWidget);
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
    expect(find.text('October 30, 2026'), findsOneWidget);
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(size: Size(320, 800), textScaler: TextScaler.linear(2)),
          child: Scaffold(body: SingleChildScrollView(child: DailyActivityTile(activity: longActivity))),
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(
        'September 30, 2026, 123 rounds, work 34 hours 17 minutes 36 seconds, '
        'rest 2 hours 44 minutes 36 seconds, total 37 hours 2 minutes 12 seconds',
      ),
      findsOneWidget,
    );
    expect(find.text('September 30, 2026'), findsOneWidget);
    expect(find.text('Work: 34 hours 17 minutes 36 seconds'), findsOneWidget);
    expect(find.text('Total: 37 hours 2 minutes 12 seconds'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
  testWidgets('chart controls expose selectable exact values and period navigation', (tester) async {
    final semantics = tester.ensureSemantics();
    final vm = StatisticsViewModel(repository, clock: () => DateTime(2026, 10, 31));
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatisticPage(accountViewModel: account, onMenuPressed: () {}, viewModel: vm),
      ),
    );
    repository.reads.single.complete(const Success([first, second]));
    await tester.pump();
    await tester.tap(find.text('Charts'));
    await tester.pumpAndSettle();
    expect(find.text('Period total: 3 minutes 5 seconds'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.ancestor(of: find.byIcon(Icons.chevron_right), matching: find.byType(IconButton)))
          .onPressed,
      isNull,
    );
    final bucket = find.bySemanticsLabel('October 31, 2026, 2 minutes 5 seconds');
    expect(bucket, findsOneWidget);
    tester.getSemantics(bucket).owner?.performAction(tester.getSemantics(bucket).id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(find.text('October 31, 2026: 2 minutes 5 seconds'), findsOneWidget);
    tester.getSemantics(bucket).owner?.performAction(tester.getSemantics(bucket).id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(find.text('Period total: 3 minutes 5 seconds'), findsOneWidget);
    final barButton = find.descendant(of: bucket, matching: find.byType(TextButton));
    final barElement = tester.element(barButton);
    var foundFocus = false;
    for (var i = 0; i < 40 && !foundFocus; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      FocusManager.instance.primaryFocus?.context?.visitAncestorElements((element) {
        if (element == barElement) foundFocus = true;
        return !foundFocus;
      });
    }
    expect(foundFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('October 31, 2026: 2 minutes 5 seconds'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Period total: 3 minutes 5 seconds'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous period'));
    await tester.pumpAndSettle();
    expect(find.text('No activity recorded in this period.'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.ancestor(of: find.byIcon(Icons.chevron_right), matching: find.byType(IconButton)))
          .onPressed,
      isNotNull,
    );
    semantics.dispose();
  });

  testWidgets('Spanish chart marks future dates and retains controls on errors', (tester) async {
    final semantics = tester.ensureSemantics();
    final vm = StatisticsViewModel(repository, clock: () => DateTime(2026, 11, 4));
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatisticPage(accountViewModel: account, onMenuPressed: () {}, viewModel: vm),
      ),
    );
    repository.reads.single.complete(
      const Success([
        DailyActivity(localDate: '2026-11-02', roundCount: 1, workDurationMs: 60000, restDurationMs: 0),
      ]),
    );
    await tester.pump();
    await tester.tap(find.text('Gráficos'));
    await tester.pumpAndSettle();
    expect(vm.period.start, DateTime.utc(2026, 11, 2));
    expect(find.bySemanticsLabel('8 de noviembre de 2026, Futuro'), findsOneWidget);
    repository.changesController.add(null);
    await tester.pump();
    repository.reads.last.complete(Failure(Exception('failed')));
    await tester.pump();
    expect(find.text('Perspectiva'), findsOneWidget);
    expect(find.text('Semana'), findsOneWidget);
    expect(find.byTooltip('Periodo anterior'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('short landscape scrolls from chart controls to content and back', (tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final vm = StatisticsViewModel(repository, clock: () => DateTime(2026, 10, 31));
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(700, 320), textScaler: TextScaler.linear(2)),
          child: StatisticPage(accountViewModel: account, onMenuPressed: () {}, viewModel: vm),
        ),
      ),
    );
    repository.reads.single.complete(const Success([first]));
    await tester.pump();
    await tester.tap(find.text('Charts'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Previous period'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Previous period'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('No activity recorded in this period.'));
    await tester.pumpAndSettle();
    expect(find.text('No activity recorded in this period.'), findsOneWidget);
    await tester.ensureVisible(find.text('List'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('List'));
    await tester.pumpAndSettle();
    expect(find.text('October 31, 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('perspectives expose exact selected values and restore the total', (tester) async {
    final semantics = tester.ensureSemantics();
    final vm = StatisticsViewModel(repository, clock: () => DateTime(2026, 10, 31));
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatisticPage(accountViewModel: account, onMenuPressed: () {}, viewModel: vm),
      ),
    );
    repository.reads.single.complete(const Success([first, second]));
    await tester.pump();
    await tester.tap(find.text('Charts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Work time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Work vs rest').last);
    await tester.pumpAndSettle();
    expect(find.text('Period total: Work: 3 minutes 5 seconds · Rest: 30 seconds'), findsOneWidget);
    final bucket = find.bySemanticsLabel('October 31, 2026, Work: 2 minutes 5 seconds · Rest: 30 seconds');
    expect(bucket, findsOneWidget);
    tester.getSemantics(bucket).owner?.performAction(tester.getSemantics(bucket).id, SemanticsAction.tap);
    await tester.pumpAndSettle();
    expect(find.text('October 31, 2026: Work: 2 minutes 5 seconds · Rest: 30 seconds'), findsOneWidget);
    await tester.tap(find.text('Work vs rest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Total time').last);
    await tester.pumpAndSettle();
    expect(find.text('Period total: 3 minutes 35 seconds'), findsOneWidget);
    await tester.tap(find.text('Total time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rounds').last);
    await tester.pumpAndSettle();
    expect(find.text('Period total: 3 rounds'), findsOneWidget);
    expect(find.bySemanticsLabel('October 31, 2026, 2 rounds'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Spanish stacked values include exact fractions', (tester) async {
    final semantics = tester.ensureSemantics();
    final vm = StatisticsViewModel(repository, clock: () => DateTime(2026, 11, 4));
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatisticPage(accountViewModel: account, onMenuPressed: () {}, viewModel: vm),
      ),
    );
    repository.reads.single.complete(
      const Success([
        DailyActivity(localDate: '2026-11-02', roundCount: 1, workDurationMs: 1250, restDurationMs: 500),
      ]),
    );
    await tester.pump();
    await tester.tap(find.text('Gráficos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiempo de trabajo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trabajo y descanso').last);
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(
        '2 de noviembre de 2026, Trabajo: 1 segundo 250 milisegundos · Descanso: 500 milisegundos',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('rest-only period does not claim that no activity was recorded', (tester) async {
    final vm = StatisticsViewModel(repository, clock: () => DateTime(2026, 10, 31));
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatisticPage(accountViewModel: account, onMenuPressed: () {}, viewModel: vm),
      ),
    );
    repository.reads.single.complete(
      const Success([DailyActivity(localDate: '2026-10-31', roundCount: 0, workDurationMs: 0, restDurationMs: 30000)]),
    );
    await tester.pump();
    vm.setView(StatisticsView.charts);
    vm.setPerspective(StatisticsPerspective.consistency);
    await tester.pumpAndSettle();
    expect(find.text('Period total: 0 active days'), findsOneWidget);
    expect(find.text('No activity recorded in this period.'), findsNothing);
  });

  testWidgets('selecting a later year day brings its exact values into view', (tester) async {
    final vm = StatisticsViewModel(repository, clock: () => DateTime(2026, 10, 31));
    addTearDown(vm.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatisticPage(accountViewModel: account, onMenuPressed: () {}, viewModel: vm),
      ),
    );
    repository.reads.single.complete(const Success([first]));
    await tester.pump();
    vm.setView(StatisticsView.charts);
    vm.setPerspective(StatisticsPerspective.consistency);
    vm.setPeriodUnit(ActivityPeriodUnit.year);
    await tester.pumpAndSettle();
    final day = find.bySemanticsLabel('Saturday, October 31, 2026: Active day. Work: 2 minutes 5 seconds · 2 rounds');
    await tester.ensureVisible(day);
    await tester.tap(day);
    await tester.pumpAndSettle();
    final details = find.text('October 31, 2026: Work: 2 minutes 5 seconds · 2 rounds');
    expect(details, findsNWidgets(2));
    expect(tester.getRect(details.last).overlaps(tester.getRect(find.byType(Scaffold))), isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final theme in [SportTheme.light, SportTheme.dark]) {
    testWidgets('chart works at narrow width and large text', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final vm = StatisticsViewModel(repository, clock: () => DateTime(2026, 10, 31));
      addTearDown(vm.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(320, 800), textScaler: TextScaler.linear(2)),
            child: StatisticPage(accountViewModel: account, onMenuPressed: () {}, viewModel: vm),
          ),
        ),
      );
      repository.reads.single.complete(const Success([first]));
      await tester.pump();
      await tester.tap(find.text('Charts'));
      await tester.pumpAndSettle();
      for (final perspective in StatisticsPerspective.values) {
        vm.setPerspective(perspective);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    });
  }
}
