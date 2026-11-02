class TimerSession {
  final String id;
  final String accountId;
  final int startedAtUtcMs;
  final int preparationDurationMs;
  final int workDurationMs;
  final int restDurationMs;
  final int roundCount;
  final int? endedAtUtcMs;

  const TimerSession({
    required this.id,
    required this.accountId,
    required this.startedAtUtcMs,
    required this.preparationDurationMs,
    required this.workDurationMs,
    required this.restDurationMs,
    required this.roundCount,
    this.endedAtUtcMs,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerSession &&
          other.id == id &&
          other.accountId == accountId &&
          other.startedAtUtcMs == startedAtUtcMs &&
          other.preparationDurationMs == preparationDurationMs &&
          other.workDurationMs == workDurationMs &&
          other.restDurationMs == restDurationMs &&
          other.roundCount == roundCount &&
          other.endedAtUtcMs == endedAtUtcMs;

  @override
  int get hashCode => Object.hash(
        id,
        accountId,
        startedAtUtcMs,
        preparationDurationMs,
        workDurationMs,
        restDurationMs,
        roundCount,
        endedAtUtcMs,
      );
}
