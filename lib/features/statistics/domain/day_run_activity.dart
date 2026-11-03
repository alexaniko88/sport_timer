import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/domain/timer_session.dart';

class DayRunActivity {
  final TimerSession session;
  final DailyActivity activity;

  const DayRunActivity({required this.session, required this.activity});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DayRunActivity && other.session == session && other.activity == activity;

  @override
  int get hashCode => Object.hash(session, activity);
}
