part of 'home.dart';

class TimerSetupPage extends StatefulWidget {
  const TimerSetupPage({super.key});

  @override
  State<TimerSetupPage> createState() => _TimerSetupPageState();
}

class _TimerSetupPageState extends State<TimerSetupPage> {
  late Duration _preparationTime, _roundTime, _restTime;
  late int _rounds;

  @override
  void initState() {
    _preparationTime = const Duration(seconds: 20);
    _roundTime = const Duration(seconds: 60);
    _restTime = const Duration(seconds: 30);
    _rounds = 5;
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
                    _buildOption(
                      context: context,
                      color: timerStyle.preparationColor,
                      timerStyle: timerStyle,
                      duration: _preparationTime,
                      label: "Preparation time",
                      maxMinutes: 5,
                      picketType: PicketType.time,
                      onDurationChanged: (duration) {
                        setState(() {
                          _preparationTime = duration;
                        });
                      },
                    ),
                    const Gap(20),
                    _buildOption(
                      context: context,
                      color: timerStyle.roundColor,
                      timerStyle: timerStyle,
                      duration: _roundTime,
                      label: "Round time",
                      maxMinutes: 60,
                      picketType: PicketType.time,
                      onDurationChanged: (duration) {
                        setState(() {
                          _roundTime = duration;
                        });
                      },
                    ),
                    const Gap(20),
                    _buildOption(
                      context: context,
                      color: timerStyle.restColor,
                      timerStyle: timerStyle,
                      duration: _restTime,
                      label: "Rest time",
                      maxMinutes: 60,
                      picketType: PicketType.time,
                      onDurationChanged: (duration) {
                        setState(() {
                          _restTime = duration;
                        });
                      },
                    ),
                    const Gap(20),
                    _buildOption(
                      context: context,
                      color: timerStyle.roundsCountColor,
                      timerStyle: timerStyle,
                      label: "Rounds",
                      maxRounds: _rounds,
                      picketType: PicketType.rounds,
                      onRoundsChanged: (rounds) {
                        setState(() {
                          _rounds = rounds;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => context.pushNamed(
          RoutePath.timer.value,
          extra: TimerParams(
            preparationTime: _preparationTime,
            roundTime: _roundTime,
            restTime: _restTime,
            rounds: _rounds,
          ),
        ),
        child: const Icon(Icons.timer),
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required TimerStyle timerStyle,
    required PicketType picketType,
    required Color color,
    required String label,
    Duration? duration,
    int? maxMinutes,
    int? maxRounds,
    Function(Duration duration)? onDurationChanged,
    Function(int rounds)? onRoundsChanged,
  }) {
    return InkWell(
      onTap: () {
        TimerSettingsPicker.show(
          context: context,
          picketType: picketType,
          initialDuration: duration,
          maxMinutes: maxMinutes ?? 60,
          maxRounds: maxRounds ?? 2,
          buttonsColor: color,
          onDurationChanged: onDurationChanged,
          onRoundsChanged: onRoundsChanged,
        );
      },
      borderRadius: BorderRadius.circular(12),
      splashColor: color.withOpacity(0.5),
      hoverColor: color.withOpacity(0.5),
      focusColor: color.withOpacity(0.5),
      highlightColor: color.withOpacity(0.5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color,
            width: 3,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 20)),
            Text(
              duration?.asMinutesAndSeconds ?? maxRounds?.toString() ?? '',
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
