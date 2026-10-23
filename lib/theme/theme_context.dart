import 'package:flutter/material.dart';
import 'package:sport_timer/theme/timer_colors.dart';

extension ThemeContext on BuildContext {
  TimerColors get timerColors => Theme.of(this).extension<TimerColors>() ?? TimerColors.light;
}
