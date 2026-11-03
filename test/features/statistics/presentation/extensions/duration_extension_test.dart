import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/statistics/presentation/extensions/duration_extension.dart';
import 'package:sport_timer/l10n/app_localizations_en.dart';
import 'package:sport_timer/l10n/app_localizations_es.dart';

void main() {
  final en = AppLocalizationsEn();
  final es = AppLocalizationsEs();
  test('formats zero and singular duration units', () {
    expect(Duration.zero.formattedStatisticsDuration(en), '0 seconds');
    expect(
      const Duration(hours: 1, minutes: 1, seconds: 1).formattedStatisticsDuration(en),
      '1 hour 1 minute 1 second',
    );
    expect(const Duration(minutes: 1, seconds: 2).formattedStatisticsDuration(es), '1 minuto 2 segundos');
  });
  test('preserves seconds and hours beyond a day', () {
    expect(const Duration(minutes: 2, seconds: 5).formattedStatisticsDuration(en), '2 minutes 5 seconds');
    expect(const Duration(hours: 25, seconds: 2).formattedStatisticsDuration(en), '25 hours 2 seconds');
    expect(const Duration(minutes: 3).formattedStatisticsDuration(en), '3 minutes');
  });
}
