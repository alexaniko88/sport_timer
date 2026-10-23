import 'package:flutter/material.dart';

/// Digit styles without a color, so they take the theme text color.
abstract final class AppTextStyles {
  static const TextStyle stopwatchTime = TextStyle(fontSize: 120);
  static const TextStyle stopwatchRound = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const TextStyle stopwatchTotal = TextStyle(fontSize: 25);

  static const TextStyle pickerRoundsSelected = TextStyle(fontSize: 35, fontWeight: FontWeight.bold);
  static const TextStyle pickerRoundsUnselected = TextStyle(fontSize: 20);
  static const TextStyle pickerTimeSelected = TextStyle(fontSize: 32, fontWeight: FontWeight.bold);
  static const TextStyle pickerTimeUnselected = TextStyle(fontSize: 24);
  static const TextStyle pickerSeparator = TextStyle(fontSize: 40, fontWeight: FontWeight.bold);
}
