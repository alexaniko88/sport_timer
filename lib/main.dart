import 'package:flutter/material.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/navigation.dart';
import 'package:sport_timer/theme/sport_theme.dart';

void main() {
  configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      routeInformationProvider: Routes.router.routeInformationProvider,
      routeInformationParser: Routes.router.routeInformationParser,
      routerDelegate: Routes.router.routerDelegate,
      theme: SportTheme.light,
      debugShowCheckedModeBanner: false,
    );
  }
}