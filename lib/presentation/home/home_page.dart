part of 'home.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
  }

  void _incrementCounter() {
    setState(() => _counter++);
  }

  void _goNextPage() {
    context.push(RoutePath.timerSettings.value);
  }

  void _startCounter() {
    context.read<TimeCountdownCubit>().restart();
  }

  void _pauseCounter() {
    context.read<TimeCountdownCubit>().pause();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter Demo Home Page'),
      ),
      body: ArcStopwatch(duration: Duration(seconds: 5)),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'Start',
            onPressed: _startCounter,
            tooltip: 'Start/Restart',
            child: const Icon(Icons.play_circle),
          ),
          const Gap(20),
          FloatingActionButton(
            heroTag: 'Pause',
            onPressed: _pauseCounter,
            tooltip: 'Pause',
            child: const Icon(Icons.pause_circle),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
