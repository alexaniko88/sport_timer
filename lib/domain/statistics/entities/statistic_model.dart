part of '../statistics.dart';

//ignore_for_file: invalid_annotation_target
@freezed
class StatisticModel with _$StatisticModel{
  @JsonSerializable(explicitToJson: true)

  const StatisticModel._();

  const factory StatisticModel({
    required String userId,
    required int rounds,
    required int totalRestTime,
    required int totalRoundTime,
    required int totalTime,
    required DateTime date,
  }) = _StatisticModel;

  factory StatisticModel.fromJson(Map<String, dynamic> json) => _$StatisticModelFromJson(json);
}