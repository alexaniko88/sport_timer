part of 'repositories.dart';

@LazySingleton(as: StatisticsRepository)
class StatisticsRepositoryImpl implements StatisticsRepository {
  const StatisticsRepositoryImpl(this.datasource);

  final StatisticsDatasource datasource;

  @override
  Future<Result<List<StatisticModel>, AppException>> getStatistics() async {
    final result = await datasource.getStatistics();
    return result.fold(
      (success) => Result.success(success.map((dto) => dto.toModel()).toList()),
      (failure) => Result.failure(failure),
    );
  }

  @override
  Future<Result<bool, AppException>> insertStatistic(StatisticModel statistic) async {
    final result = await datasource.insertStatistic(statistic);
    return result.fold(
      (success) => Result.success(success),
      (failure) => Result.failure(failure),
    );
  }
}
