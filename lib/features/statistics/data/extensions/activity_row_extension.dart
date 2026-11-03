import 'package:sport_timer/features/statistics/domain/completed_phase.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/domain/run_activity_summary.dart';
import 'package:sport_timer/features/statistics/domain/timer_session.dart';

extension ActivityRowExtension on Map<String, Object?> {
  TimerSession toTimerSession() => TimerSession(
        id: this['id'] as String,
        accountId: this['account_id'] as String,
        startedAtUtcMs: this['started_at_utc_ms'] as int,
        preparationDurationMs: this['preparation_duration_ms'] as int,
        workDurationMs: this['work_duration_ms'] as int,
        restDurationMs: this['rest_duration_ms'] as int,
        roundCount: this['round_count'] as int,
        endedAtUtcMs: this['ended_at_utc_ms'] as int?,
      );

  CompletedPhase toCompletedPhase() => CompletedPhase(
        id: this['id'] as String,
        runId: this['session_id'] as String,
        schedulePosition: this['schedule_position'] as int,
        type: CompletedPhaseType.values.byName(this['type'] as String),
        roundNumber: this['round_number'] as int,
        durationMs: this['duration_ms'] as int,
        completedAtUtcMs: this['completed_at_utc_ms'] as int,
        localCompletionDate: this['local_completion_date'] as String,
        utcOffsetMinutes: this['utc_offset_minutes'] as int,
      );

  DailyActivity toDailyActivity() => DailyActivity(
        localDate: this['local_completion_date'] as String,
        roundCount: this['round_count'] as int,
        workDurationMs: this['work_duration_ms'] as int,
        restDurationMs: this['rest_duration_ms'] as int,
      );

  RunActivitySummary toRunActivitySummary() => RunActivitySummary(
        session: toTimerSession(),
        activity: DailyActivity(
          localDate: this['local_completion_date'] as String,
          roundCount: this['day_round_count'] as int,
          workDurationMs: this['day_work_duration_ms'] as int,
          restDurationMs: this['day_rest_duration_ms'] as int,
        ),
      );
}
