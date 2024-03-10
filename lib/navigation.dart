import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'presentation/home/home.dart';
import 'presentation/timer/timer.dart';
import 'presentation/widgets/stopwatch_widget.dart';

enum RoutePath {
  home('/'),
  timer('/timer');

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
        path: RoutePath.timer.value,
        name: RoutePath.timer.value,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: TimerPage(timerParams: state.extra as TimerParams),
        ),
      ),
    ],
  );
}
