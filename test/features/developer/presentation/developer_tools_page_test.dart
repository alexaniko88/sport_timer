import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/developer/presentation/developer_tools_page.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';
import 'package:sport_timer/shared/presentation/theme/sport_theme.dart';
import 'package:sport_timer/shared/presentation/widgets/app_surface.dart';

class _FakeActivityRepository implements ActivityRepository {
  Completer<Result<void>> completer = Completer<Result<void>>();
  int deleteCalls = 0;

  @override
  Future<Result<void>> deleteAllActivity() {
    deleteCalls++;
    return completer.future;
  }

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeActivityRepository repository;

  setUp(() async {
    await getIt.reset();
    repository = _FakeActivityRepository();
    getIt.registerSingleton<ActivityRepository>(repository);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    ThemeData? theme,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? SportTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        ),
        home: const DeveloperToolsPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.text('Delete all activity'));
    await tester.pumpAndSettle();
  }

  // The spinner animates forever while purging, so settle is not possible then.
  Future<void> tapDelete(WidgetTester tester) async {
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  // The completer is created outside the test's fake clock, so its callbacks need a real async turn.
  Future<void> finishPurge(WidgetTester tester, Result<void> result) async {
    repository.completer.complete(result);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  const successText = 'All local activity deleted.';

  testWidgets('Cancel does not delete', (tester) async {
    await pumpPage(tester);
    await openDialog(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, 0);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('tapping outside the dialog does not delete', (tester) async {
    await pumpPage(tester);
    await openDialog(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, 0);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Delete purges and shows the success snackbar', (tester) async {
    await pumpPage(tester);
    await openDialog(tester);
    await tapDelete(tester);
    await finishPurge(tester, const Success(null));

    expect(repository.deleteCalls, 1);
    expect(find.text(successText), findsOneWidget);
  });

  testWidgets('tile is blocked while purging', (tester) async {
    await pumpPage(tester);
    await openDialog(tester);
    await tapDelete(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Delete all activity'));
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
    expect(repository.deleteCalls, 1);

    await finishPurge(tester, const Success(null));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('failure shows the error snackbar', (tester) async {
    await pumpPage(tester);
    await openDialog(tester);
    await tapDelete(tester);
    await finishPurge(tester, Failure(Exception('boom')));

    expect(find.text('Could not delete activity: ${Exception('boom')}'), findsOneWidget);
    expect(find.text(successText), findsNothing);
  });

  testWidgets('page meets accessibility guidelines', (tester) async {
    for (final theme in [SportTheme.light, SportTheme.dark]) {
      await pumpPage(tester, theme: theme);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    }
  });

  testWidgets('page renders at 2x text scale', (tester) async {
    await pumpPage(tester, textScale: 2);

    expect(find.byType(AppSurface), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmation dialog meets accessibility guidelines', (tester) async {
    for (final theme in [SportTheme.light, SportTheme.dark]) {
      await pumpPage(tester, theme: theme);
      await openDialog(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('confirmation dialog renders at 2x text scale', (tester) async {
    await pumpPage(tester, textScale: 2);
    await openDialog(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
