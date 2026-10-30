import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/settings/settings_view_model.dart';
import 'package:sport_timer/features/timer/timer_params.dart';
import 'package:sport_timer/features/user/user_repository.dart';
import 'package:sport_timer/presentation/login/login_page.dart';

import 'presentation/home/home.dart';
import 'presentation/timer/timer.dart';
import 'presentation/timer_styles/timer_styles.dart';

enum RoutePath {
  login('/'),
  home('/home'),
  timer('/timer'),
  timerStyles('/timer-styles');

  final String value;

  const RoutePath(this.value);
}

class Routes {
  static final router = GoRouter(
    routes: [
      GoRoute(
        path: RoutePath.login.value,
        name: RoutePath.login.value,
        // Runs before the page is built, so a signed-in user never sees the login page.
        redirect: (context, state) => getIt<UserRepository>().isUserLoggedIn() ? RoutePath.home.value : null,
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
      GoRoute(
        path: RoutePath.timerStyles.value,
        name: RoutePath.timerStyles.value,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: TimerStylesPage(viewModel: state.extra as SettingsViewModel),
        ),
      ),
    ],
  );
}
