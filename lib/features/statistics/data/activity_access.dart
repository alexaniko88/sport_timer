import 'dart:async';

import 'package:sport_timer/features/statistics/data/activity_database.dart';
import 'package:sport_timer/features/statistics/data/extensions/activity_row_extension.dart';
import 'package:sport_timer/features/statistics/domain/activity_account_source.dart';
import 'package:sport_timer/features/statistics/domain/activity_session_handle.dart';
import 'package:sport_timer/features/statistics/domain/completed_phase.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/domain/timer_session.dart';

class _ActivitySessionHandle implements ActivitySessionHandle {
  final Object issuer;
  final String accountId;
  @override
  final String sessionId;

  _ActivitySessionHandle(this.issuer, this.accountId, this.sessionId);
}

class ActivityAccess {
  final ActivityDatabase _database;
  final ActivityAccountSource _accounts;
  final StreamController<void> _changes = StreamController<void>.broadcast(sync: true);
  late final StreamSubscription<void> _subscription;
  int _generation = 0;
  bool _closed = false;

  ActivityAccess(this._database, this._accounts) {
    _subscription = _accounts.changes.listen((_) {
      _generation++;
      _changes.add(null);
    });
  }

  Stream<void> get changes => _changes.stream;

  ({String? accountId, int generation, bool closed}) get readToken => (
        accountId: _accounts.currentAccountId,
        generation: _generation,
        closed: _closed,
      );

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

  _ActivitySessionHandle _verifyHandle(ActivitySessionHandle handle) {
    if (_closed || handle is! _ActivitySessionHandle || !identical(handle.issuer, this)) {
      throw StateError('Invalid activity session');
    }
    return handle;
  }

  void _notifyChange() {
    if (!_closed) _changes.add(null);
  }

  Future<ActivitySessionHandle> createSession(TimerSession session) async {
    final account = _requireAccount();
    if (session.accountId != account) throw StateError('Session belongs to another account');
    final db = await _database.connection;
    await db.transaction((txn) async {
      final existing = await txn.query('timer_sessions', where: 'id = ?', whereArgs: [session.id]);
      if (existing.isNotEmpty) {
        if (existing.single.toTimerSession() != session) throw StateError('Conflicting activity session');
        return;
      }
      await txn.insert('timer_sessions', {
        'id': session.id,
        'account_id': account,
        'started_at_utc_ms': session.startedAtUtcMs,
        'preparation_duration_ms': session.preparationDurationMs,
        'work_duration_ms': session.workDurationMs,
        'rest_duration_ms': session.restDurationMs,
        'round_count': session.roundCount,
        'ended_at_utc_ms': session.endedAtUtcMs,
      });
    });
    _notifyChange();
    return _ActivitySessionHandle(this, account, session.id);
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
    return _ActivitySessionHandle(this, account, sessionId);
  }

  Future<List<TimerSession>> readSessions() async {
    final account = _requireAccount();
    final generation = _generation;
    final db = await _database.connection;
    final rows = await db.query('timer_sessions', where: 'account_id = ?', whereArgs: [account]);
    _verifyRead(account, generation);
    return rows.map((row) => row.toTimerSession()).toList();
  }

  Future<void> addPhase(ActivitySessionHandle handle, CompletedPhase phase) =>
      addPhases(session: handle, phases: [phase]);

  Future<void> addPhases({
    required ActivitySessionHandle session,
    required List<CompletedPhase> phases,
  }) async {
    final handle = _verifyHandle(session);
    final batch = List<CompletedPhase>.of(phases);
    if (batch.any((phase) => phase.runId != handle.sessionId)) {
      throw StateError('Phase belongs to another session');
    }
    final db = await _database.connection;
    await db.transaction((txn) async {
      final sessions = await txn.query(
        'timer_sessions',
        columns: ['id'],
        where: 'id = ? AND account_id = ?',
        whereArgs: [handle.sessionId, handle.accountId],
      );
      if (sessions.isEmpty) throw StateError('Session not found');
      for (final phase in batch) {
        final existing = await txn.query(
          'completed_phases',
          where: 'id = ? OR (session_id = ? AND schedule_position = ?)',
          whereArgs: [phase.id, phase.runId, phase.schedulePosition],
        );
        if (existing.isNotEmpty) {
          if (existing.length != 1 || existing.single.toCompletedPhase() != phase) {
            throw StateError('Conflicting completed phase');
          }
          continue;
        }
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
      }
    });
    if (batch.isNotEmpty) _notifyChange();
  }

  Future<void> endSession({
    required ActivitySessionHandle session,
    required int endedAtUtcMs,
  }) async {
    final handle = _verifyHandle(session);
    final db = await _database.connection;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'timer_sessions',
        columns: ['ended_at_utc_ms'],
        where: 'id = ? AND account_id = ?',
        whereArgs: [handle.sessionId, handle.accountId],
      );
      if (rows.isEmpty) throw StateError('Session not found');
      final existing = rows.single['ended_at_utc_ms'] as int?;
      if (existing != null && existing != endedAtUtcMs) throw StateError('Conflicting session end');
      if (existing == null) {
        await txn.update(
          'timer_sessions',
          {'ended_at_utc_ms': endedAtUtcMs},
          where: 'id = ? AND account_id = ?',
          whereArgs: [handle.sessionId, handle.accountId],
        );
      }
    });
    _notifyChange();
  }

  Future<List<CompletedPhase>> readPhases(String sessionId) async {
    final account = _requireAccount();
    final generation = _generation;
    final db = await _database.connection;
    final rows = await db.rawQuery(
      'SELECT p.* FROM completed_phases p JOIN timer_sessions s ON s.id = p.session_id '
      'WHERE s.id = ? AND s.account_id = ? ORDER BY p.schedule_position',
      [sessionId, account],
    );
    _verifyRead(account, generation);
    return rows.map((row) => row.toCompletedPhase()).toList();
  }

  Future<List<DailyActivity>> readDailyActivity() async {
    final account = _requireAccount();
    final generation = _generation;
    final db = await _database.connection;
    final rows = await db.rawQuery(
      '''
      SELECT p.local_completion_date,
        SUM(CASE WHEN p.type = 'work' THEN 1 ELSE 0 END) AS round_count,
        SUM(CASE WHEN p.type = 'work' THEN p.duration_ms ELSE 0 END) AS work_duration_ms,
        SUM(CASE WHEN p.type = 'rest' THEN p.duration_ms ELSE 0 END) AS rest_duration_ms
      FROM completed_phases p JOIN timer_sessions s ON s.id = p.session_id
      WHERE s.account_id = ?
      GROUP BY p.local_completion_date
      ORDER BY p.local_completion_date DESC
    ''',
      [account],
    );
    _verifyRead(account, generation);
    return rows.map((row) => row.toDailyActivity()).toList();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription.cancel();
    await _changes.close();
  }
}
