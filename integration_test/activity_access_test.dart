import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:sport_timer/features/statistics/activity_access.dart';
import 'package:sport_timer/features/statistics/activity_account_source.dart';
import 'package:sport_timer/features/statistics/activity_database.dart';
import 'package:sport_timer/features/statistics/completed_phase.dart';
import 'package:sport_timer/features/statistics/firebase_activity_account_source.dart';
import 'package:sport_timer/features/statistics/timer_session.dart';
import 'package:sqflite/sqflite.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class FakeAccounts implements ActivityAccountSource {
  final controller = StreamController<void>.broadcast(sync: true);
  String? account;

  @override
  String? get currentAccountId => account;
  @override
  Stream<void> get changes => controller.stream;

  void change(String? value) {
    account = value;
    controller.add(null);
  }
}

TimerSession session(String id, String account) => TimerSession(
      id: id,
      accountId: account,
      startedAtUtcMs: 1000,
      preparationDurationMs: 0,
      workDurationMs: 30000,
      restDurationMs: 10000,
      roundCount: 2,
    );

CompletedPhase phase(String id, String sessionId) => CompletedPhase(
      id: id,
      runId: sessionId,
      schedulePosition: 0,
      type: CompletedPhaseType.work,
      roundNumber: 1,
      durationMs: 30000,
      completedAtUtcMs: 31000,
      localCompletionDate: '2026-11-02',
      utcOffsetMinutes: 60,
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late String dbPath;
  late ActivityDatabase db;
  late ActivityAccess access;
  late FakeAccounts accounts;

  setUp(() async {
    dbPath = path.join(await getDatabasesPath(), 'access_${DateTime.now().microsecondsSinceEpoch}.db');
    accounts = FakeAccounts();
    db = ActivityDatabase(databasePath: dbPath);
    access = ActivityAccess(db, accounts);
  });
  tearDown(() async {
    await access.close();
    await accounts.controller.close();
    await db.close();
    await deleteDatabase(dbPath);
  });

  testWidgets('isolates accounts and retains pending writes for original owner', (tester) async {
    await expectLater(access.readSessions(), throwsStateError);
    accounts.change('a');
    final a = await access.createSession(session('a-session', 'a'));
    accounts.change('b');
    await expectLater(access.createSession(session('bad', 'a')), throwsStateError);
    await access.createSession(session('b-session', 'b'));
    await access.addPhase(a, phase('a-phase', 'a-session'));
    expect((await access.readSessions()).map((s) => s.id), ['b-session']);
    expect(await access.readPhases('a-session'), isEmpty);
    await expectLater(access.openSession('a-session'), throwsStateError);
    accounts.change(null);
    await expectLater(access.readSessions(), throwsStateError);
    accounts.change('a');
    expect((await access.readSessions()).map((s) => s.id), ['a-session']);
    expect((await access.readPhases('a-session')).map((p) => p.id), ['a-phase']);
  });

  testWidgets('discards a read when account signs out and back in', (tester) async {
    accounts.change('a');
    final pending = access.readSessions();
    accounts.change(null);
    accounts.change('a');
    await expectLater(pending, throwsStateError);
  });

  testWidgets('ignores the initial Firebase snapshot but detects subsequent changes', (tester) async {
    final auth = MockFirebaseAuth();
    final user = MockUser();
    final events = StreamController<User?>.broadcast(sync: true);
    User? currentUser = user;
    when(() => user.uid).thenReturn('a');
    when(() => auth.currentUser).thenAnswer((_) => currentUser);
    when(() => auth.authStateChanges()).thenAnswer((_) => events.stream);
    final firebaseAccess = ActivityAccess(db, FirebaseActivityAccountSource(auth));
    try {
      final initialRead = firebaseAccess.readSessions();
      events.add(user);
      expect(await initialRead, isEmpty);

      final pending = firebaseAccess.readSessions();
      currentUser = null;
      events.add(null);
      currentUser = user;
      events.add(user);
      await expectLater(pending, throwsStateError);
    } finally {
      await firebaseAccess.close();
      await events.close();
    }
  });
}
