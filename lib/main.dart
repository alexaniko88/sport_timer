import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/firebase_options.dart';
import 'package:sport_timer/navigation.dart';
import 'package:sport_timer/theme/sport_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sport Timer',
      routeInformationProvider: Routes.router.routeInformationProvider,
      routeInformationParser: Routes.router.routeInformationParser,
      routerDelegate: Routes.router.routerDelegate,
      theme: SportTheme.light,
      darkTheme: SportTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
    );
  }
}
