import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/domain/statistics/statistics.dart';
import 'package:sport_timer/domain/timer/timer.dart';
import 'package:sport_timer/presentation/login/login.dart';

import 'presentation/timer/timer.dart';

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
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => getIt<StatisticsCubit>(),
                ),
              ],
              child: const LoginPage(),
            )),
      ),
      GoRoute(
        path: RoutePath.timer.value,
        name: RoutePath.timer.value,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (context) => getIt<TimeCountdownCubit>(param1: state.extra as TimerParams)..start(),
            child: const TimerPage(),
          ),
        ),
      ),
    ],
  );
}
