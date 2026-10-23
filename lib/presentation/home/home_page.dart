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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
              activeIcon: Icon(Icons.home),
              tooltip: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              label: 'Templates',
              activeIcon: Icon(Icons.assignment),
              tooltip: 'Workout Templates',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_outlined),
              label: 'Statistics',
              activeIcon: Icon(Icons.show_chart),
              tooltip: 'Statistics',
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
