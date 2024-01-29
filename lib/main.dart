import 'package:flutter/material.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/navigation.dart';

void main() {
  configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    /*
    child: MaterialApp.router(
          routeInformationProvider: Routes.router.routeInformationProvider,
          routeInformationParser: Routes.router.routeInformationParser,
          routerDelegate: _routerDelegate,
          title: F.title,
          theme: GSTheme.lightTheme,
          localizationsDelegates: [
            ...Lt.localizationsDelegates,
            AppLocalizations.delegate,
          ],
          supportedLocales: Lt.supportedLocales,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return Column(
              children: [
                Expanded(child: EnvBanner(child: child)),
                Material(child: ConnectivityNotificationView()),
              ],
            );
          },
        ),
     */
    return MaterialApp.router(
      title: 'Flutter Demo',
      routeInformationProvider: Routes.router.routeInformationProvider,
      routeInformationParser: Routes.router.routeInformationParser,
      routerDelegate: Routes.router.routerDelegate,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}