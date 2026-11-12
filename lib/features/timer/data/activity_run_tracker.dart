import 'package:sport_timer/core/extensions/date_time_extension.dart';
import 'package:sport_timer/features/statistics/domain/completed_phase.dart';
import 'package:sport_timer/features/timer/domain/timer_schedule.dart';
import 'package:sport_timer/features/timer/domain/timer_status.dart';

typedef ActivityWallClock = DateTime Function();
typedef ActivityIdGenerator = String Function();

/// Counts the phases of one timer run from the elapsed time it is told about.
/// It reports finished phases at full length and the phase in progress in whole seconds.
class ActivityRunTracker {
  static const _clockTolerance = Duration(seconds: 1);

  final TimerSchedule _schedule;
  final String _sessionId;
  final ActivityWallClock _clock;
  final ActivityIdGenerator _newId;
  final _completed = <CompletedPhase>[];
  final _phaseIds = <int, String>{};
  DateTime _segmentStart;
  DateTime _lastInstant;
  Duration _segmentElapsed = Duration.zero;
  Duration _lastElapsed = Duration.zero;
  DateTime? _finishedAt;
  int _nextStage = 0;
  bool _paused = false;
  Duration _pausedElapsed = Duration.zero;
  DateTime _pausedInstant;

  ActivityRunTracker({
    required TimerSchedule schedule,
    required String sessionId,
    required DateTime startedAt,
    required ActivityWallClock clock,
    required ActivityIdGenerator newId,
  })  : _schedule = schedule,
        _sessionId = sessionId,
        _segmentStart = startedAt.toUtc(),
        _lastInstant = startedAt.toUtc(),
        _pausedInstant = startedAt.toUtc(),
        _clock = clock,
        _newId = newId;

  Duration get lastElapsed => _lastElapsed;

  bool get isFinished => _nextStage >= _schedule.stages.length;

  DateTime get endInstant => _finishedAt ?? (_paused ? _clock().toUtc() : _lastInstant);

  List<CompletedPhase> reconcile(Duration elapsed) {
    if (elapsed < _lastElapsed) return const [];
    _lastElapsed = elapsed;
    if (_paused) return const [];
    final completed = <CompletedPhase>[];
    while (_nextStage < _schedule.stages.length) {
      final stage = _schedule.stages[_nextStage];
      final boundary = Duration(seconds: stage.endSeconds);
      if (boundary > elapsed) break;
      final instant = _segmentStart.add(boundary - _segmentElapsed);
      if (stage.type == TimerStatus.round || stage.type == TimerStatus.rest) {
        completed.add(
          _phase(
            index: _nextStage,
            stage: stage,
            durationMs: Duration(seconds: stage.lengthSeconds).inMilliseconds,
            instant: instant,
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
    _completed.addAll(completed);
    return completed;
  }

  List<CompletedPhase> pause(Duration elapsed) {
    if (_paused || elapsed < _lastElapsed) return const [];
    final completed = reconcile(elapsed);
    _paused = true;
    _pausedElapsed = elapsed;
    _pausedInstant = _lastInstant;
    return completed;
  }

  void resume() {
    if (!_paused) return;
    _segmentStart = _clock().toUtc();
    _lastInstant = _segmentStart;
    _segmentElapsed = _lastElapsed;
    _paused = false;
  }

  /// Every finished phase at full length, then the phase in progress when it
  /// has at least one whole second of work or rest.
  List<CompletedPhase> snapshot() {
    return [
      ..._completed,
      if (_partialPhase() case final partial?) partial,
    ];
  }

  CompletedPhase? _partialPhase() {
    if (isFinished) return null;
    final stage = _schedule.stages[_nextStage];
    if (stage.type != TimerStatus.round && stage.type != TimerStatus.rest) return null;
    final activeElapsed = _paused ? _pausedElapsed : _lastElapsed;
    final wholeSeconds = (activeElapsed - Duration(seconds: stage.startSeconds)).inSeconds;
    if (wholeSeconds < 1) return null;
    final instant = _paused ? _pausedInstant : _segmentStart.add(_lastElapsed - _segmentElapsed);
    return _phase(
      index: _nextStage,
      stage: stage,
      durationMs: Duration(seconds: wholeSeconds).inMilliseconds,
      instant: instant,
    );
  }

  CompletedPhase _phase({
    required int index,
    required TimerStage stage,
    required int durationMs,
    required DateTime instant,
  }) {
    // The device's timezone when the phase is built determines the local date.
    final local = instant.toLocal();
    return CompletedPhase(
      id: _phaseIds.putIfAbsent(index, _newId.call),
      runId: _sessionId,
      schedulePosition: index,
      type: stage.type == TimerStatus.round ? CompletedPhaseType.work : CompletedPhaseType.rest,
      roundNumber: stage.round,
      durationMs: durationMs,
      completedAtUtcMs: instant.millisecondsSinceEpoch,
      localCompletionDate: local.asIsoDate,
      utcOffsetMinutes: local.timeZoneOffset.inMinutes,
    );
  }
}
