part of 'home.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if(index == 0) {
        context.read<SettingsCubit>().loadSettings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final settings = state.timerSettings!;
        return Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          body: SafeArea(
            top: false,
            child: Center(
              child: switch (_selectedIndex) {
                1 => const TemplatesPage(),
                2 => const StatisticPage(),
                _ => const TimerSetupPage(),
              },
            ),
          ),
          bottomNavigationBar: SafeArea(
            bottom: false,
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              onTap: _onItemTapped,
              unselectedItemColor: Colors.black,
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
          floatingActionButton: _selectedIndex != 2 ? FloatingActionButton.large(

            onPressed: state.status == SettingsStatus.saving
                ? null
                : () {
              context.read<SettingsCubit>().saveSettings(settings);
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
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.timer),
          ) : null,
        );
      }
    );
  }
}
