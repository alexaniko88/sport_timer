import 'dart:async';

import 'package:sport_timer/features/statistics/data/activity_database.dart';
import 'package:sport_timer/features/statistics/data/extensions/activity_row_extension.dart';
import 'package:sport_timer/features/statistics/domain/activity_account_source.dart';
import 'package:sport_timer/features/statistics/domain/activity_session_creation.dart';
import 'package:sport_timer/features/statistics/domain/activity_session_handle.dart';
import 'package:sport_timer/features/statistics/domain/completed_phase.dart';
import 'package:sport_timer/features/statistics/domain/daily_activity.dart';
import 'package:sport_timer/features/statistics/domain/run_activity_summary.dart';
import 'package:sport_timer/features/statistics/domain/timer_session.dart';
import 'package:sqflite/sqflite.dart';

class _ActivitySessionHandle implements ActivitySessionHandle {
  final Object issuer;
  final String accountId;
  final int purgeEpoch;
  @override
  final String sessionId;

  _ActivitySessionHandle(
    this.issuer,
    this.accountId,
    this.sessionId,
    this.purgeEpoch,
  );
}

class _ActivitySessionCreation implements ActivitySessionCreation {
  final Object issuer;
  final TimerSession session;
  final int purgeEpoch;

  _ActivitySessionCreation(
    this.issuer,
    this.session,
    this.purgeEpoch,
  );
}

class ActivityAccess {
  final ActivityDatabase _database;
  final ActivityAccountSource _accounts;
  final StreamController<void> _changes = StreamController<void>.broadcast(sync: true);
  late final StreamSubscription<void> _subscription;
  int _generation = 0;
  // Bumped by every purge. Writes issued before a purge carry an older value and are dropped.
  int _purgeEpoch = 0;
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

  ActivitySessionCreation prepareSession(TimerSession session) {
    final account = _requireAccount();
    if (session.accountId != account) throw StateError('Session belongs to another account');
    return _ActivitySessionCreation(this, session, _purgeEpoch);
  }

  Future<ActivitySessionHandle> createSession(TimerSession session) async =>
      createPreparedSession(prepareSession(session));

  Future<ActivitySessionHandle> createPreparedSession(ActivitySessionCreation creation) async {
    if (_closed || creation is! _ActivitySessionCreation || !identical(creation.issuer, this)) {
      throw StateError('Invalid activity session creation');
    }
    final session = creation.session;
    final account = session.accountId;
    var isStale = false;
    final db = await _database.connection;
    await db.transaction((txn) async {
      if (creation.purgeEpoch != _purgeEpoch) {
        isStale = true;
        return;
      }
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
    if (!isStale) _notifyChange();
    return _ActivitySessionHandle(this, account, session.id, creation.purgeEpoch);
  }

  Future<ActivitySessionHandle> openSession(String sessionId) async {
    final account = _requireAccount();
    final generation = _generation;
    final purgeEpoch = _purgeEpoch;
    final db = await _database.connection;
    final rows = await db.query(
      'timer_sessions',
      columns: ['id'],
      where: 'id = ? AND account_id = ?',
      whereArgs: [sessionId, account],
    );
    _verifyRead(account, generation);
    if (rows.isEmpty) throw StateError('Session not found');
    return _ActivitySessionHandle(this, account, sessionId, purgeEpoch);
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
    var isStale = false;
    final db = await _database.connection;
    await db.transaction((txn) async {
      if (handle.purgeEpoch != _purgeEpoch) {
        isStale = true;
        return;
      }
      final sessions = await txn.query(
        'timer_sessions',
        columns: ['id'],
        where: 'id = ? AND account_id = ?',
        whereArgs: [handle.sessionId, handle.accountId],
      );
      if (sessions.isEmpty) throw StateError('Session not found');
      await _insertPhases(txn, batch);
    });
    if (batch.isNotEmpty && !isStale) _notifyChange();
  }

  Future<void> endSession({
    required ActivitySessionHandle session,
    required int endedAtUtcMs,
  }) async {
    final handle = _verifyHandle(session);
    var isStale = false;
    final db = await _database.connection;
    await db.transaction((txn) async {
      if (handle.purgeEpoch != _purgeEpoch) {
        isStale = true;
        return;
      }
      await _setEnd(txn, handle, endedAtUtcMs);
    });
    if (!isStale) _notifyChange();
  }

  // Stores the phases and the end time in one transaction, so a failure keeps nothing.
  Future<void> finishRun({
    required ActivitySessionHandle session,
    required List<CompletedPhase> phases,
    required int endedAtUtcMs,
  }) async {
    final handle = _verifyHandle(session);
    final batch = List<CompletedPhase>.of(phases);
    if (batch.any((phase) => phase.runId != handle.sessionId)) {
      throw StateError('Phase belongs to another session');
    }
    var isStale = false;
    final db = await _database.connection;
    await db.transaction((txn) async {
      if (handle.purgeEpoch != _purgeEpoch) {
        isStale = true;
        return;
      }
      // The end helper checks the session exists before any phase is inserted.
      await _insertPhasesAndEnd(txn, handle, batch, endedAtUtcMs);
    });
    if (!isStale) _notifyChange();
  }

  Future<void> _insertPhasesAndEnd(
    Transaction txn,
    _ActivitySessionHandle handle,
    List<CompletedPhase> batch,
    int endedAtUtcMs,
  ) async {
    final rows = await txn.query(
      'timer_sessions',
      columns: ['id'],
      where: 'id = ? AND account_id = ?',
      whereArgs: [handle.sessionId, handle.accountId],
    );
    if (rows.isEmpty) throw StateError('Session not found');
    await _insertPhases(txn, batch);
    await _setEnd(txn, handle, endedAtUtcMs);
    await txn.delete('draft_phases', where: 'session_id = ?', whereArgs: [handle.sessionId]);
  }

  // Replaces the hidden draft of a running session. Statistics never read it, so nothing is emitted.
  Future<void> saveDraft({
    required ActivitySessionHandle session,
    required List<CompletedPhase> phases,
    required int checkpointAtUtcMs,
  }) async {
    final handle = _verifyHandle(session);
    final batch = List<CompletedPhase>.of(phases);
    if (batch.any((phase) => phase.runId != handle.sessionId)) {
      throw StateError('Phase belongs to another session');
    }
    final db = await _database.connection;
    await db.transaction((txn) async {
      if (handle.purgeEpoch != _purgeEpoch) return;
      final rows = await txn.query(
        'timer_sessions',
        columns: ['ended_at_utc_ms'],
        where: 'id = ? AND account_id = ?',
        whereArgs: [handle.sessionId, handle.accountId],
      );
      if (rows.isEmpty) throw StateError('Session not found');
      if (rows.single['ended_at_utc_ms'] != null) return;
      await txn.delete('draft_phases', where: 'session_id = ?', whereArgs: [handle.sessionId]);
      for (final phase in batch) {
        await txn.insert('draft_phases', {
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
      await txn.update(
        'timer_sessions',
        {'checkpoint_at_utc_ms': checkpointAtUtcMs},
        where: 'id = ? AND account_id = ?',
        whereArgs: [handle.sessionId, handle.accountId],
      );
    });
  }

  // Turns the drafts of earlier runs into final records, each session in its own transaction.
  Future<void> recoverUnfinishedRuns({required int startedBeforeUtcMs}) async {
    if (_closed) throw StateError('Activity access is closed');
    final db = await _database.connection;
    final sessions = await db.query(
      'timer_sessions',
      columns: ['id'],
      where: 'ended_at_utc_ms IS NULL AND checkpoint_at_utc_ms IS NOT NULL AND started_at_utc_ms < ?',
      whereArgs: [startedBeforeUtcMs],
    );
    Object? firstError;
    StackTrace? firstStackTrace;
    var recovered = 0;
    for (final row in sessions) {
      try {
        await db.transaction((txn) => _recoverSession(txn, row['id'] as String));
        recovered++;
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }
    if (recovered > 0) _notifyChange();
    if (firstError case final error?) Error.throwWithStackTrace(error, firstStackTrace ?? StackTrace.current);
  }

  Future<void> _recoverSession(Transaction txn, String sessionId) async {
    final sessions = await txn.query(
      'timer_sessions',
      columns: ['checkpoint_at_utc_ms'],
      where: 'id = ? AND ended_at_utc_ms IS NULL AND checkpoint_at_utc_ms IS NOT NULL',
      whereArgs: [sessionId],
    );
    if (sessions.isEmpty) return;
    final drafts = await txn.query(
      'draft_phases',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'schedule_position',
    );
    await _insertPhases(txn, drafts.map((row) => row.toCompletedPhase()).toList());
    await txn.update(
      'timer_sessions',
      {'ended_at_utc_ms': sessions.single['checkpoint_at_utc_ms']},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    await txn.delete('draft_phases', where: 'session_id = ?', whereArgs: [sessionId]);
  }

  Future<void> _insertPhases(Transaction txn, List<CompletedPhase> batch) async {
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
  }

  Future<void> _setEnd(Transaction txn, _ActivitySessionHandle handle, int endedAtUtcMs) async {
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
  }

  Future<void> deleteAllActivity() async {
    if (_closed) throw StateError('Activity access is closed');
    _purgeEpoch++;
    final db = await _database.connection;
    await db.transaction((txn) async {
      await txn.delete('completed_phases');
      await txn.delete('timer_sessions');
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
        SUM(CASE WHEN p.type = 'work' AND (p.duration_ms >= 5000 OR p.duration_ms >= s.work_duration_ms) THEN 1 ELSE 0 END) AS round_count,
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

  Future<List<RunActivitySummary>> readDayActivity(String localDate) async {
    final account = _requireAccount();
    final generation = _generation;
    final db = await _database.connection;
    final rows = await db.rawQuery(
      '''
      SELECT s.*, p.local_completion_date,
        SUM(CASE WHEN p.type = 'work' AND (p.duration_ms >= 5000 OR p.duration_ms >= s.work_duration_ms) THEN 1 ELSE 0 END) AS day_round_count,
        SUM(CASE WHEN p.type = 'work' THEN p.duration_ms ELSE 0 END) AS day_work_duration_ms,
        SUM(CASE WHEN p.type = 'rest' THEN p.duration_ms ELSE 0 END) AS day_rest_duration_ms
      FROM completed_phases p JOIN timer_sessions s ON s.id = p.session_id
      WHERE s.account_id = ? AND p.local_completion_date = ?
      GROUP BY s.id
      ORDER BY s.started_at_utc_ms DESC, s.id DESC
    ''',
      [account, localDate],
    );
    _verifyRead(account, generation);
    return rows.map((row) => row.toRunActivitySummary()).toList();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription.cancel();
    await _changes.close();
  }
}
