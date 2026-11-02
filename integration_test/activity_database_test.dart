import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:sport_timer/features/statistics/activity_database.dart';
import 'package:sqflite/sqflite.dart';

Map<String, Object?> session({String id = 'session-1'}) => {
      'id': id,
      'account_id': 'account-1',
      'started_at_utc_ms': 1000,
      'preparation_duration_ms': 3000,
      'work_duration_ms': 30000,
      'rest_duration_ms': 10000,
      'round_count': 3,
      'ended_at_utc_ms': null,
    };

Map<String, Object?> phase({
  String id = 'phase-1',
  String sessionId = 'session-1',
  int position = 1,
}) =>
    {
      'id': id,
      'session_id': sessionId,
      'schedule_position': position,
      'type': 'work',
      'round_number': 1,
      'duration_ms': 30000,
      'completed_at_utc_ms': 31000,
      'local_completion_date': '2026-11-02',
      'utc_offset_minutes': 60,
    };

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late String databasePath;
  ActivityDatabase? store;

  setUp(() async {
    databasePath = path.join(
      await getDatabasesPath(),
      'activity_test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
  });

  tearDown(() async {
    await store?.close();
    store = null;
    await deleteDatabase(databasePath);
  });

  testWidgets('creates schema and shares a single connection', (tester) async {
    store = ActivityDatabase(databasePath: databasePath);
    await Future.wait([store!.open(), store!.open()]);
    final db = await openDatabase(databasePath);
    expect(await db.getVersion(), 2);
    expect(Sqflite.firstIntValue(await db.rawQuery('PRAGMA foreign_keys')), 1);
    final indexes = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index'",
    );
    expect(
      indexes.map((index) => index['name']),
      containsAll([
        'timer_sessions_account_id',
        'completed_phases_session_date',
      ]),
    );
  });

  testWidgets('enforces foreign keys, uniqueness, and retained history', (tester) async {
    store = ActivityDatabase(databasePath: databasePath);
    await store!.open();
    final db = await openDatabase(databasePath);
    await expectLater(db.insert('completed_phases', phase()), throwsA(isA<DatabaseException>()));
    await db.insert('timer_sessions', session());
    await db.insert('completed_phases', phase());
    await expectLater(db.insert('timer_sessions', session()), throwsA(isA<DatabaseException>()));
    await expectLater(db.insert('completed_phases', phase()), throwsA(isA<DatabaseException>()));
    await expectLater(
      db.insert('completed_phases', phase(id: 'another-phase')),
      throwsA(isA<DatabaseException>()),
    );
    await expectLater(db.delete('timer_sessions'), throwsA(isA<DatabaseException>()));
    expect(await db.query('completed_phases'), hasLength(1));
  });

  testWidgets('rolls back an incomplete transaction', (tester) async {
    store = ActivityDatabase(databasePath: databasePath);
    await store!.open();
    final db = await openDatabase(databasePath);
    await expectLater(
      db.transaction((txn) async {
        await txn.insert('timer_sessions', session());
        await txn.insert('completed_phases', phase(sessionId: 'missing'));
      }),
      throwsA(isA<DatabaseException>()),
    );
    expect(await db.query('timer_sessions'), isEmpty);
    expect(await db.query('completed_phases'), isEmpty);
  });

  testWidgets('concurrent close calls wait for the same pending close', (tester) async {
    store = ActivityDatabase(databasePath: databasePath);
    final opening = store!.open();
    final firstClose = store!.close();
    final secondClose = store!.close();

    expect(identical(firstClose, secondClose), isTrue);
    await expectLater(store!.open(), throwsStateError);
    await opening;
    await Future.wait([firstClose, secondClose]);
  });

  testWidgets('reopens committed records after close', (tester) async {
    store = ActivityDatabase(databasePath: databasePath);
    await store!.open();
    final db = await openDatabase(databasePath);
    await db.insert('timer_sessions', session());
    await db.insert('completed_phases', phase());
    await store!.close();
    await expectLater(store!.open(), throwsStateError);
    store = ActivityDatabase(databasePath: databasePath);
    await store!.open();
    final reopened = await openDatabase(databasePath);
    expect(await reopened.query('timer_sessions'), [session()]);
    expect(await reopened.query('completed_phases'), [phase()]);
  });

  testWidgets('upgrades version 1 without losing records', (tester) async {
    final old = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE timer_sessions (
            id TEXT PRIMARY KEY NOT NULL,
            account_id TEXT NOT NULL CHECK (length(account_id) > 0),
            started_at_utc_ms INTEGER NOT NULL,
            preparation_duration_ms INTEGER NOT NULL CHECK (preparation_duration_ms >= 0),
            work_duration_ms INTEGER NOT NULL CHECK (work_duration_ms >= 0),
            rest_duration_ms INTEGER NOT NULL CHECK (rest_duration_ms >= 0),
            round_count INTEGER NOT NULL CHECK (round_count > 0),
            ended_at_utc_ms INTEGER
          )
        ''');
        await db.execute('CREATE INDEX timer_sessions_account_id ON timer_sessions(account_id)');
      },
    );
    await old.insert('timer_sessions', session());
    await old.close();
    store = ActivityDatabase(databasePath: databasePath);
    await store!.open();
    final upgraded = await openDatabase(databasePath);
    expect(await upgraded.getVersion(), 2);
    expect(await upgraded.query('timer_sessions'), [session()]);
    await upgraded.insert('completed_phases', phase());
    expect(await upgraded.query('completed_phases'), [phase()]);
  });
}
