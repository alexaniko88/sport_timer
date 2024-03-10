part of 'styles.dart';

class TimerStyle extends ThemeExtension<TimerStyle> {
  final Color preparationColor,
      roundColor,
      restColor,
      finishColor,
      roundsCountColor,
      progressTextTimeStartColor,
      progressTextTimeEndColor,
      progressTimer1Color,
      progressTimer2Color,
      progressTimer3Color,
      progressTimer4Color;

  const TimerStyle({
    required this.preparationColor,
    required this.roundColor,
    required this.restColor,
    required this.finishColor,
    required this.roundsCountColor,
    required this.progressTextTimeStartColor,
    required this.progressTextTimeEndColor,
    required this.progressTimer1Color,
    required this.progressTimer2Color,
    required this.progressTimer3Color,
    required this.progressTimer4Color,
  });

  @override
  ThemeExtension<TimerStyle> copyWith({
    Color? preparationColor,
    Color? roundColor,
    Color? restColor,
    Color? finishColor,
    Color? roundsCountColor,
    Color? progressTextTimeStartColor,
    Color? progressTextTimeEndColor,
    Color? progressTimer1Color,
    Color? progressTimer2Color,
    Color? progressTimer3Color,
    Color? progressTimer4Color,
  }) =>
      TimerStyle(
        preparationColor: preparationColor ?? this.preparationColor,
        roundColor: roundColor ?? this.roundColor,
        restColor: restColor ?? this.restColor,
        finishColor: finishColor ?? this.finishColor,
        roundsCountColor: roundsCountColor ?? this.roundsCountColor,
        progressTextTimeStartColor: progressTextTimeStartColor ?? this.progressTextTimeStartColor,
        progressTextTimeEndColor: progressTextTimeEndColor ?? this.progressTextTimeEndColor,
        progressTimer1Color: progressTimer1Color ?? this.progressTimer1Color,
        progressTimer2Color: progressTimer2Color ?? this.progressTimer2Color,
        progressTimer3Color: progressTimer3Color ?? this.progressTimer3Color,
        progressTimer4Color: progressTimer4Color ?? this.progressTimer4Color,
      );

  @override
  ThemeExtension<TimerStyle> lerp(ThemeExtension<TimerStyle>? other, double t) => other ?? this;
}
