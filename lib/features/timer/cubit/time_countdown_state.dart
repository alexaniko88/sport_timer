part of '../timer.dart';

@freezed
class TimeCountdownState with _$TimeCountdownState {
  const factory TimeCountdownState({
    required String formattedTime,
    required double currentTime,
    required AvailabilitySlotsStatus availabilitySlotsStatus,
  }) = _TimeCountdownState;
}

enum AvailabilitySlotsStatus {
  initial,
  getTime,
  countdownFinished,
}