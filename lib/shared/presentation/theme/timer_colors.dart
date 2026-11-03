import 'package:flutter/material.dart';
import 'package:sport_timer/shared/presentation/theme/app_palette.dart';

class TimerColors extends ThemeExtension<TimerColors> {
  static const TimerColors light = TimerColors(
    preparation: AppPalette.yellow,
    round: AppPalette.redAccent,
    rest: AppPalette.blueAccent,
    finished: AppPalette.green,
    roundsCount: AppPalette.orangeAccent,
    roundCounterBorder: AppPalette.orange,
    onAccent: AppPalette.white,
    onPhase: AppPalette.darkOnAccent,
    onFinished: AppPalette.darkOnAccent,
  );

  static const TimerColors dark = TimerColors(
    preparation: AppPalette.yellowLight,
    round: AppPalette.redAccentLight,
    rest: AppPalette.blueAccentLight,
    finished: AppPalette.greenDark,
    roundsCount: AppPalette.orangeAccentLight,
    roundCounterBorder: AppPalette.orangeLight,
    onAccent: AppPalette.darkOnAccent,
    onPhase: AppPalette.darkOnAccent,
    onFinished: AppPalette.white,
  );

  final Color preparation;
  final Color round;
  final Color rest;
  final Color finished;
  final Color roundsCount;
  final Color roundCounterBorder;
  final Color onAccent;
  final Color onPhase;
  final Color onFinished;

  const TimerColors({
    required this.preparation,
    required this.round,
    required this.rest,
    required this.finished,
    required this.roundsCount,
    required this.roundCounterBorder,
    required this.onAccent,
    required this.onPhase,
    required this.onFinished,
  });

  @override
  TimerColors copyWith({
    Color? preparation,
    Color? round,
    Color? rest,
    Color? finished,
    Color? roundsCount,
    Color? roundCounterBorder,
    Color? onAccent,
    Color? onPhase,
    Color? onFinished,
  }) {
    return TimerColors(
      preparation: preparation ?? this.preparation,
      round: round ?? this.round,
      rest: rest ?? this.rest,
      finished: finished ?? this.finished,
      roundsCount: roundsCount ?? this.roundsCount,
      roundCounterBorder: roundCounterBorder ?? this.roundCounterBorder,
      onAccent: onAccent ?? this.onAccent,
      onPhase: onPhase ?? this.onPhase,
      onFinished: onFinished ?? this.onFinished,
    );
  }

  @override
  TimerColors lerp(ThemeExtension<TimerColors>? other, double t) {
    if (other is! TimerColors) return this;
    return TimerColors(
      preparation: Color.lerp(preparation, other.preparation, t)!,
      round: Color.lerp(round, other.round, t)!,
      rest: Color.lerp(rest, other.rest, t)!,
      finished: Color.lerp(finished, other.finished, t)!,
      roundsCount: Color.lerp(roundsCount, other.roundsCount, t)!,
      roundCounterBorder: Color.lerp(roundCounterBorder, other.roundCounterBorder, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      onPhase: Color.lerp(onPhase, other.onPhase, t)!,
      onFinished: Color.lerp(onFinished, other.onFinished, t)!,
    );
  }
}
