---
id: STAT-06-05
status: ready
type: feat
complexity: 7
depends-on: [STAT-06-01, STAT-06-02, STAT-06-03]
touches:
  - lib/features/timer/data/default_timer_activity_recorder.dart
  - lib/features/timer/domain/timer_activity_recorder.dart
  - test/features/timer/data/default_timer_activity_recorder_test.dart
skills: []
---

# Save drafts while the timer runs

Story: [Record partial activity](../index.md)

Epic: [Statistics](../../../index.md)

## Goal

While a workout runs, make the recorder keep a hidden draft of the run in the database, so if the OS kills the app at most the time since the last draft is lost. A failing draft never blocks the final save. This task is the recorder half; [Store drafts and recover unfinished runs (STAT-06-03)](../task-03-store-drafts-and-recover/index.md) stores and recovers the drafts. Serves R5.

## Context

- Story rules: [Record partial activity](../index.md) (agreed behavior, decisions and shared contracts).
- After STAT-06-02, `_RecordingRun` in `lib/features/timer/data/default_timer_activity_recorder.dart` uses `ActivityRunTracker` and writes the run once with `ActivityRepository.finishRun` when it ends. Writes go through its queue (`_enqueue`, `_drain`, `_blocked`, `_failedAttempts`, `_retryTimer`, `_maxAutoRetries` 5), which retries failures and reports them through `_onFailure` on the recorder's `failures` stream. `begin` enqueues the session creation first.
- `lib/features/timer/domain/timer_activity_recorder.dart`: the doc comments on `TimerActivityRecorder.failures` and `TimerActivityRun`.
- `fake_async` is already a dev dependency.

## Contract

- `ActivityRunTracker` (`snapshot()`, `endInstant`, `isFinished`, `lastElapsed`, `pause`, `resume`) — provided by [Count partial progress in whole seconds (STAT-06-01)](../done/task-01-count-partial-progress/index.md). Not changed here.
- `ActivityRepository.finishRun` and the write-once `end` — provided by [Save the run once when leaving the timer (STAT-06-02)](../task-02-save-on-leaving-timer/index.md).
- `ActivityRepository.saveDraft({session, phases, checkpointAtUtcMs})` — provided by [Store drafts and recover unfinished runs (STAT-06-03)](../task-03-store-drafts-and-recover/index.md): replaces the session's draft; writes nothing for a stale handle or an ended session; returns `Failure` on errors.

Recorder (`_RecordingRun`) — changed.

- It keeps a private `_paused` flag next to `_ended`. This updates STAT-06-01, where `_RecordingRun` keeps only `_ended` and the write queue; the tracker itself is not changed.
- `pause(elapsed)`: only when not `_paused`, not ended, `!tracker.isFinished` (a pause after the finish does nothing), and `elapsed` is not smaller than `tracker.lastElapsed` (today's rule in `_RecordingRun.pause` and STAT-06-01's `tracker.pause`), it calls `tracker.pause(elapsed)`, saves the pause draft, cancels the periodic timer and sets `_paused`. Otherwise it does nothing: no draft, the periodic timer keeps running and `_paused` is unchanged.
- `resume()`: only when `_paused` and not ended, it calls `tracker.resume()` and clears `_paused`; it restarts the periodic timer (a fresh 10 s period) only when also `!tracker.isFinished`. Otherwise it does nothing. After the finish nothing restarts the periodic timer.
- A repeated `pause` or `resume` does nothing: no draft, no timer change.

It saves a draft of `tracker.snapshot()` with `checkpointAtUtcMs` from `tracker.endInstant` at these moments:

- **Periodic:** a `Timer.periodic(Duration(seconds: 10))` started in `begin`. It is cancelled in `pause`, started again (a fresh 10 s period) in `resume`, and cancelled for good when `tracker.isFinished` becomes true, in `end` and in `dispose`. Each firing saves a draft of the snapshot as of the last `reconcile`; the timer does not reconcile by itself.
- **Phase change:** in `reconcile`, when at least one phase completed. This covers the finish.
- **Pause:** in `pause`, after the tracker paused, under the guard above.

No draft is saved:

- when the snapshot is empty (for example during preparation);
- when the snapshot and `endInstant` are equal to the last draft enqueued (for example the periodic timer firing with no new `reconcile`);
- from `end`: `end` reconciles to its elapsed without enqueuing a draft, then enqueues only `finishRun`;
- after the finish draft: once `tracker.isFinished` is true and its phase-change draft was enqueued, the periodic timer is cancelled and no further draft is saved.

Queue rule:

- Drafts are enqueued after the session creation write, like every write, so they wait while the session is not created yet.
- A draft can be superseded. When a new draft or the `finishRun` is enqueued, every draft in the queue that is not being written right now is removed first. This includes a failed draft at the head of a blocked queue: removing it cancels the retry timer, clears the blocked state, resets `_failedAttempts` to 0 and lets the queue drain at once.
- A draft that is being written right now is left to finish. If it then fails while anything is already waiting behind it, the failure is reported on `failures` and the draft is dropped at once (no block, no retry timer, `_failedAttempts` reset to 0), and the queue goes on draining.
- A failed draft with nothing behind it is reported on `failures`, stays at the head and counts toward the automatic retry limit until something is enqueued. Because a later draft or `finishRun` always removes a failed draft, a failing draft can never block `finishRun`.

`TimerActivityRecorder.failures` doc comment in `lib/features/timer/domain/timer_activity_recorder.dart` — changed, comment only, no API change. New meaning: failed session creation and `finishRun` writes stay queued until retried; a failed draft is dropped when a newer write replaces it or a write is waiting behind it.

## Decisions

- **Keep the draft safety net:** the user keeps the final save on leaving as the only normal save. The draft is used only after a kill.
- **Draft moments:** every 10 s while running, at each phase change (including finish) and on pause. No "app went to background" trigger, because the foreground service keeps ticks running and the recorder stays free of Flutter lifecycle code. Chosen by the user.

## Out of scope

- Draft storage, recovery and the startup call (STAT-06-03).
- Any change to `ActivityRunTracker`.
- Integration tests and device runs. The integration test setup does not exist yet.

## Files and tests

- Fakes: only the `_Repository` fake in `test/features/timer/data/default_timer_activity_recorder_test.dart` needs a real `saveDraft`. It records each call in its own `drafts` list, separate from the session creation and `finishRun` records, succeeds by default, and can be made to fail or to hold a call open. The other `ActivityRepository` fakes use `noSuchMethod` and need no change.
- `test/features/timer/data/default_timer_activity_recorder_test.dart` (unit): the new timer-driven cases run inside `fakeAsync` and drive the run by calling `reconcile`, `pause` and `resume` directly.
- How the existing recorder tests adapt (as they stand after STAT-06-02):
  - They keep reading only the session creation and `finishRun` records; drafts are allowed before `end` and are not asserted there. So "writes the run only once at end" (STAT-06-02) keeps its meaning by checking session creation and `finishRun` only.
  - Failure-path tests count only `finishRun` and session creation failures, because the fake's `saveDraft` succeeds unless a test makes it fail: "retries a failed batch with identical phase data and keeps the original owner" and "retries a failed finishRun with identical values" (STAT-06-02). Draft failures are tested only by the new cases below.
  - Every existing test that starts a run ends it with `end`, which cancels the periodic timer: "reconciles every crossed boundary once and stores its logical instant", "pause excludes paused time and stop excludes incomplete work" (renamed by STAT-06-02), "retries a failed batch with identical phase data and keeps the original owner", "finishes queued writes after the caller ends a run while creation is pending", "omits zero-duration stages and preparation from activity", "applies a forward clock correction after observed boundaries across midnight", "uses a backward correction for future boundaries across midnight and a pause", "keeps delayed boundaries immutable when a backward correction is first observed", "attributes a delayed callback to the day the phase finished", "attributes a phase after a pause spanning midnight to its completion day", "ending at ${elapsed}ms records only completed phases" (renamed by STAT-06-02), and STAT-06-02's "leaving mid-round finishes the run with the partial work", "leaving while paused saves the time up to the pause", "leaving after the finish saves every phase", "leaving during preparation finishes the run with no phases", "writes the run only once at end" and "retries a failed finishRun with identical values". "does not start recording without an account" starts no run. Any recorder test that starts a run must either end or dispose it, or run inside `fakeAsync`.
- `lib/features/timer/domain/timer_activity_recorder.dart`: update only the doc comment on `failures` as written in Contract; no API change and no test.
- In `notes.md`, list for the user a manual Android check to run after merge (STAT-06-03 must be merged too): start a workout, kill the app from recents mid-round, reopen it and confirm Statistics. The runner does not run it.

## Acceptance

- [ ] When a run is running, then a draft is saved every 10 s with the snapshot of the last `reconcile`. Check: `test/features/timer/data/default_timer_activity_recorder_test.dart` "saves a draft every 10 s while running".
- [ ] When a phase completes during `reconcile`, including the last one, then a draft is saved, and after the finish draft no further draft is saved. Check: `test/features/timer/data/default_timer_activity_recorder_test.dart` "saves a draft at each phase change and stops after the finish".
- [ ] When the run pauses, then a draft is saved, no periodic draft is saved while paused, and after `resume` the next periodic draft comes 10 s later. Check: `test/features/timer/data/default_timer_activity_recorder_test.dart` "saves a draft on pause and none while paused".
- [ ] When `pause` is called a second time while already paused, then no second draft is saved and the periodic timer stays cancelled. Check: `test/features/timer/data/default_timer_activity_recorder_test.dart` "a second pause saves no draft".
- [ ] When `pause` is called with an `elapsed` smaller than `tracker.lastElapsed`, then no draft is saved, the periodic timer keeps running and the run is not paused. Check: `test/features/timer/data/default_timer_activity_recorder_test.dart` "a pause with a smaller elapsed saves no draft".
- [ ] When `pause` and then `resume` are called after the finish draft, then no draft is saved and the periodic timer is not restarted. Check: `test/features/timer/data/default_timer_activity_recorder_test.dart` "pause and resume after the finish do not restart the draft timer".
- [ ] When `resume` is called while not paused, then the periodic timer is not restarted and the next periodic draft keeps its original 10 s schedule. Check: `test/features/timer/data/default_timer_activity_recorder_test.dart` "resume while not paused does not restart the timer".
- [ ] When the snapshot is empty (preparation) or equal to the last draft with the same `endInstant`, then no draft is saved. Check: `test/features/timer/data/default_timer_activity_recorder_test.dart` "skips empty and unchanged drafts".
- [ ] When `end` runs, then it enqueues only `finishRun` and no draft, and no draft is saved afterwards. Check: `test/features/timer/data/default_timer_activity_recorder_test.dart` "end writes only finishRun".
- [ ] When session creation is still pending, then drafts wait behind it and are written after it. Check: `test/features/timer/data/default_timer_activity_recorder_test.dart` "drafts wait for the session creation".
- [ ] When a draft is waiting in the queue and a new draft or `finishRun` is enqueued, then the waiting draft is never written. Check: `test/features/timer/data/default_timer_activity_recorder_test.dart` "a newer write supersedes a waiting draft".
- [ ] When a draft save fails and `finishRun` is enqueued after the failure, then the failure is reported on `failures` and `finishRun` runs without a manual retry. Check: `test/features/timer/data/default_timer_activity_recorder_test.dart` "a failed draft does not block a later finishRun".
- [ ] When a draft that is being written fails while `finishRun` is already waiting behind it, then the failure is reported on `failures`, the draft is dropped and `finishRun` runs without a manual retry. Check: `test/features/timer/data/default_timer_activity_recorder_test.dart` "a failed draft in flight is dropped when a write waits behind it".
- [ ] When all changed files are checked, then format, analyze, the mirrored tests and the boundary test pass. Check: `fvm dart tool/agent_check.dart --skip-build`.
