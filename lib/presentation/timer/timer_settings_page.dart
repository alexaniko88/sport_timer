part of 'timer.dart';

class TimerSettingsPage extends StatelessWidget {
  const TimerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer settings page'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Hero(
                  tag: 'timer',
                  child: CircleAvatar(
                    radius: 150,
                    child: Text(
                      '22:00',
                      style: TextStyle(fontSize: 30),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Configuration 1'),
                    Text('Configuration 2'),
                    Text('Configuration 3'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
