import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/account/presentation/account_view_model.dart';
import 'package:sport_timer/features/settings/presentation/extensions/timer_style_names_extension.dart';
import 'package:sport_timer/features/settings/presentation/settings_state.dart';
import 'package:sport_timer/features/settings/presentation/settings_view_model.dart';
import 'package:sport_timer/features/settings/presentation/timer_setup_page.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_page.dart';
import 'package:sport_timer/features/statistics/presentation/statistics_view_model.dart';
import 'package:sport_timer/features/templates/presentation/extensions/template_names_extension.dart';
import 'package:sport_timer/features/timer/domain/timer_params.dart';
import 'package:sport_timer/navigation.dart';
import 'package:sport_timer/shared/presentation/extensions/l10n_context.dart';
import 'package:sport_timer/shared/presentation/extensions/text_theme_extension.dart';
import 'package:sport_timer/shared/presentation/theme/app_spacing.dart';
import 'package:sport_timer/shared/presentation/widgets/app_surface.dart';

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

  void _onDrawerTileTapped(RoutePath route) {
    _scaffoldKey.currentState?.closeDrawer();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s20,
                  AppSpacing.s16,
                  AppSpacing.s16,
                ),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: SizedBox(
                        width: AppSpacing.s40,
                        height: AppSpacing.s40,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.r12),
                          ),
                          child: Icon(Icons.timer_outlined, color: colorScheme.onPrimaryContainer),
                        ),
                      ),
                    ),
                    const Gap(AppSpacing.s12),
                    Expanded(
                      child: Text(
                        l10n.appTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: AppSpacing.s16, endIndent: AppSpacing.s16),
              Expanded(
                child: ValueListenableBuilder<SettingsState>(
                  valueListenable: _viewModel.state,
                  builder: (context, state, _) {
                    return ListView(
                      padding: const EdgeInsets.all(AppSpacing.s16),
                      children: [
                        _DrawerTile(
                          icon: Icons.assignment_outlined,
                          title: l10n.homeDrawerTemplates,
                          subtitle: switch (state.selectedTemplateId) {
                            final id? => l10n.templateName(id),
                            null => l10n.templateCustomName,
                          },
                          onTap: () => _onDrawerTileTapped(RoutePath.templates),
                        ),
                        const Gap(AppSpacing.s12),
                        _DrawerTile(
                          icon: Icons.style_outlined,
                          title: l10n.homeDrawerTimerStyles,
                          subtitle: l10n.timerStyleName(state.timerStyle),
                          onTap: () => _onDrawerTileTapped(RoutePath.timerStyles),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Semantics(
      button: true,
      child: AppSurface(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const Gap(AppSpacing.s12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.tileTitle,
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.tileSecondary.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.s12),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
