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
  test('preserves fractional seconds in both languages', () {
    expect(const Duration(milliseconds: 1251).formattedStatisticsDuration(en), '1 second 251 milliseconds');
    expect(const Duration(milliseconds: 1).formattedStatisticsDuration(es), '1 milisegundo');
  });
  test('preserves seconds and hours beyond a day', () {
    expect(const Duration(minutes: 2, seconds: 5).formattedStatisticsDuration(en), '2 minutes 5 seconds');
    expect(const Duration(hours: 25, seconds: 2).formattedStatisticsDuration(en), '25 hours 2 seconds');
    expect(const Duration(minutes: 3).formattedStatisticsDuration(en), '3 minutes');
  });
  test('compact duration joins the non-zero hours, minutes and seconds', () {
    expect(const Duration(minutes: 26).compactStatisticsDuration, '26m');
    expect(const Duration(minutes: 3, seconds: 35).compactStatisticsDuration, '3m 35s');
    expect(const Duration(hours: 1, minutes: 2, seconds: 5).compactStatisticsDuration, '1h 2m 5s');
    expect(const Duration(seconds: 30).compactStatisticsDuration, '30s');
    expect(const Duration(hours: 37, minutes: 2, seconds: 12).compactStatisticsDuration, '37h 2m 12s');
    expect(const Duration(minutes: 1, seconds: 2, milliseconds: 999).compactStatisticsDuration, '1m 2s');
  });
  test('compact duration of zero or under a second is 0s', () {
    expect(Duration.zero.compactStatisticsDuration, '0s');
    expect(const Duration(milliseconds: 999).compactStatisticsDuration, '0s');
  });
}
