import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/settings/domain/settings_repository.dart';
import 'package:sport_timer/features/settings/domain/timer_configuration.dart';
import 'package:sport_timer/features/settings/domain/timer_settings.dart';
import 'package:sport_timer/features/settings/presentation/settings_view_model.dart';
import 'package:sport_timer/features/settings/domain/timer_style.dart';
import 'package:sport_timer/features/templates/domain/built_in_templates.dart';
import 'package:sport_timer/features/templates/domain/workout_template.dart';
import 'package:sport_timer/features/timer/presentation/timer_state.dart';
import 'package:sport_timer/features/timer/domain/audio_manager.dart';
import 'package:sport_timer/features/timer/domain/background_keep_alive.dart';
import 'package:sport_timer/features/timer/domain/timer_activity_recorder.dart';
import 'package:sport_timer/features/timer/domain/timer_params.dart';
import 'package:sport_timer/features/timer/presentation/timer_page.dart';
import 'package:sport_timer/features/timer/domain/timer_status.dart';
import 'package:sport_timer/features/user/domain/user_repository.dart';
import 'package:sport_timer/features/user/domain/app_user.dart';
import 'package:sport_timer/l10n/app_localizations.dart';
import 'package:sport_timer/features/home/presentation/home_page.dart';
import 'package:sport_timer/features/login/presentation/login_page.dart';
import 'package:sport_timer/features/timer/presentation/widgets/full_color_timer_view.dart';
import 'package:sport_timer/features/timer/presentation/widgets/ring_timer_view.dart';
import 'package:sport_timer/features/timer/presentation/widgets/rounds_strip_timer_view.dart';
import 'package:sport_timer/features/settings/presentation/timer_styles/timer_styles_page.dart';
import 'package:sport_timer/features/templates/presentation/templates_page.dart';
import 'package:sport_timer/shared/presentation/theme/sport_theme.dart';

typedef _WidgetFactory = Widget Function();

const Size _phoneSize = Size(390, 844);
const BoxConstraints _pairConstraints = BoxConstraints(
  minWidth: 840,
  maxWidth: 840,
  maxHeight: 960,
);

const TimerSettings _customSettings = TimerSettings(
  preparationTime: Duration(seconds: 10),
  roundTime: Duration(minutes: 1, seconds: 30),
  restTime: Duration(seconds: 15),
  rounds: 3,
);

final WorkoutTemplate _hyroxTemplate = builtInTemplates.firstWhere(
  (template) => template.id == TemplateId.hyrox,
);

class _FakeUserRepository implements UserRepository {
  final AppUser _user;

  const _FakeUserRepository(this._user);

  @override
  AppUser? getCurrentUser() => _user;

  @override
  bool isUserLoggedIn() => false;

  @override
  Future<Result<void>> signInWithGoogle() async => const Success(null);

  @override
  Future<Result<void>> signOut() async => const Success(null);
}

class _FakeSettingsRepository implements SettingsRepository {
  TimerSettings storedSettings = _customSettings;
  String? selectedTemplateId;
  TimerStyle storedStyle = TimerStyle.ring;

  @override
  Future<Result<TimerConfiguration>> getTimerConfiguration() async {
    return Success(TimerConfiguration(storedSettings, selectedTemplateId));
  }

  @override
  Future<Result<void>> saveTimerConfiguration(
    TimerConfiguration configuration,
  ) async {
    storedSettings = configuration.settings;
    selectedTemplateId = configuration.selectedTemplateId;
    return const Success(null);
  }

  @override
  Future<Result<TimerSettings>> getTimerSettings() async {
    return Success(storedSettings);
  }

  @override
  Future<Result<void>> saveTimerSettings(TimerSettings settings) async {
    storedSettings = settings;
    return const Success(null);
  }

  @override
  Future<Result<TimerStyle>> getTimerStyle() async {
    return Success(storedStyle);
  }

  @override
  Future<Result<void>> saveTimerStyle(TimerStyle style) async {
    storedStyle = style;
    return const Success(null);
  }
}

class _UnusedAudioManager implements AudioManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedKeepAlive implements BackgroundKeepAlive {
  @override
  Future<void> stop() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailedActivityRecorder implements TimerActivityRecorder {
  @override
  Result<TimerActivityRun> start(TimerParams params) => Failure(Exception('No signed-in account'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _phoneFrame({
  required ThemeData theme,
  required Widget child,
}) {
  return SizedBox(
    width: _phoneSize.width,
    height: _phoneSize.height,
    child: MediaQuery(
      data: const MediaQueryData(size: _phoneSize),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
}

GoldenTestGroup _lightAndDarkGroup({
  required _WidgetFactory builder,
}) {
  return GoldenTestGroup(
    columns: 2,
    children: [
      GoldenTestScenario(
        name: 'Light',
        child: _phoneFrame(
          theme: SportTheme.light,
          child: builder(),
        ),
      ),
      GoldenTestScenario(
        name: 'Dark',
        child: _phoneFrame(
          theme: SportTheme.dark,
          child: builder(),
        ),
      ),
    ],
  );
}

Widget _timerScaffold({
  required TimerStyle style,
  required TimerState state,
}) {
  void noop() {}
  return Scaffold(
    body: switch (style) {
      TimerStyle.ring => RingTimerView(
          state: state,
          onTogglePause: noop,
        ),
      TimerStyle.fullColor => FullColorTimerView(
          state: state,
          onTogglePause: noop,
        ),
      TimerStyle.roundsStrip => RoundsStripTimerView(
          state: state,
          onTogglePause: noop,
        ),
    },
  );
}

Interaction _tapInBothFrames(Finder finder) {
  return (tester) async {
    final matches = finder.evaluate().toList();
    for (final element in matches) {
      await tester.tap(
        find.byElementPredicate((candidate) => candidate == element),
      );
      await tester.pumpAndSettle();
    }
    return null;
  };
}

void main() {
  late _FakeSettingsRepository settingsRepository;

  AppUser buildFixtureUser() {
    return const AppUser(
      displayName: 'Alex Runner',
      email: 'alex@example.com',
    );
  }

  void configureFakeDependencies({
    TimerSettings settings = _customSettings,
    String? selectedTemplateId,
    TimerStyle style = TimerStyle.ring,
  }) {
    settingsRepository
      ..storedSettings = settings
      ..selectedTemplateId = selectedTemplateId
      ..storedStyle = style;
  }

  setUp(() async {
    await getIt.reset();
    settingsRepository = _FakeSettingsRepository();
    getIt.registerSingleton<UserRepository>(
      _FakeUserRepository(buildFixtureUser()),
    );
    getIt.registerSingleton<SettingsRepository>(settingsRepository);
    getIt.registerSingleton<AudioManager>(_UnusedAudioManager());
    getIt.registerSingleton<BackgroundKeepAlive>(_UnusedKeepAlive());
    getIt.registerSingleton<TimerActivityRecorder>(_FailedActivityRecorder());
  });

  tearDown(() async {
    await getIt.reset();
  });

  unawaited(
    AlchemistConfig.runWithConfig(
      config: AlchemistConfig(
        ciGoldensConfig: const CiGoldensConfig(enabled: false),
        platformGoldensConfig: PlatformGoldensConfig(
          enabled: !const bool.fromEnvironment('CI'),
          obscureText: false,
          renderShadows: true,
          platforms: {HostPlatform.macOS},
          filePathResolver: (fileName, _) => 'goldens/$fileName.png',
        ),
      ),
      run: () {
        group('UI snapshot reference', () {
          goldenTest(
            'login page',
            fileName: 'login',
            constraints: _pairConstraints,
            builder: () => _lightAndDarkGroup(
              builder: () => const LoginPage(),
            ),
          );

          goldenTest(
            'home setup with custom settings',
            fileName: 'setup_custom',
            constraints: _pairConstraints,
            builder: () {
              configureFakeDependencies();
              return _lightAndDarkGroup(
                builder: () => const HomePage(),
              );
            },
          );

          goldenTest(
            'home setup with selected template chip',
            fileName: 'setup_template_selected',
            constraints: _pairConstraints,
            builder: () {
              configureFakeDependencies(
                settings: _hyroxTemplate.settings,
                selectedTemplateId: _hyroxTemplate.id.name,
              );
              return _lightAndDarkGroup(
                builder: () => const HomePage(),
              );
            },
          );

          goldenTest(
            'home setup with work duration wheel picker open',
            fileName: 'setup_time_picker',
            constraints: _pairConstraints,
            whilePerforming: _tapInBothFrames(find.text('Work')),
            builder: () {
              configureFakeDependencies();
              return _lightAndDarkGroup(
                builder: () => const HomePage(),
              );
            },
          );

          goldenTest(
            'home setup with rounds wheel picker open',
            fileName: 'setup_rounds_picker',
            constraints: _pairConstraints,
            whilePerforming: _tapInBothFrames(find.text('Rounds')),
            builder: () {
              configureFakeDependencies();
              return _lightAndDarkGroup(
                builder: () => const HomePage(),
              );
            },
          );

          goldenTest(
            'home with navigation drawer open',
            fileName: 'home_drawer',
            constraints: _pairConstraints,
            whilePerforming: _tapInBothFrames(find.byIcon(Icons.menu)),
            builder: () {
              configureFakeDependencies();
              return _lightAndDarkGroup(
                builder: () => const HomePage(),
              );
            },
          );

          goldenTest(
            'home with account sheet open',
            fileName: 'account_sheet',
            constraints: _pairConstraints,
            whilePerforming: _tapInBothFrames(
              find.byTooltip('Account, Alex Runner'),
            ),
            builder: () {
              configureFakeDependencies();
              return _lightAndDarkGroup(
                builder: () => const HomePage(),
              );
            },
          );

          goldenTest(
            'home with sign out confirmation dialog open',
            fileName: 'account_sign_out_dialog',
            constraints: _pairConstraints,
            whilePerforming: (tester) async {
              await _tapInBothFrames(
                find.byTooltip('Account, Alex Runner'),
              )(tester);
              final tiles = tester.widgetList<ListTile>(
                find.widgetWithText(ListTile, 'Sign out'),
              );
              for (final tile in tiles.toList()) {
                tile.onTap?.call();
              }
              await tester.pumpAndSettle();
              return null;
            },
            builder: () {
              configureFakeDependencies();
              return _lightAndDarkGroup(
                builder: () => const HomePage(),
              );
            },
          );

          goldenTest(
            'templates page with Hyrox selected',
            fileName: 'templates_selected',
            constraints: _pairConstraints,
            builder: () {
              configureFakeDependencies(
                settings: _hyroxTemplate.settings,
                selectedTemplateId: _hyroxTemplate.id.name,
              );
              return _lightAndDarkGroup(
                builder: () {
                  final viewModel = SettingsViewModel(getIt())..loadSettings();
                  addTearDown(viewModel.dispose);
                  return TemplatesPage(viewModel: viewModel);
                },
              );
            },
          );

          goldenTest(
            'templates page with custom settings row',
            fileName: 'templates_custom',
            constraints: _pairConstraints,
            builder: () {
              configureFakeDependencies();
              return _lightAndDarkGroup(
                builder: () {
                  final viewModel = SettingsViewModel(getIt())..loadSettings();
                  addTearDown(viewModel.dispose);
                  return TemplatesPage(viewModel: viewModel);
                },
              );
            },
          );

          goldenTest(
            'home statistics tab',
            fileName: 'statistics',
            constraints: _pairConstraints,
            whilePerforming: _tapInBothFrames(find.text('Statistics')),
            builder: () {
              configureFakeDependencies();
              return _lightAndDarkGroup(
                builder: () => const HomePage(),
              );
            },
          );

          goldenTest(
            'timer styles page',
            fileName: 'timer_styles',
            constraints: _pairConstraints,
            builder: () {
              configureFakeDependencies();
              return _lightAndDarkGroup(
                builder: () {
                  final viewModel = SettingsViewModel(getIt())..loadSettings();
                  addTearDown(viewModel.dispose);
                  return TimerStylesPage(viewModel: viewModel);
                },
              );
            },
          );

          goldenTest(
            'timer could not start',
            fileName: 'timer_start_error',
            constraints: _pairConstraints,
            builder: () => _lightAndDarkGroup(
              builder: () => const TimerPage(
                params: TimerParams(
                  preparationTime: Duration(seconds: 10),
                  roundTime: Duration(minutes: 1),
                  restTime: Duration(seconds: 15),
                  rounds: 3,
                  style: TimerStyle.ring,
                ),
              ),
            ),
          );

          goldenTest(
            'timer ring style in preparation phase',
            fileName: 'timer_ring_preparation',
            constraints: _pairConstraints,
            builder: () => _lightAndDarkGroup(
              builder: () => _timerScaffold(
                style: TimerStyle.ring,
                state: const TimerState(
                  currentSeconds: 7,
                  totalSeconds: 307,
                  currentRound: 1,
                  totalRounds: 3,
                  stageSeconds: 10,
                  totalDuration: Duration(minutes: 5, seconds: 10),
                  timerStatus: TimerStatus.preparation,
                ),
              ),
            ),
          );

          goldenTest(
            'timer ring style in round phase',
            fileName: 'timer_ring_round',
            constraints: _pairConstraints,
            builder: () => _lightAndDarkGroup(
              builder: () => _timerScaffold(
                style: TimerStyle.ring,
                state: const TimerState(
                  currentSeconds: 72,
                  totalSeconds: 177,
                  currentRound: 2,
                  totalRounds: 3,
                  stageSeconds: 90,
                  totalDuration: Duration(minutes: 5, seconds: 10),
                  timerStatus: TimerStatus.round,
                ),
              ),
            ),
          );

          goldenTest(
            'timer ring style in rest phase',
            fileName: 'timer_ring_rest',
            constraints: _pairConstraints,
            builder: () => _lightAndDarkGroup(
              builder: () => _timerScaffold(
                style: TimerStyle.ring,
                state: const TimerState(
                  currentSeconds: 10,
                  totalSeconds: 100,
                  currentRound: 3,
                  totalRounds: 3,
                  stageSeconds: 15,
                  totalDuration: Duration(minutes: 5, seconds: 10),
                  timerStatus: TimerStatus.rest,
                ),
              ),
            ),
          );

          goldenTest(
            'timer ring style paused',
            fileName: 'timer_ring_paused',
            constraints: _pairConstraints,
            builder: () => _lightAndDarkGroup(
              builder: () => _timerScaffold(
                style: TimerStyle.ring,
                state: const TimerState(
                  currentSeconds: 45,
                  totalSeconds: 150,
                  currentRound: 2,
                  totalRounds: 3,
                  stageSeconds: 90,
                  totalDuration: Duration(minutes: 5, seconds: 10),
                  timerStatus: TimerStatus.round,
                  isPaused: true,
                ),
              ),
            ),
          );

          goldenTest(
            'timer ring style finished',
            fileName: 'timer_ring_finished',
            constraints: _pairConstraints,
            builder: () => _lightAndDarkGroup(
              builder: () => _timerScaffold(
                style: TimerStyle.ring,
                state: const TimerState(
                  currentSeconds: 0,
                  totalSeconds: 0,
                  currentRound: 3,
                  totalRounds: 3,
                  stageSeconds: 90,
                  totalDuration: Duration(minutes: 5, seconds: 10),
                  timerStatus: TimerStatus.finished,
                ),
              ),
            ),
          );

          goldenTest(
            'timer full color style in round phase',
            fileName: 'timer_full_color_round',
            constraints: _pairConstraints,
            builder: () => _lightAndDarkGroup(
              builder: () => _timerScaffold(
                style: TimerStyle.fullColor,
                state: const TimerState(
                  currentSeconds: 72,
                  totalSeconds: 177,
                  currentRound: 2,
                  totalRounds: 3,
                  stageSeconds: 90,
                  totalDuration: Duration(minutes: 5, seconds: 10),
                  timerStatus: TimerStatus.round,
                ),
              ),
            ),
          );

          goldenTest(
            'timer full color style paused in rest phase',
            fileName: 'timer_full_color_paused',
            constraints: _pairConstraints,
            builder: () => _lightAndDarkGroup(
              builder: () => _timerScaffold(
                style: TimerStyle.fullColor,
                state: const TimerState(
                  currentSeconds: 10,
                  totalSeconds: 100,
                  currentRound: 3,
                  totalRounds: 3,
                  stageSeconds: 15,
                  totalDuration: Duration(minutes: 5, seconds: 10),
                  timerStatus: TimerStatus.rest,
                  isPaused: true,
                ),
              ),
            ),
          );

          goldenTest(
            'timer rounds strip style in round phase',
            fileName: 'timer_rounds_strip_round',
            constraints: _pairConstraints,
            builder: () => _lightAndDarkGroup(
              builder: () => _timerScaffold(
                style: TimerStyle.roundsStrip,
                state: const TimerState(
                  currentSeconds: 72,
                  totalSeconds: 177,
                  currentRound: 2,
                  totalRounds: 3,
                  stageSeconds: 90,
                  totalDuration: Duration(minutes: 5, seconds: 10),
                  timerStatus: TimerStatus.round,
                ),
              ),
            ),
          );

          goldenTest(
            'timer rounds strip style paused',
            fileName: 'timer_rounds_strip_paused',
            constraints: _pairConstraints,
            builder: () => _lightAndDarkGroup(
              builder: () => _timerScaffold(
                style: TimerStyle.roundsStrip,
                state: const TimerState(
                  currentSeconds: 45,
                  totalSeconds: 150,
                  currentRound: 2,
                  totalRounds: 3,
                  stageSeconds: 90,
                  totalDuration: Duration(minutes: 5, seconds: 10),
                  timerStatus: TimerStatus.round,
                  isPaused: true,
                ),
              ),
            ),
          );
        });
        return null;
      },
    ),
  );
}
