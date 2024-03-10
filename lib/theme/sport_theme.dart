import 'package:flutter/material.dart';
import 'package:sport_timer/theme/styles/styles.dart';

class SportTheme {
  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
      useMaterial3: true,
      extensions: const <ThemeExtension<dynamic>>[
        TimerStyle(
          preparationColor: Colors.yellow,
          roundColor: Colors.redAccent,
          restColor: Colors.blueAccent,
          finishColor: Colors.green,
          roundsCountColor: Colors.orangeAccent,
          progressTextTimeStartColor: Colors.black,
          progressTextTimeEndColor: Colors.red,
          progressTimer1Color: Colors.green,
          progressTimer2Color: Colors.yellow,
          progressTimer3Color: Colors.orange,
          progressTimer4Color: Colors.red,
        )
      ],
    );
  }
}
