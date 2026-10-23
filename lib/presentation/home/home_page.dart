part of 'home.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _loaderSize = 24;
  static const double _loaderStroke = 2;

  final SettingsViewModel _viewModel = SettingsViewModel(getIt());
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _viewModel.loadSettings();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
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
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        top: false,
        child: Center(
          child: switch (_selectedIndex) {
            1 => TemplatesPage(viewModel: _viewModel),
            2 => const StatisticPage(),
            _ => TimerSetupPage(viewModel: _viewModel),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedIndex != 2
          ? ValueListenableBuilder<SettingsState>(
              valueListenable: _viewModel.state,
              builder: (context, state, _) {
                final settings = state.timerSettings;
                return FloatingActionButton.large(
                  onPressed: state.status == SettingsStatus.saving
                      ? null
                      : () {
                          _viewModel.saveSettings(settings);
                          context.pushNamed(
                            RoutePath.timer.value,
                            extra: TimerParams(
                              preparationTime: settings.preparationTime,
                              roundTime: settings.roundTime,
                              restTime: settings.restTime,
                              rounds: settings.rounds,
                            ),
                          );
                        },
                  child: state.status == SettingsStatus.saving
                      ? const SizedBox.square(
                          dimension: _loaderSize,
                          child: CircularProgressIndicator(strokeWidth: _loaderStroke),
                        )
                      : const Icon(Icons.timer),
                );
              },
            )
          : null,
    );
  }
}
