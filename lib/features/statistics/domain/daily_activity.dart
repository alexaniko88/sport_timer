class DailyActivity {
  final String localDate;
  final int roundCount;
  final int workDurationMs;
  final int restDurationMs;

  const DailyActivity({
    required this.localDate,
    required this.roundCount,
    required this.workDurationMs,
    required this.restDurationMs,
  });

  int get totalDurationMs => workDurationMs + restDurationMs;
}
