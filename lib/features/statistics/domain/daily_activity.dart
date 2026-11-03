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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyActivity &&
          other.localDate == localDate &&
          other.roundCount == roundCount &&
          other.workDurationMs == workDurationMs &&
          other.restDurationMs == restDurationMs;

  @override
  int get hashCode => Object.hash(
        localDate,
        roundCount,
        workDurationMs,
        restDurationMs,
      );
}
