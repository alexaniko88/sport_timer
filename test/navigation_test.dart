import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/developer/presentation/developer_tools_page.dart';
import 'package:sport_timer/features/settings/domain/settings_repository.dart';
import 'package:sport_timer/features/settings/domain/timer_configuration.dart';
import 'package:sport_timer/features/settings/domain/timer_settings.dart';
import 'package:sport_timer/features/settings/domain/timer_style.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';
import 'package:sport_timer/features/templates/domain/custom_template_repository.dart';
import 'package:sport_timer/features/user/domain/app_user.dart';
import 'package:sport_timer/features/user/domain/user_repository.dart';
import 'package:sport_timer/l10n/app_localizations.dart';
import 'package:sport_timer/navigation.dart';
import 'package:sport_timer/shared/presentation/theme/sport_theme.dart';

import 'features/statistics/fake_activity_repository.dart';
import 'features/templates/fake_custom_template_repository.dart';

class _FakeSettingsRepository implements SettingsRepository {
  TimerSettings storedSettings = const TimerSettings(
    preparationTime: Duration(seconds: 10),
    roundTime: Duration(seconds: 90),
    restTime: Duration(seconds: 15),
    rounds: 3,
  );
  String? selectedTemplateId;
  TimerStyle storedStyle = TimerStyle.ring;

  @override
  Future<Result<TimerConfiguration>> getTimerConfiguration() async {
    return Success(TimerConfiguration(storedSettings, selectedTemplateId));
  }

  @override
  Future<Result<void>> saveTimerConfiguration(TimerConfiguration configuration) async {
    storedSettings = configuration.settings;
    selectedTemplateId = configuration.selectedTemplateId;
    return const Success(null);
  }

  @override
  Future<Result<TimerSettings>> getTimerSettings() async => Success(storedSettings);

  @override
  Future<Result<void>> saveTimerSettings(TimerSettings settings) async {
    storedSettings = settings;
    return const Success(null);
  }

  @override
  Future<Result<TimerStyle>> getTimerStyle() async => Success(storedStyle);

  @override
  Future<Result<void>> saveTimerStyle(TimerStyle style) async {
    storedStyle = style;
    return const Success(null);
  }
}

class _FakeUserRepository implements UserRepository {
  @override
  AppUser? getCurrentUser() => null;

  @override
  bool isUserLoggedIn() => false;

  @override
  Future<Result<void>> signInWithGoogle() async => const Success(null);

  @override
  Future<Result<void>> signOut() async => const Success(null);
}

void main() {
  late GoRouter router;

  setUp(() async {
    await getIt.reset();
    getIt.registerSingleton<SettingsRepository>(_FakeSettingsRepository());
    getIt.registerSingleton<CustomTemplateRepository>(FakeCustomTemplateRepository());
    getIt.registerSingleton<UserRepository>(_FakeUserRepository());
    getIt.registerSingleton<ActivityRepository>(FakeEmptyActivityRepository());
    router = Routes.build(developerToolsEnabled: false);
  });

  tearDown(() async {
    router.dispose();
    await getIt.reset();
  });

  testWidgets('developer route does not exist when developer tools are disabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: SportTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    router.go(RoutePath.developer.value);
    await tester.pumpAndSettle();

    expect(find.byType(DeveloperToolsPage), findsNothing);
  });
}
