import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/statistics/domain/activity_account_source.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';
import 'package:sport_timer/features/statistics/domain/completed_phase.dart';
import 'package:sport_timer/features/statistics/domain/activity_session_creation.dart';
import 'package:sport_timer/features/statistics/domain/activity_session_handle.dart';
import 'package:sport_timer/features/statistics/domain/timer_session.dart';
import 'package:sport_timer/features/timer/data/activity_run_tracker.dart';
import 'package:sport_timer/features/timer/domain/timer_activity_recorder.dart';
import 'package:sport_timer/features/timer/domain/timer_params.dart';
import 'package:sport_timer/features/timer/domain/timer_schedule.dart';
import 'package:uuid/uuid.dart';

typedef _WriteAction = Future<Result<void>> Function();
typedef _FailureCallback = void Function(Exception error);
typedef _DrainedCallback = void Function(_RecordingRun run);

class DefaultTimerActivityRecorder implements TimerActivityRecorder {
  final ActivityRepository _repository;
  final ActivityAccountSource _accounts;
  final ActivityWallClock _clock;
  final ActivityIdGenerator _newId;
  final _failures = StreamController<Exception>.broadcast();
  final _runs = <_RecordingRun>{};

  DefaultTimerActivityRecorder(
    this._repository,
    this._accounts, {
    ActivityWallClock? clock,
    ActivityIdGenerator? newId,
  })  : _clock = clock ?? DateTime.now,
        _newId = newId ?? const Uuid().v4;

  @override
  Stream<Exception> get failures => _failures.stream;

  @override
  Result<TimerActivityRun> start(TimerParams params) {
    final account = _accounts.currentAccountId;
    if (account == null || account.isEmpty) return Failure(Exception('No signed-in account'));
    final now = _clock();
    final session = TimerSession(
      id: _newId(),
      accountId: account,
      startedAtUtcMs: now.toUtc().millisecondsSinceEpoch,
      preparationDurationMs: params.preparationTime.inMilliseconds,
      workDurationMs: params.roundTime.inMilliseconds,
      restDurationMs: params.restTime.inMilliseconds,
      roundCount: params.rounds,
    );
    final prepared = _repository.prepareSession(session);
    return prepared.fold(
      onSuccess: (creation) => _beginRun(
        params: params,
        session: session,
        startedAt: now,
        creation: creation,
      ),
      onFailure: (error) => Failure(error),
    );
  }

  Result<TimerActivityRun> _beginRun({
    required TimerParams params,
    required TimerSession session,
    required DateTime startedAt,
    required ActivitySessionCreation creation,
  }) {
    final run = _RecordingRun(
      repository: _repository,
      creation: creation,
      sessionId: session.id,
      schedule: TimerSchedule.fromParams(params),
      startedAt: startedAt,
      clock: _clock,
      newId: _newId,
      onFailure: _reportFailure,
      onDrained: _runs.remove,
    );
    _runs.add(run);
    run.begin();
    return Success(run);
  }

  void _reportFailure(Exception error) {
    debugPrint('$runtimeType:: activity write failed: $error');
    if (!_failures.isClosed) _failures.add(error);
  }

  @override
  void retryPendingWrites() {
    for (final run in _runs.toList()) {
      run.retry();
    }
  }

  // Stops every retry timer and closes the failure stream. Queued writes are dropped.
  void dispose() {
    for (final run in _runs) {
      run.dispose();
    }
    _runs.clear();
    _failures.close();
  }
}

class _PendingWrite {
  final _WriteAction action;
  final bool isDraft;

  _PendingWrite(this.action, {this.isDraft = false});
}

class _RecordingRun implements TimerActivityRun {
  static const _retryDelay = Duration(seconds: 5);
  static const _draftPeriod = Duration(seconds: 10);
  static const _maxAutoRetries = 5;

  final ActivityRepository _repository;
  final ActivitySessionCreation _creation;
  final ActivityRunTracker _tracker;
  final _FailureCallback _onFailure;
  final _DrainedCallback _onDrained;
  final _pending = Queue<_PendingWrite>();
  ActivitySessionHandle? _session;
  bool _ended = false;
  bool _paused = false;
  bool _isWriting = false;
  bool _draining = false;
  bool _blocked = false;
  bool _disposed = false;
  int _failedAttempts = 0;
  Timer? _retryTimer;
  Timer? _draftTimer;
  List<CompletedPhase>? _lastDraftPhases;
  DateTime? _lastDraftInstant;

  _RecordingRun({
    required ActivityRepository repository,
    required ActivitySessionCreation creation,
    required String sessionId,
    required TimerSchedule schedule,
    required DateTime startedAt,
    required ActivityWallClock clock,
    required ActivityIdGenerator newId,
    required _FailureCallback onFailure,
    required _DrainedCallback onDrained,
  })  : _repository = repository,
        _creation = creation,
        _tracker = ActivityRunTracker(
          schedule: schedule,
          sessionId: sessionId,
          startedAt: startedAt,
          clock: clock,
          newId: newId,
        ),
        _onFailure = onFailure,
        _onDrained = onDrained;

  void begin() {
    _draftTimer = Timer.periodic(_draftPeriod, (_) => _saveDraft());
    _enqueue(() async {
      final result = await _repository.createPreparedSession(_creation);
      return result.fold(
        onSuccess: (session) {
          _session = session;
          return const Success(null);
        },
        onFailure: (error) => Failure(error),
      );
    });
  }

  @override
  void reconcile(Duration elapsed) {
    if (_ended) return;
    final completed = _tracker.reconcile(elapsed);
    if (completed.isNotEmpty) _saveDraft();
    if (_tracker.isFinished) _stopDraftTimer();
  }

  @override
  void pause(Duration elapsed) {
    if (_paused || _ended || _tracker.isFinished || elapsed < _tracker.lastElapsed) return;
    _tracker.pause(elapsed);
    _paused = true;
    _saveDraft();
    _stopDraftTimer();
  }

  @override
  void resume() {
    if (!_paused || _ended) return;
    _tracker.resume();
    _paused = false;
    if (!_tracker.isFinished) _draftTimer = Timer.periodic(_draftPeriod, (_) => _saveDraft());
  }

  void _stopDraftTimer() {
    _draftTimer?.cancel();
    _draftTimer = null;
  }

  // Keeps a hidden copy of the run so a killed app loses at most the time since the last draft.
  void _saveDraft() {
    if (_ended || _disposed) return;
    final phases = _tracker.snapshot();
    final checkpoint = _tracker.endInstant;
    if (phases.isEmpty) return;
    if (_lastDraftInstant == checkpoint && listEquals(_lastDraftPhases, phases)) return;
    _lastDraftPhases = phases;
    _lastDraftInstant = checkpoint;
    _enqueue(
      () async {
        final session = _session;
        if (session == null) return Failure(Exception('Activity session is unavailable'));
        return _repository.saveDraft(
          session: session,
          phases: phases,
          checkpointAtUtcMs: checkpoint.millisecondsSinceEpoch,
        );
      },
      isDraft: true,
    );
  }

  @override
  void end(Duration elapsed) {
    if (_ended || elapsed < _tracker.lastElapsed) return;
    _tracker.reconcile(elapsed);
    // Captured once so a retry sends the same phases and end time.
    final phases = _tracker.snapshot();
    final endedAtUtcMs = _tracker.endInstant.millisecondsSinceEpoch;
    _ended = true;
    _stopDraftTimer();
    _enqueue(() async {
      final session = _session;
      if (session == null) return Failure(Exception('Activity session is unavailable'));
      return _repository.finishRun(session: session, phases: phases, endedAtUtcMs: endedAtUtcMs);
    });
  }

  void _enqueue(_WriteAction action, {bool isDraft = false}) {
    _dropWaitingDrafts();
    _pending.add(_PendingWrite(action, isDraft: isDraft));
    if (!_blocked) unawaited(_drain());
  }

  // A newer write replaces every draft that is not being written right now,
  // including a failed draft at the head of a blocked queue.
  void _dropWaitingDrafts() {
    if (_pending.isEmpty) return;
    final head = _pending.first;
    final isHeadWriting = _isWriting;
    final hadFailedHead = head.isDraft && !isHeadWriting;
    _pending.removeWhere((write) => write.isDraft && !(isHeadWriting && identical(write, head)));
    if (hadFailedHead && _blocked) {
      _retryTimer?.cancel();
      _retryTimer = null;
      _blocked = false;
      _failedAttempts = 0;
    }
  }

  // A manual retry starts a fresh set of automatic attempts.
  void retry() {
    _failedAttempts = 0;
    _resumeDrain();
  }

  void dispose() {
    _disposed = true;
    _stopDraftTimer();
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void _resumeDrain() {
    if (_disposed) return;
    _retryTimer?.cancel();
    _retryTimer = null;
    _blocked = false;
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_draining || _blocked || _disposed) return;
    _draining = true;
    while (_pending.isNotEmpty && !_disposed) {
      final write = _pending.first;
      _isWriting = true;
      final result = await write.action();
      _isWriting = false;
      if (_disposed) break;
      if (result case Failure<void>(:final error)) {
        if (write.isDraft && _pending.length > 1) {
          // A write is already waiting, so the stale draft is dropped instead of blocking it.
          _onFailure(error);
          _pending.removeFirst();
          _failedAttempts = 0;
          continue;
        }
        _blocked = true;
        _failedAttempts++;
        _onFailure(error);
        // After the limit the run waits for a manual retry, so a permanent error does not loop forever.
        if (_failedAttempts < _maxAutoRetries) _retryTimer = Timer(_retryDelay, _resumeDrain);
        break;
      }
      _failedAttempts = 0;
      _pending.removeFirst();
    }
    _draining = false;
    if (_ended && _pending.isEmpty) _onDrained(this);
  }
}
