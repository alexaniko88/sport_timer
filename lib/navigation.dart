import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/login/login.dart';
import 'package:sport_timer/features/settings/settings.dart';
import 'package:sport_timer/presentation/login/login_page.dart';
import 'package:sport_timer/features/timer/timer.dart';

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
          child: BlocProvider(
            create: (context) => getIt<LoginCubit>(),
            child: const LoginPage(),
          ),
        ),
      ),
      GoRoute(
        path: RoutePath.home.value,
        name: RoutePath.home.value,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (context) => getIt<SettingsCubit>()..loadSettings(),
            child: const HomePage(),
          ),
        ),
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
