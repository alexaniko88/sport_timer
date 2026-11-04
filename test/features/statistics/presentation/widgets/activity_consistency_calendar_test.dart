import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/features/statistics/domain/activity_chart_data.dart';
import 'package:sport_timer/features/statistics/domain/activity_period.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/domain/extensions/daily_activity_list_extension.dart';
import 'package:sport_timer/features/statistics/presentation/widgets/activity_consistency_calendar.dart';
import 'package:sport_timer/l10n/app_localizations.dart';
import 'package:sport_timer/shared/presentation/theme/sport_theme.dart';

void main() {
  const records = [
    DailyActivity(localDate: '2024-02-28', roundCount: 2, workDurationMs: 60000, restDurationMs: 0),
    DailyActivity(localDate: '2024-02-29', roundCount: 0, workDurationMs: 0, restDurationMs: 30000),
  ];

  ActivityChartData data(ActivityPeriodUnit unit, int firstWeekday) => records.chartData(
        period: ActivityPeriod(unit: unit, date: DateTime(2024, 2, 29), firstWeekday: firstWeekday),
        today: DateTime(2024, 2, 29),
      );

  testWidgets('shows active, rest-only and future dates with usable semantics and keyboard selection', (tester) async {
    final semantics = tester.ensureSemantics();
    ActivityChartDay? selected;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ActivityConsistencyCalendar(
            data: data(ActivityPeriodUnit.week, DateTime.sunday),
            selected: null,
            onSelected: (day) => selected = day,
            onMonthSelected: (_) {},
          ),
        ),
      ),
    );
    final active = find.bySemanticsLabel('Wednesday, February 28, 2024: Active day. Work: 1 minute · 2 rounds');
    final restOnly = find.bySemanticsLabel('Thursday, February 29, 2024: No activity recorded. ');
    final future = find.bySemanticsLabel('Friday, March 1, 2024: Future day. ');
    expect(active, findsOneWidget);
    expect(restOnly, findsOneWidget);
    expect(future, findsOneWidget);
    await tester.tap(restOnly);
    expect(selected?.date, DateTime.utc(2024, 2, 29));
    await tester.tap(future, warnIfMissed: false);
    expect(selected?.date, DateTime.utc(2024, 2, 29));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selected?.date, DateTime.utc(2024, 2, 25));
    semantics.dispose();
  });

  testWidgets('uses locale weekday order and fits small screens with large text in both themes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          theme: brightness == Brightness.light ? SportTheme.light : SportTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(320, 800), textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: ActivityConsistencyCalendar(
                  data: data(ActivityPeriodUnit.month, DateTime.monday),
                  selected: null,
                  onSelected: (_) {},
                  onMonthSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      final weekdays = tester.widgetList<Text>(find.byType(Text)).take(7).map((text) => text.data).toList();
      expect(weekdays, ['L', 'M', 'X', 'J', 'V', 'S', 'D']);
      expect(find.text('29'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
