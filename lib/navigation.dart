import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/settings/presentation/settings_view_model.dart';
import 'package:sport_timer/features/statistics/presentation/day_details_page.dart';
import 'package:sport_timer/features/timer/domain/timer_params.dart';
import 'package:sport_timer/features/user/domain/user_repository.dart';
import 'package:sport_timer/features/home/presentation/home_page.dart';
import 'package:sport_timer/features/login/presentation/login_page.dart';
import 'package:sport_timer/features/settings/presentation/timer_styles/timer_styles_page.dart';
import 'package:sport_timer/features/templates/presentation/templates_page.dart';
import 'package:sport_timer/features/timer/presentation/timer_page.dart';

enum RoutePath {
  login('/'),
  home('/home'),
  timer('/timer'),
  timerStyles('/timer-styles'),
  templates('/templates'),
  dayDetails('/day-details');

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
        path: RoutePath.dayDetails.value,
        name: RoutePath.dayDetails.value,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: DayDetailsPage(localDate: state.extra as String),
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
      GoRoute(
        path: RoutePath.templates.value,
        name: RoutePath.templates.value,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: TemplatesPage(viewModel: state.extra as SettingsViewModel),
        ),
      ),
    ],
  );
}
