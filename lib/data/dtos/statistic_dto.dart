part of 'dtos.dart';
//ignore_for_file: invalid_annotation_target
@freezed
class StatisticDTO with _$StatisticDTO{
  @JsonSerializable(explicitToJson: true)

  const StatisticDTO._();

  const factory StatisticDTO({
    required String userId,
    required int rounds,
    required int totalRestTime,
    required int totalRoundTime,
    required int totalTime,
    @TimestampSerializer() required DateTime date,
  }) = _StatisticDTO;

  factory StatisticDTO.fromJson(Map<String, dynamic> json) => _$StatisticDTOFromJson(json);
}