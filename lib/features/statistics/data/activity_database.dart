import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class ActivityDatabase {
  static const int schemaVersion = 2;
  static const String _databaseName = 'activity.db';

  final String? databasePath;
  Future<Database>? _opening;
  Future<void>? _closing;

  ActivityDatabase({this.databasePath});

  Future<Database> get connection {
    if (_closing != null) {
      throw StateError('Activity database is closed');
    }
    return _opening ??= _open();
  }

  Future<void> open() async {
    await connection;
  }

  Future<Database> _open() async {
    try {
      final resolvedPath = databasePath ?? path.join(await getDatabasesPath(), _databaseName);
      return await openDatabase(
        resolvedPath,
        version: schemaVersion,
        onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
        onCreate: (database, version) => _migrate(database, 0, version),
        onUpgrade: _migrate,
      );
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  static Future<void> _migrate(Database database, int oldVersion, int newVersion) async {
    if (oldVersion < 1 && newVersion >= 1) {
      await database.execute('''
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
      await database.execute(
        'CREATE INDEX timer_sessions_account_id ON timer_sessions(account_id)',
      );
    }
    if (oldVersion < 2 && newVersion >= 2) {
      await database.execute('''
        CREATE TABLE completed_phases (
          id TEXT PRIMARY KEY NOT NULL,
          session_id TEXT NOT NULL REFERENCES timer_sessions(id) ON DELETE RESTRICT,
          schedule_position INTEGER NOT NULL CHECK (schedule_position >= 0),
          type TEXT NOT NULL CHECK (type IN ('work', 'rest')),
          round_number INTEGER NOT NULL CHECK (round_number > 0),
          duration_ms INTEGER NOT NULL CHECK (duration_ms > 0),
          completed_at_utc_ms INTEGER NOT NULL,
          local_completion_date TEXT NOT NULL,
          utc_offset_minutes INTEGER NOT NULL,
          UNIQUE (session_id, schedule_position)
        )
      ''');
      await database.execute(
        'CREATE INDEX completed_phases_session_date ON completed_phases(session_id, local_completion_date)',
      );
    }
  }

  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    final opening = _opening;
    if (opening != null) {
      await (await opening).close();
    }
  }
}
