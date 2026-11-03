import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:sport_timer/core/extensions/date_time_extension.dart';
import 'package:sport_timer/core/result.dart';
import 'package:sport_timer/features/statistics/domain/activity_account_source.dart';
import 'package:sport_timer/features/statistics/domain/activity_repository.dart';
import 'package:sport_timer/features/statistics/domain/activity_session_creation.dart';
import 'package:sport_timer/features/statistics/domain/activity_session_handle.dart';
import 'package:sport_timer/features/statistics/domain/completed_phase.dart';
import 'package:sport_timer/features/statistics/domain/timer_session.dart';
import 'package:sport_timer/features/timer/domain/timer_activity_recorder.dart';
import 'package:sport_timer/features/timer/domain/timer_params.dart';
import 'package:sport_timer/features/timer/domain/timer_schedule.dart';
import 'package:sport_timer/features/timer/domain/timer_status.dart';
import 'package:uuid/uuid.dart';

typedef ActivityWallClock = DateTime Function();
typedef ActivityIdGenerator = String Function();
typedef _PendingWrite = Future<Result<void>> Function();
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

class _RecordingRun implements TimerActivityRun {
  static const _retryDelay = Duration(seconds: 5);
  static const _maxAutoRetries = 5;
  static const _clockTolerance = Duration(seconds: 1);

  final ActivityRepository _repository;
  final ActivitySessionCreation _creation;
  final String _sessionId;
  final TimerSchedule _schedule;
  final ActivityWallClock _clock;
  final ActivityIdGenerator _newId;
  final _FailureCallback _onFailure;
  final _DrainedCallback _onDrained;
  final _pending = Queue<_PendingWrite>();
  ActivitySessionHandle? _session;
  DateTime _segmentStart;
  DateTime _lastInstant;
  Duration _segmentElapsed = Duration.zero;
  Duration _lastElapsed = Duration.zero;
  DateTime? _finishedAt;
  int _nextStage = 0;
  bool _paused = false;
  bool _ended = false;
  bool _draining = false;
  bool _blocked = false;
  bool _disposed = false;
  int _failedAttempts = 0;
  Timer? _retryTimer;

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
        _sessionId = sessionId,
        _schedule = schedule,
        _segmentStart = startedAt.toUtc(),
        _lastInstant = startedAt.toUtc(),
        _clock = clock,
        _newId = newId,
        _onFailure = onFailure,
        _onDrained = onDrained;

  void begin() {
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
    if (_ended || elapsed < _lastElapsed) return;
    _lastElapsed = elapsed;
    if (_paused) return;
    final completed = <CompletedPhase>[];
    while (_nextStage < _schedule.stages.length) {
      final stage = _schedule.stages[_nextStage];
      final boundary = Duration(seconds: stage.endSeconds);
      if (boundary > elapsed) break;
      final instant = _segmentStart.add(boundary - _segmentElapsed);
      if (stage.type == TimerStatus.round || stage.type == TimerStatus.rest) {
        // The device's timezone at reconciliation determines the local date.
        final local = instant.toLocal();
        completed.add(
          CompletedPhase(
            id: _newId(),
            runId: _sessionId,
            schedulePosition: _nextStage,
            type: stage.type == TimerStatus.round ? CompletedPhaseType.work : CompletedPhaseType.rest,
            roundNumber: stage.round,
            durationMs: Duration(seconds: stage.lengthSeconds).inMilliseconds,
            completedAtUtcMs: instant.millisecondsSinceEpoch,
            localCompletionDate: local.asIsoDate,
            utcOffsetMinutes: local.timeZoneOffset.inMinutes,
          ),
        );
      }
      _nextStage++;
      if (_nextStage == _schedule.stages.length) _finishedAt = instant;
    }
    final projected = _segmentStart.add(elapsed - _segmentElapsed);
    final observed = _clock().toUtc();
    // A correction is only known at observation, so earlier boundaries keep
    // their original projection and future boundaries use the observed clock.
    if (observed.difference(projected).abs() > _clockTolerance) {
      _segmentStart = observed;
      _segmentElapsed = elapsed;
      _lastInstant = observed;
    } else {
      _lastInstant = projected;
    }
    if (completed.isNotEmpty) {
      _enqueue(() async {
        final session = _session;
        if (session == null) return Failure(Exception('Activity session is unavailable'));
        return _repository.recordPhases(session: session, phases: completed);
      });
    }
  }

  @override
  void pause(Duration elapsed) {
    if (_ended || _paused || elapsed < _lastElapsed) return;
    reconcile(elapsed);
    _paused = true;
  }

  @override
  void resume() {
    if (_ended || !_paused) return;
    _segmentStart = _clock().toUtc();
    _lastInstant = _segmentStart;
    _segmentElapsed = _lastElapsed;
    _paused = false;
  }

  @override
  void end(Duration elapsed) {
    if (_ended || elapsed < _lastElapsed) return;
    reconcile(elapsed);
    final end = _finishedAt ?? (_paused ? _clock().toUtc() : _lastInstant);
    _ended = true;
    _enqueue(() async {
      final session = _session;
      if (session == null) return Failure(Exception('Activity session is unavailable'));
      return _repository.endSession(session: session, endedAtUtcMs: end.millisecondsSinceEpoch);
    });
  }

  void _enqueue(_PendingWrite write) {
    _pending.add(write);
    if (!_blocked) unawaited(_drain());
  }

  // A manual retry starts a fresh set of automatic attempts.
  void retry() {
    _failedAttempts = 0;
    _resumeDrain();
  }

  void dispose() {
    _disposed = true;
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
      final result = await _pending.first();
      if (_disposed) break;
      if (result case Failure<void>(:final error)) {
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
