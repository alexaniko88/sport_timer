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
}
