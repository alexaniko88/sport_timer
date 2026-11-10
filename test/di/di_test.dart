import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sport_timer/di/di.dart';
import 'package:sport_timer/features/statistics/data/activity_access.dart';
import 'package:sport_timer/features/statistics/domain/activity_account_source.dart';
import 'package:sport_timer/features/statistics/data/activity_database.dart';
import 'package:sport_timer/features/timer/domain/timer_activity_recorder.dart';

class FakeActivityAccountSource implements ActivityAccountSource {
  bool cancelled = false;
  late final StreamController<void> controller = StreamController<void>(
    onCancel: () => cancelled = true,
  );

  @override
  String? get currentAccountId => 'account';

  @override
  Stream<void> get changes => controller.stream;

  Future<void> closeChanges() => controller.close();
}

void main() {
  tearDown(() async => getIt.reset());

  test('registers lazy shared activity services and disposes them', () async {
    configureDependencies();
    final accounts = FakeActivityAccountSource();
    await getIt.unregister<ActivityAccountSource>();
    getIt.registerSingleton<ActivityAccountSource>(accounts);

    final database = getIt<ActivityDatabase>();
    final access = getIt<ActivityAccess>();
    final recorder = getIt<TimerActivityRecorder>();
    expect(getIt<ActivityDatabase>(), same(database));
    expect(getIt<ActivityAccess>(), same(access));
    expect(getIt<TimerActivityRecorder>(), same(recorder));

    await getIt.reset();
    expect(accounts.cancelled, isTrue);
    expect(() => database.connection, throwsStateError);
    await expectLater(access.readSessions(), throwsStateError);
    await accounts.closeChanges();
  });

  test('configuration and database lookup do not initialize Firebase or SQLite', () async {
    configureDependencies();
    expect(getIt<ActivityDatabase>(), isA<ActivityDatabase>());
  });
}
