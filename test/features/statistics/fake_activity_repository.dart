import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';

class FakeEmptyActivityRepository implements ActivityRepository {
  @override
  Future<Result<void>> deleteAllActivity() async => const Success(null);

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<Result<List<DailyActivity>>> readDailyActivity() async => const Success([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
