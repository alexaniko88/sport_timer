import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/domain/timer_session.dart';

class RunActivitySummary {
  final TimerSession session;
  final DailyActivity activity;

  const RunActivitySummary({required this.session, required this.activity});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RunActivitySummary && other.session == session && other.activity == activity;

  @override
  int get hashCode => Object.hash(session, activity);
}
