import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/navigation.dart';
import 'package:sport_timer/observers/simple_bloc_observer.dart';
import 'package:sport_timer/theme/sport_theme.dart';

import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = SimpleBlocObserver();
  configureDependencies();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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