import 'package:flutter/material.dart';

/// Digit styles without a color, so they take the theme text color.
abstract final class AppTextStyles {
  static const TextStyle stopwatchTime = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.bold,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const TextStyle timerPhase = TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2);
  static const TextStyle timerInfo = TextStyle(fontSize: 18);

  static const TextStyle pickerSelected = TextStyle(fontSize: 32, fontWeight: FontWeight.bold);
  static const TextStyle pickerUnselected = TextStyle(fontSize: 24);
  static const TextStyle pickerSeparator = TextStyle(fontSize: 32, fontWeight: FontWeight.bold);
}
