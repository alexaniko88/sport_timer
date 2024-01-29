import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/home/home.dart';
import 'presentation/timer/timer.dart';

enum RoutePath {
  home('/'),
  timerSettings('/timer_settings');

  final String value;

  const RoutePath(this.value);
}
class Routes {
  static final router = GoRouter(
    routes: [
      GoRoute(
        path: RoutePath.home.value,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const HomePage(),
        ),
      ),
      GoRoute(
        path: RoutePath.timerSettings.value,

        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const TimerSettingsPage(),
        ),
      ),
    ],
  );
}
