import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/statistics/domain/activity_period.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/domain/run_activity_summary.dart';
import 'package:sport_timer/features/statistics/domain/timer_session.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_state.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_view_model.dart';

class FakeActivityRepository implements ActivityRepository {
  final controller = StreamController<void>.broadcast(sync: true);
  final reads = <Completer<Result<List<DailyActivity>>>>[];
  final dayReadDates = <String>[];
  final dayReads = <Completer<Result<List<RunActivitySummary>>>>[];

  final deleteResults = <Completer<Result<void>>>[];
  int deleteCalls = 0;

  @override
  Future<Result<void>> deleteAllActivity() async => const Success(null);

  @override
  Future<Result<void>> deleteAccountActivity() {
    deleteCalls++;
    final completer = Completer<Result<void>>();
    deleteResults.add(completer);
    return completer.future;
  }

  @override
  Stream<void> get changes => controller.stream;

  Future<void> closeChanges() => controller.close();

  @override
  Future<Result<List<DailyActivity>>> readDailyActivity() {
    final completer = Completer<Result<List<DailyActivity>>>();
    reads.add(completer);
    return completer.future;
  }

  @override
  Future<Result<List<RunActivitySummary>>> readDayActivity(String localDate) {
    dayReadDates.add(localDate);
    final completer = Completer<Result<List<RunActivitySummary>>>();
    dayReads.add(completer);
    return completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const first = DailyActivity(localDate: '2026-10-31', roundCount: 2, workDurationMs: 60, restDurationMs: 30);
  const second = DailyActivity(localDate: '2026-11-01', roundCount: 1, workDurationMs: 50, restDurationMs: 0);
  const run = RunActivitySummary(
    session: TimerSession(
      id: 'run',
      accountId: 'account',
      startedAtUtcMs: 0,
      preparationDurationMs: 0,
      workDurationMs: 60,
      restDurationMs: 30,
      roundCount: 2,
    ),
    activity: first,
  );
  late FakeActivityRepository repository;
  late StatisticsViewModel viewModel;

  setUp(() {
    repository = FakeActivityRepository();
    viewModel = StatisticsViewModel(repository);
  });

  tearDown(() async {
    viewModel.dispose();
    await repository.closeChanges();
  });

  test('loads content, then refreshes to empty', () async {
    expect(viewModel.state.value.status, StatisticsStatus.loading);
    repository.reads[0].complete(const Success([first]));
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.state.value.status, StatisticsStatus.content);
    expect(viewModel.state.value.dailyActivity, [first]);

    final refresh = viewModel.refresh();
    expect(viewModel.state.value.dailyActivity, isEmpty);
    repository.reads[1].complete(const Success([]));
    await refresh;
    expect(viewModel.state.value.status, StatisticsStatus.empty);
  });

  test('allows retry after an error', () async {
    repository.reads[0].complete(Failure(Exception('failed')));
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.state.value.status, StatisticsStatus.error);
    expect(viewModel.state.value.errorMessage, contains('failed'));

    final retry = viewModel.refresh();
    expect(viewModel.state.value.errorMessage, isNull);
    repository.reads[1].complete(const Success([first]));
    await retry;
    expect(viewModel.state.value.dailyActivity, [first]);
  });

  test('clears previous account on changes and ignores old success or failure', () async {
    repository.reads[0].complete(const Success([first]));
    await Future<void>.delayed(Duration.zero);
    repository.controller.add(null);
    expect(viewModel.state.value.status, StatisticsStatus.loading);
    expect(viewModel.state.value.dailyActivity, isEmpty);
    repository.controller.add(null);
    repository.reads[2].complete(const Success([second]));
    await Future<void>.delayed(Duration.zero);
    repository.reads[1].complete(Failure(Exception('old account')));
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.state.value.dailyActivity, [second]);
    expect(viewModel.state.value.status, StatisticsStatus.content);

    repository.controller.add(null);
    repository.controller.add(null);
    repository.reads[4].complete(const Success([second]));
    await Future<void>.delayed(Duration.zero);
    repository.reads[3].complete(const Success([first]));
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.state.value.dailyActivity, [second]);
  });

  test('chart data clears on account changes and ignores stale results', () async {
    final period = ActivityPeriod(unit: ActivityPeriodUnit.week, date: DateTime(2026, 11, 1), firstWeekday: 1);
    final today = DateTime(2026, 11, 1);
    repository.reads[0].complete(const Success([first]));
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.chartData(period: period, today: today).roundCount, 2);

    repository.controller.add(null);
    expect(viewModel.chartData(period: period, today: today).hasRecordedActivity, isFalse);
    repository.controller.add(null);
    repository.reads[2].complete(const Success([second]));
    await Future<void>.delayed(Duration.zero);
    repository.reads[1].complete(const Success([first]));
    await Future<void>.delayed(Duration.zero);
    final data = viewModel.chartData(period: period, today: today);
    expect(data.roundCount, 1);
    expect(data.workDurationMs, 50);
    expect(data.days.last.date, DateTime.utc(2026, 11, 1));
  });

  test('ignores a pending result after disposal', () async {
    final separateRepository = FakeActivityRepository();
    final separateViewModel = StatisticsViewModel(separateRepository);
    separateViewModel.dispose();
    separateRepository.reads[0].complete(const Success([first]));
    await Future<void>.delayed(Duration.zero);
    await separateRepository.closeChanges();
  });
  test('chart controls default, navigate, and keep selection across refresh', () async {
    final repo = FakeActivityRepository();
    final vm = StatisticsViewModel(repo, clock: () => DateTime(2026, 11, 4));
    addTearDown(() async {
      vm.dispose();
      await repo.closeChanges();
    });
    repo.reads.single.complete(const Success([first]));
    await Future<void>.delayed(Duration.zero);
    expect(vm.state.value.view, StatisticsView.list);
    vm.setView(StatisticsView.charts);
    expect(vm.period.unit, ActivityPeriodUnit.week);
    expect(vm.period.start, DateTime.utc(2026, 11, 2));
    expect(vm.canNavigateNext, isFalse);
    vm.previousPeriod();
    expect(vm.period.start, DateTime.utc(2026, 10, 26));
    final bucket = vm.currentChartData.buckets.last;
    vm.selectBucket(bucket);
    expect(vm.state.value.selectedBucket, bucket.start);
    vm.selectBucket(bucket);
    expect(vm.state.value.selectedBucket, isNull);
    vm.selectBucket(bucket);
    final refresh = vm.refresh();
    repo.reads.last.complete(const Success([first]));
    await refresh;
    expect(vm.state.value.selectedBucket, bucket.start);
    vm.setPeriodUnit(ActivityPeriodUnit.month);
    expect(vm.state.value.selectedBucket, isNull);
    expect(vm.period.start, DateTime.utc(2026, 10));
    vm.nextPeriod();
    expect(vm.period.start, DateTime.utc(2026, 11));
    expect(vm.canNavigateNext, isFalse);
    vm.nextPeriod();
    expect(vm.period.start, DateTime.utc(2026, 11));
    vm.setPeriodUnit(ActivityPeriodUnit.year);
    expect(vm.period.start, DateTime.utc(2026));
  });

  test('locale week start, zero and future buckets and account changes', () async {
    final repo = FakeActivityRepository();
    final vm = StatisticsViewModel(repo, clock: () => DateTime(2026, 11, 4));
    addTearDown(() async {
      vm.dispose();
      await repo.closeChanges();
    });
    repo.reads.single.complete(const Success([second]));
    await Future<void>.delayed(Duration.zero);
    vm.setView(StatisticsView.charts);
    vm.setFirstWeekday(DateTime.sunday);
    expect(vm.period.start, DateTime.utc(2026, 11, 1));
    final zero = vm.currentChartData.buckets[1];
    expect(zero.workDurationMs, 0);
    vm.selectBucket(zero);
    expect(vm.state.value.selectedBucket, zero.start);
    final future = vm.currentChartData.buckets.last;
    expect(future.isFuture, isTrue);
    vm.selectBucket(future);
    expect(vm.state.value.selectedBucket, zero.start);
    repo.controller.add(null);
    expect(vm.state.value.selectedBucket, isNull);
    expect(vm.state.value.view, StatisticsView.charts);
    repo.reads.last.complete(Failure(Exception('failed')));
    await Future<void>.delayed(Duration.zero);
    expect(vm.state.value.status, StatisticsStatus.error);
    expect(vm.state.value.view, StatisticsView.charts);
  });
  test('perspective changes clear selection and persist across view and period changes', () async {
    final repo = FakeActivityRepository();
    final vm = StatisticsViewModel(repo, clock: () => DateTime(2026, 10, 31));
    addTearDown(() async {
      vm.dispose();
      await repo.closeChanges();
    });
    repo.reads.single.complete(const Success([first]));
    await Future<void>.delayed(Duration.zero);
    expect(vm.state.value.perspective, StatisticsPerspective.workTime);
    vm.selectBucket(vm.currentChartData.buckets[5]);
    vm.setPerspective(StatisticsPerspective.workTime);
    expect(vm.state.value.selectedBucket, isNotNull);
    vm.setPerspective(StatisticsPerspective.rounds);
    expect(vm.state.value.selectedBucket, isNull);
    expect(vm.chartMaxY, 3);
    vm.setView(StatisticsView.charts);
    vm.setView(StatisticsView.list);
    vm.setPeriodUnit(ActivityPeriodUnit.year);
    expect(vm.state.value.perspective, StatisticsPerspective.rounds);
    vm.setPerspective(StatisticsPerspective.totalTime);
    expect(vm.chartMaxY, 1);
  });
  test('consistency selects past days and opens only available months', () async {
    final repo = FakeActivityRepository();
    final vm = StatisticsViewModel(repo, clock: () => DateTime(2024, 3, 1));
    addTearDown(() async {
      vm.dispose();
      await repo.closeChanges();
    });
    repo.reads.single.complete(const Success([]));
    await Future<void>.delayed(Duration.zero);
    vm.setPerspective(StatisticsPerspective.consistency);
    vm.setPeriodUnit(ActivityPeriodUnit.year);
    final leapDay = vm.currentChartData.days.firstWhere((day) => day.date == DateTime.utc(2024, 2, 29));
    final future = vm.currentChartData.days.firstWhere((day) => day.date == DateTime.utc(2024, 3, 2));
    vm.selectDay(leapDay);
    expect(vm.state.value.selectedBucket, leapDay.date);
    vm.selectDay(future);
    expect(vm.state.value.selectedBucket, leapDay.date);
    vm.selectDay(leapDay);
    expect(vm.state.value.selectedBucket, isNull);
    vm.selectDay(leapDay);
    vm.openMonth(DateTime.utc(2024, 4));
    expect(vm.period.unit, ActivityPeriodUnit.year);
    expect(vm.state.value.selectedBucket, leapDay.date);
    vm.openMonth(DateTime.utc(2024, 2));
    expect(vm.period.unit, ActivityPeriodUnit.month);
    expect(vm.period.start, DateTime.utc(2024, 2));
    expect(vm.currentChartData.days.last.date, DateTime.utc(2024, 2, 29));
    expect(vm.state.value.selectedBucket, isNull);
    vm.previousPeriod();
    expect(vm.period.start, DateTime.utc(2024, 1));
  });

  group('open day', () {
    Future<void> settle() => Future<void>.delayed(Duration.zero);

    setUp(() async {
      repository.reads[0].complete(const Success([first, second]));
      await settle();
    });

    test('toggleDay opens a day and loads its runs', () async {
      viewModel.toggleDay('2026-10-31');
      expect(viewModel.state.value.expandedDate, '2026-10-31');
      expect(viewModel.state.value.dayStatus, StatisticsStatus.loading);
      expect(repository.dayReadDates, ['2026-10-31']);
      repository.dayReads[0].complete(const Success([run]));
      await settle();
      expect(viewModel.state.value.dayStatus, StatisticsStatus.content);
      expect(viewModel.state.value.dayRuns, [run]);
      expect(repository.dayReadDates, ['2026-10-31']);
    });

    test('toggleDay on the open day closes it', () async {
      viewModel.toggleDay('2026-10-31');
      repository.dayReads[0].complete(const Success([run]));
      await settle();
      viewModel.toggleDay('2026-10-31');
      expect(viewModel.state.value.expandedDate, isNull);
      expect(viewModel.state.value.dayStatus, StatisticsStatus.initial);
      expect(viewModel.state.value.dayRuns, isEmpty);
    });

    test('toggleDay on another day closes the first', () async {
      viewModel.toggleDay('2026-10-31');
      repository.dayReads[0].complete(const Success([run]));
      await settle();
      viewModel.toggleDay('2026-11-01');
      expect(viewModel.state.value.expandedDate, '2026-11-01');
      expect(viewModel.state.value.dayStatus, StatisticsStatus.loading);
      expect(viewModel.state.value.dayRuns, isEmpty);
    });

    test('toggleDay shows a cached day without reading again', () async {
      viewModel.toggleDay('2026-10-31');
      repository.dayReads[0].complete(const Success([run]));
      await settle();
      viewModel.toggleDay('2026-10-31');
      viewModel.toggleDay('2026-10-31');
      expect(viewModel.state.value.dayStatus, StatisticsStatus.content);
      expect(viewModel.state.value.dayRuns, [run]);
      expect(repository.dayReadDates, ['2026-10-31']);
    });

    test('a day with no runs is empty', () async {
      viewModel.toggleDay('2026-11-01');
      repository.dayReads[0].complete(const Success([]));
      await settle();
      expect(viewModel.state.value.dayStatus, StatisticsStatus.empty);
      viewModel.toggleDay('2026-11-01');
      viewModel.toggleDay('2026-11-01');
      expect(viewModel.state.value.dayStatus, StatisticsStatus.empty);
      expect(repository.dayReadDates, ['2026-11-01']);
    });

    test('a failed day shows an error and retryDay loads it again', () async {
      viewModel.toggleDay('2026-10-31');
      repository.dayReads[0].complete(Failure(Exception('failed')));
      await settle();
      expect(viewModel.state.value.dayStatus, StatisticsStatus.error);

      final retry = viewModel.retryDay();
      expect(viewModel.state.value.dayStatus, StatisticsStatus.loading);
      repository.dayReads[1].complete(const Success([run]));
      await retry;
      expect(viewModel.state.value.dayStatus, StatisticsStatus.content);
      expect(viewModel.state.value.dayRuns, [run]);
      expect(repository.dayReadDates, ['2026-10-31', '2026-10-31']);
    });

    test('retryDay does nothing when no day is open', () async {
      await viewModel.retryDay();
      expect(repository.dayReadDates, isEmpty);
    });

    test('ignores a day result after it closed, another opened or disposal', () async {
      viewModel.toggleDay('2026-10-31');
      viewModel.toggleDay('2026-10-31');
      repository.dayReads[0].complete(const Success([run]));
      await settle();
      expect(viewModel.state.value.expandedDate, isNull);
      expect(viewModel.state.value.dayRuns, isEmpty);

      viewModel.toggleDay('2026-10-31');
      viewModel.toggleDay('2026-11-01');
      repository.dayReads[1].complete(const Success([run]));
      await settle();
      expect(viewModel.state.value.expandedDate, '2026-11-01');
      expect(viewModel.state.value.dayStatus, StatisticsStatus.loading);
      expect(viewModel.state.value.dayRuns, isEmpty);

      final repo = FakeActivityRepository();
      final vm = StatisticsViewModel(repo);
      addTearDown(repo.closeChanges);
      repo.reads[0].complete(const Success([first]));
      await settle();
      vm.toggleDay('2026-10-31');
      vm.dispose();
      repo.dayReads[0].complete(const Success([run]));
      await settle();
    });

    test('changes and refresh close the open day and clear the cache', () async {
      viewModel.toggleDay('2026-10-31');
      repository.dayReads[0].complete(const Success([run]));
      await settle();

      repository.controller.add(null);
      expect(viewModel.state.value.expandedDate, isNull);
      expect(viewModel.state.value.dayRuns, isEmpty);
      repository.reads[1].complete(const Success([first]));
      await settle();
      viewModel.toggleDay('2026-10-31');
      expect(viewModel.state.value.dayStatus, StatisticsStatus.loading);
      expect(repository.dayReadDates.length, 2);
      repository.dayReads[1].complete(const Success([run]));
      await settle();

      final refresh = viewModel.refresh();
      expect(viewModel.state.value.expandedDate, isNull);
      repository.reads[2].complete(const Success([first]));
      await refresh;
      viewModel.toggleDay('2026-10-31');
      expect(viewModel.state.value.dayStatus, StatisticsStatus.loading);
      expect(repository.dayReadDates.length, 3);
    });
  });

  test('delete succeeds and clears the busy flag', () async {
    final busy = <bool>[];
    viewModel.state.addListener(() => busy.add(viewModel.state.value.isDeleting));

    final delete = viewModel.deleteStatistics();
    expect(viewModel.state.value.isDeleting, isTrue);
    repository.deleteResults.single.complete(const Success(null));

    expect(await delete, isTrue);
    expect(viewModel.state.value.isDeleting, isFalse);
    expect(busy, [true, false]);
  });

  test('failed delete returns false', () async {
    final delete = viewModel.deleteStatistics();
    repository.deleteResults.single.complete(Failure(Exception('failed')));

    expect(await delete, isFalse);
    expect(viewModel.state.value.isDeleting, isFalse);
  });

  test('a second delete while busy is ignored', () async {
    final first = viewModel.deleteStatistics();
    final second = await viewModel.deleteStatistics();

    expect(second, isFalse);
    expect(repository.deleteCalls, 1);
    repository.deleteResults.single.complete(const Success(null));
    expect(await first, isTrue);
  });
}
