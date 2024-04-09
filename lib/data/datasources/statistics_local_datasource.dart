part of 'datasources.dart';

abstract class StatisticsDatasource {
  Future<Result<bool, AppException>> insertStatistic(StatisticModel statistic);

  Future<Result<List<StatisticDTO>, AppException>> getStatistics();
}

const String _collectionPath = "statistics";

@LazySingleton(as: StatisticsDatasource)
class StatisticsLocalDatasource extends StatisticsDatasource {
  StatisticsLocalDatasource(this.firestore);

  final FirebaseFirestore firestore;

  @override
  Future<Result<List<StatisticDTO>, AppException>> getStatistics() async {
    try {
      final snapshot = await firestore.collection(_collectionPath).get();
      return Result.success(snapshot.docs.map((snapshot) => StatisticDTO.fromJson(snapshot.data())).toList());
    } on Exception catch (e) {
      return Result.failure(
        AppException(
          message: e.toString(),
          statusCode: StatusCode.unknownError,
          identifier: 'getStatistics',
        ),
      );
    }
  }

  @override
  Future<Result<bool, AppException>> insertStatistic(StatisticModel statistic) async {
    try {
      final reference = await firestore.collection(_collectionPath).add(statistic.toJson());
      printLog("$runtimeType:: insertStatistic with ref ID -> ${reference.id}");
      return Result.success(true);
    } on Exception catch (e) {
      return Result.failure(
        AppException(
          message: e.toString(),
          statusCode: StatusCode.unknownError,
          identifier: 'insertStatistic',
        ),
      );
    }
  }
}
