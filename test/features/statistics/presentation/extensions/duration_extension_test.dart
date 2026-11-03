import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/statistics/presentation/extensions/duration_extension.dart';

void main() {
  test('formats zero and singular duration units', () {
    expect(Duration.zero.formattedStatisticsDuration, '0 seconds');
    expect(const Duration(hours: 1, minutes: 1, seconds: 1).formattedStatisticsDuration, '1 hour 1 minute 1 second');
  });

  test('preserves seconds and hours beyond a day', () {
    expect(const Duration(minutes: 2, seconds: 5).formattedStatisticsDuration, '2 minutes 5 seconds');
    expect(const Duration(hours: 25, seconds: 2).formattedStatisticsDuration, '25 hours 2 seconds');
    expect(const Duration(minutes: 3).formattedStatisticsDuration, '3 minutes');
  });
}
