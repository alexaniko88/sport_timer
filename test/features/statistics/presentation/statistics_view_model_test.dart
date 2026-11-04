import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/statistics/domain/activity_period.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_state.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_view_model.dart';

class FakeActivityRepository implements ActivityRepository {
  final controller = StreamController<void>.broadcast(sync: true);
  final reads = <Completer<Result<List<DailyActivity>>>>[];

  @override
  Stream<void> get changes => controller.stream;

  @override
  Future<Result<List<DailyActivity>>> readDailyActivity() {
    final completer = Completer<Result<List<DailyActivity>>>();
    reads.add(completer);
    return completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const first = DailyActivity(localDate: '2026-10-31', roundCount: 2, workDurationMs: 60, restDurationMs: 30);
  const second = DailyActivity(localDate: '2026-11-01', roundCount: 1, workDurationMs: 50, restDurationMs: 0);
  late FakeActivityRepository repository;
  late StatisticsViewModel viewModel;

  setUp(() {
    repository = FakeActivityRepository();
    viewModel = StatisticsViewModel(repository);
  });

  tearDown(() async {
    viewModel.dispose();
    await repository.controller.close();
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
    await separateRepository.controller.close();
  });
  test('chart controls default, navigate, and keep selection across refresh', () async {
    final repo = FakeActivityRepository();
    final vm = StatisticsViewModel(repo, clock: () => DateTime(2026, 11, 4));
    addTearDown(() async {
      vm.dispose();
      await repo.controller.close();
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
      await repo.controller.close();
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
      await repo.controller.close();
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
      await repo.controller.close();
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
}
