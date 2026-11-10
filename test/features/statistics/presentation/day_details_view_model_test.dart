import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/domain/run_activity_summary.dart';
import 'package:sport_timer/features/statistics/domain/timer_session.dart';
import 'package:sport_timer/features/statistics/presentation/day_details_view_model.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_state.dart';

class _Repository implements ActivityRepository {
  final controller = StreamController<void>.broadcast(sync: true);
  final reads = <Completer<Result<List<RunActivitySummary>>>>[];
  final dates = <String>[];

  @override
  Stream<void> get changes => controller.stream;

  Future<void> closeChanges() => controller.close();

  @override
  Future<Result<List<RunActivitySummary>>> readDayActivity(String localDate) {
    dates.add(localDate);
    final read = Completer<Result<List<RunActivitySummary>>>();
    reads.add(read);
    return read.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const date = '2026-11-02';
  const first = RunActivitySummary(
    session: TimerSession(
      id: 'one',
      accountId: 'a',
      startedAtUtcMs: 2,
      preparationDurationMs: 0,
      workDurationMs: 45000,
      restDurationMs: 15000,
      roundCount: 3,
    ),
    activity: DailyActivity(localDate: date, roundCount: 1, workDurationMs: 45000, restDurationMs: 0),
  );
  const second = RunActivitySummary(
    session: TimerSession(
      id: 'two',
      accountId: 'a',
      startedAtUtcMs: 1,
      preparationDurationMs: 0,
      workDurationMs: 30000,
      restDurationMs: 10000,
      roundCount: 5,
    ),
    activity: DailyActivity(localDate: date, roundCount: 2, workDurationMs: 60000, restDurationMs: 10000),
  );
  late _Repository repository;
  late DayDetailsViewModel viewModel;

  setUp(() {
    repository = _Repository();
    viewModel = DayDetailsViewModel(repository, date);
  });
  tearDown(() async {
    viewModel.dispose();
    await repository.closeChanges();
  });

  test('loads selected date and derives summary from the displayed runs', () async {
    expect(repository.dates, [date]);
    expect(viewModel.state.value.status, StatisticsStatus.loading);
    repository.reads.single.complete(const Success([first, second]));
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.state.value.runs, [first, second]);
    expect(
      viewModel.state.value.summary(date),
      const DailyActivity(localDate: date, roundCount: 3, workDurationMs: 105000, restDurationMs: 10000),
    );
    final refresh = viewModel.refresh();
    expect(viewModel.state.value.runs, isEmpty);
    repository.reads.last.complete(const Success([]));
    await refresh;
    expect(viewModel.state.value.status, StatisticsStatus.empty);
  });

  test('retries errors and clears old account data while ignoring stale results', () async {
    repository.reads[0].complete(Failure(Exception('failed')));
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.state.value.status, StatisticsStatus.error);
    final retry = viewModel.refresh();
    repository.reads[1].complete(const Success([first]));
    await retry;
    repository.controller.add(null);
    expect(viewModel.state.value.runs, isEmpty);
    repository.controller.add(null);
    repository.reads[3].complete(const Success([second]));
    await Future<void>.delayed(Duration.zero);
    repository.reads[2].complete(const Success([first]));
    await Future<void>.delayed(Duration.zero);
    expect(viewModel.state.value.runs, [second]);
    expect(viewModel.state.value.status, StatisticsStatus.content);
  });

  test('ignores pending results after disposal', () async {
    final other = _Repository();
    final disposed = DayDetailsViewModel(other, date)..dispose();
    other.reads.single.complete(const Success([first]));
    await Future<void>.delayed(Duration.zero);
    await other.closeChanges();
    expect(disposed, isNotNull);
  });
}
