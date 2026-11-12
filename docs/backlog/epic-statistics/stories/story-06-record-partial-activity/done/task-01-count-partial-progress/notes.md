# Notes

## Summary

- New `ActivityRunTracker` (`lib/features/timer/data/activity_run_tracker.dart`) owns the counting state: `reconcile`, `pause`, `resume`, `lastElapsed`, `snapshot()`, `endInstant`, `isFinished`.
- `snapshot()` adds the current work or rest phase in whole seconds (rounded down, from 1 s). While paused it uses the elapsed time and instant held at the pause.
- Phase IDs are kept per stage, so a partial phase keeps its ID when it completes.
- `default_timer_activity_recorder.dart` now delegates counting to the tracker; what it writes is unchanged.

## Evidence

- Partial work counts whole seconds (83.8 s gives 83000): "partial work counts whole seconds", passed.
- Partial rest counts whole seconds: "partial rest counts whole seconds", passed.
- No partial phase under 1 s: "no partial phase under one second", passed.
- Empty snapshot during preparation: "snapshot is empty during preparation", passed.
- Pause excludes paused time: "pause excludes paused time from the partial phase", passed.
- Reconcile while paused leaves the snapshot unchanged: passed.
- `pause` returns the phases it completes: passed.
- Late reconcile across several phases: passed.
- Same ID from partial to completed: passed.
- Equal snapshots without progress: passed.
- Midnight date: passed.
- `isFinished` and `endInstant` (running and paused): passed.
- Existing recorder tests unchanged and passing.

## Points to review

- lib/features/timer/data/activity_run_tracker.dart:138: needless `.call` tear-off in `_phaseIds.putIfAbsent(index, _newId.call)`; use `_newId`.

## Run

implementer: Claude Sonnet 5.5; tests: Claude Sonnet 5.5; reviewer: Claude Opus 5.5
