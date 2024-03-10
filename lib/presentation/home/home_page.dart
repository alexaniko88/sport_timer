part of 'home.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Duration _preparationTime, _roundTime, _restTime;
  late int _rounds;

  @override
  void initState() {
    _preparationTime = const Duration(seconds: 5);
    _roundTime = const Duration(seconds: 5);
    _restTime = const Duration(seconds: 5);
    _rounds = 2;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final timerStyle = Theme.of(context).extension<TimerStyle>()!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Prepared for the new challenge?'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        TimerSettingsPicker.show(
                          context: context,
                          picketType: PicketType.time,
                          initialDuration: _preparationTime,
                          maxMinutes: 5,
                          buttonsColor: timerStyle.preparationColor,
                          onDurationChanged: (duration) {
                            setState(() {
                              _preparationTime = duration;
                            });
                          },
                        );
                      },
                      child: Card(
                        color: timerStyle.preparationColor,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Preparation time', style: TextStyle(fontSize: 20)),
                              Text(
                                _preparationTime.asMinutesAndSeconds,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Gap(20),
                    GestureDetector(
                      onTap: () {
                        TimerSettingsPicker.show(
                          context: context,
                          picketType: PicketType.time,
                          initialDuration: _roundTime,
                          buttonsColor: timerStyle.roundColor,
                          onDurationChanged: (duration) {
                            setState(() {
                              _roundTime = duration;
                            });
                          },
                        );
                      },
                      child: Card(
                        color: timerStyle.roundColor,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Round time', style: TextStyle(fontSize: 20)),
                              Text(
                                _roundTime.asMinutesAndSeconds,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Gap(20),
                    GestureDetector(
                      onTap: () {
                        TimerSettingsPicker.show(
                          context: context,
                          picketType: PicketType.time,
                          initialDuration: _restTime,
                          buttonsColor: timerStyle.restColor,
                          onDurationChanged: (duration) {
                            setState(() {
                              _restTime = duration;
                            });
                          },
                        );
                      },
                      child: Card(
                        color: timerStyle.restColor,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Rest time', style: TextStyle(fontSize: 20)),
                              Text(
                                _restTime.asMinutesAndSeconds,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Gap(20),
                    GestureDetector(
                      onTap: () {
                        TimerSettingsPicker.show(
                          context: context,
                          picketType: PicketType.rounds,
                          maxRounds: _rounds,
                          buttonsColor: timerStyle.roundsCountColor,
                          onRoundsChanged: (rounds) {
                            setState(() {
                              _rounds = rounds;
                            });
                          },
                        );
                      },
                      child: Card(
                        color: timerStyle.roundsCountColor,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Rounds', style: TextStyle(fontSize: 20)),
                              Text(
                                _rounds.toString(),
                                style: const TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              MaterialButton(
                onPressed: () => context.pushNamed(
                  RoutePath.timer.value,
                  extra: TimerParams(
                    preparationTime: _preparationTime,
                    roundTime: _roundTime,
                    restTime: _restTime,
                    rounds: _rounds,
                  ),
                ),
                color: Theme.of(context).colorScheme.primary,
                minWidth: MediaQuery.of(context).size.width / 2,
                height: MediaQuery.of(context).size.width / 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.timer,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
