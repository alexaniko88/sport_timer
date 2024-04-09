import 'package:sport_timer/data/dtos/dtos.dart';
import 'package:sport_timer/domain/statistics/statistics.dart';

extension StatisticExtension on StatisticDTO {
  StatisticModel toModel() => StatisticModel(
        userId: userId,
        date: date,
        rounds: rounds,
        totalRestTime: totalRestTime,
        totalRoundTime: totalRoundTime,
        totalTime: totalTime,
      );
}
