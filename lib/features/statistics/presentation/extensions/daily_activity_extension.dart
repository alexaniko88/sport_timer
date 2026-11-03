import 'package:intl/intl.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';

extension DailyActivityExtension on DailyActivity {
  String get formattedDate => DateFormat('d MMMM y', 'en_US').format(DateTime.parse(localDate));
}
