part of '../statistics.dart';

@injectable
class StatisticsCubit extends Cubit<StatisticsState> {
  StatisticsCubit(this.repository)
      : super(
          const StatisticsState(
            status: StatisticsStatus.initial,
            statistics: [],
          ),
        );

  final StatisticsRepository repository;

  Future<void> getAllStatistics() async {
    emit(state.copyWith(status: StatisticsStatus.loading));
    final result = await repository.getStatistics();
    result.fold(
      (items) => emit(
        StatisticsState(
          status: StatisticsStatus.success,
          statistics: items,
        ),
      ),
      (exception) => emit(
        state.copyWith(
          status: StatisticsStatus.failure,
          exception: exception,
        ),
      ),
    );
  }
}
