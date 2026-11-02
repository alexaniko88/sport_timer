enum CompletedPhaseType { work, rest }

class CompletedPhase {
  final String id;
  final String runId;
  final int schedulePosition;
  final CompletedPhaseType type;
  final int roundNumber;
  final int durationMs;
  final int completedAtUtcMs;
  final String localCompletionDate;
  final int utcOffsetMinutes;

  const CompletedPhase({
    required this.id,
    required this.runId,
    required this.schedulePosition,
    required this.type,
    required this.roundNumber,
    required this.durationMs,
    required this.completedAtUtcMs,
    required this.localCompletionDate,
    required this.utcOffsetMinutes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletedPhase &&
          other.id == id &&
          other.runId == runId &&
          other.schedulePosition == schedulePosition &&
          other.type == type &&
          other.roundNumber == roundNumber &&
          other.durationMs == durationMs &&
          other.completedAtUtcMs == completedAtUtcMs &&
          other.localCompletionDate == localCompletionDate &&
          other.utcOffsetMinutes == utcOffsetMinutes;

  @override
  int get hashCode => Object.hash(
        id,
        runId,
        schedulePosition,
        type,
        roundNumber,
        durationMs,
        completedAtUtcMs,
        localCompletionDate,
        utcOffsetMinutes,
      );
}
