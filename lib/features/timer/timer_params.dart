class TimerParams {
  final Duration preparationTime;
  final Duration roundTime;
  final Duration restTime;
  final int rounds;

  const TimerParams({
    required this.preparationTime,
    required this.roundTime,
    required this.restTime,
    required this.rounds,
  });
}
