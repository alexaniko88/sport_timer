part of 'home.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SettingsViewModel _viewModel = SettingsViewModel(getIt());
  final AccountViewModel _accountViewModel = AccountViewModel(getIt());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _viewModel.loadSettings();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _accountViewModel.dispose();
    super.dispose();
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _onDrawerDestinationSelected(int _) {
    _scaffoldKey.currentState?.closeDrawer();
    context.pushNamed(RoutePath.timerStyles.value, extra: _viewModel);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
            icon: const Icon(Icons.style_outlined),
            label: Text(l10n.homeDrawerTimerStyles),
          ),
        ],
      ),
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        top: false,
        child: Center(
          child: switch (_selectedIndex) {
            1 => TemplatesPage(
                viewModel: _viewModel,
                accountViewModel: _accountViewModel,
                onMenuPressed: _openDrawer,
              ),
            2 => StatisticPage(
                accountViewModel: _accountViewModel,
                onMenuPressed: _openDrawer,
              ),
            _ => TimerSetupPage(
                viewModel: _viewModel,
                accountViewModel: _accountViewModel,
                onMenuPressed: _openDrawer,
              ),
          },
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
              icon: const Icon(Icons.home_outlined),
              label: l10n.homeTabHome,
              activeIcon: const Icon(Icons.home),
              tooltip: l10n.homeTabHomeTooltip,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.assignment_outlined),
              label: l10n.homeTabTemplates,
              activeIcon: const Icon(Icons.assignment),
              tooltip: l10n.homeTabTemplatesTooltip,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _selectedIndex != 2
          ? ValueListenableBuilder<SettingsState>(
              valueListenable: _viewModel.state,
              builder: (context, state, _) {
                final settings = state.timerSettings;
                return AppButton.fab(
                  icon: const Icon(Icons.timer),
                  label: l10n.homeStartButton,
                  isLoading: state.status == SettingsStatus.saving,
                  onPressed: () {
                    _viewModel.saveSettings(settings);
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
                  },
                );
              },
            )
          : null,
    );
  }
}
