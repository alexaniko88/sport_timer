import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/presentation/login/login_page.dart';
import 'package:sport_timer/features/timer/timer_params.dart';

import 'presentation/home/home.dart';
import 'presentation/timer/timer.dart';

enum RoutePath {
  login('/'),
  home('/home'),
  timer('/timer');

  final String value;

  const RoutePath(this.value);
}

class Routes {
  static final router = GoRouter(
    routes: [
      GoRoute(
        path: RoutePath.login.value,
        name: RoutePath.login.value,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: RoutePath.home.value,
        name: RoutePath.home.value,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const HomePage(),
        ),
      ),
      GoRoute(
        path: RoutePath.timer.value,
        name: RoutePath.timer.value,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: TimerPage(params: state.extra as TimerParams),
        ),
      ),
    ],
  );
}
