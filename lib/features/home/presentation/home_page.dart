import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/account/presentation/account_view_model.dart';
import 'package:sport_timer/features/settings/presentation/settings_view_model.dart';
import 'package:sport_timer/features/settings/presentation/timer_setup_page.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_page.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_view_model.dart';
import 'package:sport_timer/features/timer/domain/timer_params.dart';
import 'package:sport_timer/navigation.dart';
import 'package:sport_timer/shared/presentation/extensions/l10n_context.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final SettingsViewModel _viewModel = SettingsViewModel(getIt());
  final AccountViewModel _accountViewModel = AccountViewModel(getIt());
  final StatisticsViewModel _statisticsViewModel = StatisticsViewModel(getIt());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel.loadSettings();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_viewModel.flushSettings());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.dispose();
    _accountViewModel.dispose();
    _statisticsViewModel.dispose();
    super.dispose();
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _openTemplates() => context.pushNamed(RoutePath.templates.value, extra: _viewModel);

  void _onDrawerDestinationSelected(int index) {
    _scaffoldKey.currentState?.closeDrawer();
    final route = index == 0 ? RoutePath.templates : RoutePath.timerStyles;
    context.pushNamed(route.value, extra: _viewModel);
  }

  void _onItemTapped(int index) {
    if (index == 1 && _selectedIndex != 1) unawaited(_statisticsViewModel.refresh());
    setState(() {
      _selectedIndex = index;
    });
  }

  void _startTimer() {
    final state = _viewModel.state.value;
    final settings = state.timerSettings;
    unawaited(_viewModel.flushSettings());
    context.pushNamed(
      RoutePath.timer.value,
      extra: TimerParams(
        preparationTime: settings.preparationTime,
        roundTime: settings.roundTime,
        restTime: settings.restTime,
        rounds: settings.rounds,
        style: state.timerStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      key: _scaffoldKey,
      drawer: NavigationDrawer(
        onDestinationSelected: _onDrawerDestinationSelected,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s24, AppSpacing.s24, AppSpacing.s16, AppSpacing.s16),
            child: Text(
              l10n.appTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.assignment_outlined),
            label: Flexible(
              child: Text(
                l10n.homeDrawerTemplates,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.style_outlined),
            label: Flexible(
              child: Text(
                l10n.homeDrawerTimerStyles,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
      extendBody: _selectedIndex != 0,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        top: false,
        child: Center(
          child: _selectedIndex == 0
              ? TimerSetupPage(
                  viewModel: _viewModel,
                  accountViewModel: _accountViewModel,
                  onMenuPressed: _openDrawer,
                  onTemplatesPressed: _openTemplates,
                  onStartPressed: _startTimer,
                )
              : StatisticPage(
                  viewModel: _statisticsViewModel,
                  accountViewModel: _accountViewModel,
                  onMenuPressed: _openDrawer,
                ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        bottom: false,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.timer_outlined),
              label: l10n.homeTabTimer,
              activeIcon: const Icon(Icons.timer),
              tooltip: l10n.homeTabTimerTooltip,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.show_chart_outlined),
              label: l10n.homeTabStatistics,
              activeIcon: const Icon(Icons.show_chart),
              tooltip: l10n.homeTabStatisticsTooltip,
            ),
          ],
        ),
      ),
    );
  }
}
