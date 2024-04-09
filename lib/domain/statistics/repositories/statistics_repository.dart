import 'package:sport_timer/domain/statistics/statistics.dart';
import 'package:sport_timer/shared/shared.dart';

abstract class StatisticsRepository {
  Future<Result<bool, AppException>> insertStatistic(StatisticModel statistic);

  Future<Result<List<StatisticModel>, AppException>> getStatistics();
}