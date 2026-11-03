import 'package:intl/intl.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';

extension DailyActivityExtension on DailyActivity {
  String formattedDate(String locale) => DateFormat.yMMMMd(locale).format(DateTime.parse(localDate));
}
