import 'dart:async';

import 'package:sport_timer/features/statistics/domain/activity_account_source.dart';
import 'package:sport_timer/features/statistics/data/activity_database.dart';
import 'package:sport_timer/features/statistics/domain/completed_phase.dart';
import 'package:sport_timer/features/statistics/domain/timer_session.dart';

class ActivitySessionHandle {
  final Object _issuer;
  final String _accountId;
  final String sessionId;

  ActivitySessionHandle._(this._issuer, this._accountId, this.sessionId);
}

class ActivityAccess {
  final ActivityDatabase _database;
  final ActivityAccountSource _accounts;
  late final StreamSubscription<void> _subscription;
  int _generation = 0;
  bool _closed = false;

  ActivityAccess(this._database, this._accounts) {
    _subscription = _accounts.changes.listen((_) => _generation++);
  }

  String _requireAccount() {
    if (_closed) throw StateError('Activity access is closed');
    final account = _accounts.currentAccountId;
    if (account == null || account.isEmpty) throw StateError('No signed-in account');
    return account;
  }

  void _verifyRead(String account, int generation) {
    if (_closed || _generation != generation || _accounts.currentAccountId != account) {
      throw StateError('Account changed during activity read');
    }
  }

  Future<ActivitySessionHandle> createSession(TimerSession session) async {
    final account = _requireAccount();
    if (session.accountId != account) throw StateError('Session belongs to another account');
    final db = await _database.connection;
    await db.insert('timer_sessions', {
      'id': session.id,
      'account_id': account,
      'started_at_utc_ms': session.startedAtUtcMs,
      'preparation_duration_ms': session.preparationDurationMs,
      'work_duration_ms': session.workDurationMs,
      'rest_duration_ms': session.restDurationMs,
      'round_count': session.roundCount,
      'ended_at_utc_ms': session.endedAtUtcMs,
    });
    return ActivitySessionHandle._(this, account, session.id);
  }

  Future<ActivitySessionHandle> openSession(String sessionId) async {
    final account = _requireAccount();
    final generation = _generation;
    final db = await _database.connection;
    final rows = await db.query(
      'timer_sessions',
      columns: ['id'],
      where: 'id = ? AND account_id = ?',
      whereArgs: [sessionId, account],
    );
    _verifyRead(account, generation);
    if (rows.isEmpty) throw StateError('Session not found');
    return ActivitySessionHandle._(this, account, sessionId);
  }

  Future<List<TimerSession>> readSessions() async {
    final account = _requireAccount();
    final generation = _generation;
    final db = await _database.connection;
    final rows = await db.query('timer_sessions', where: 'account_id = ?', whereArgs: [account]);
    _verifyRead(account, generation);
    return rows
        .map(
          (row) => TimerSession(
            id: row['id']! as String,
            accountId: row['account_id']! as String,
            startedAtUtcMs: row['started_at_utc_ms']! as int,
            preparationDurationMs: row['preparation_duration_ms']! as int,
            workDurationMs: row['work_duration_ms']! as int,
            restDurationMs: row['rest_duration_ms']! as int,
            roundCount: row['round_count']! as int,
            endedAtUtcMs: row['ended_at_utc_ms'] as int?,
          ),
        )
        .toList();
  }

  Future<void> addPhase(ActivitySessionHandle handle, CompletedPhase phase) async {
    if (_closed || !identical(handle._issuer, this) || phase.runId != handle.sessionId) {
      throw StateError('Invalid activity session');
    }
    final db = await _database.connection;
    await db.transaction((txn) async {
      final sessions = await txn.query(
        'timer_sessions',
        columns: ['id'],
        where: 'id = ? AND account_id = ?',
        whereArgs: [handle.sessionId, handle._accountId],
      );
      if (sessions.isEmpty) throw StateError('Session not found');
      await txn.insert('completed_phases', {
        'id': phase.id,
        'session_id': phase.runId,
        'schedule_position': phase.schedulePosition,
        'type': phase.type.name,
        'round_number': phase.roundNumber,
        'duration_ms': phase.durationMs,
        'completed_at_utc_ms': phase.completedAtUtcMs,
        'local_completion_date': phase.localCompletionDate,
        'utc_offset_minutes': phase.utcOffsetMinutes,
      });
    });
  }

  Future<List<CompletedPhase>> readPhases(String sessionId) async {
    final account = _requireAccount();
    final generation = _generation;
    final db = await _database.connection;
    final rows = await db.rawQuery(
      'SELECT p.* FROM completed_phases p JOIN timer_sessions s ON s.id = p.session_id '
      'WHERE s.id = ? AND s.account_id = ?',
      [sessionId, account],
    );
    _verifyRead(account, generation);
    return rows
        .map(
          (row) => CompletedPhase(
            id: row['id']! as String,
            runId: row['session_id']! as String,
            schedulePosition: row['schedule_position']! as int,
            type: CompletedPhaseType.values.byName(row['type']! as String),
            roundNumber: row['round_number']! as int,
            durationMs: row['duration_ms']! as int,
            completedAtUtcMs: row['completed_at_utc_ms']! as int,
            localCompletionDate: row['local_completion_date']! as String,
            utcOffsetMinutes: row['utc_offset_minutes']! as int,
          ),
        )
        .toList();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription.cancel();
  }
}
