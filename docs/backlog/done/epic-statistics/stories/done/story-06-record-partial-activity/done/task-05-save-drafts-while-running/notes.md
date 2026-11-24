# Notes

## Summary

- `_RecordingRun` in `default_timer_activity_recorder.dart` now keeps a paused flag and a 10 s draft timer. The timer starts with the run, stops on pause, end, dispose and finish, and restarts on resume (only when the run is not finished).
- Drafts come from `tracker.snapshot()` with `checkpointAtUtcMs` from `tracker.endInstant`. They are saved on each timer tick, on each phase change (including the finish), and on pause. Empty drafts and drafts equal to the last one are skipped. `end` writes only `finishRun`.
- The write queue drops drafts that are waiting when a newer write arrives. A failed draft does not block a later `finishRun`.
- `lib/features/timer/domain/timer_activity_recorder.dart`: only the doc comment on `failures` changed.
- Master was merged into the branch (`cfc298a`) before the last fix round.

## Evidence

- Draft every 10 s while running: "saves a draft every 10 s while running" passes.
- Draft at each phase change, none after the finish: "saves a draft at each phase change and stops after the finish" passes.
- Draft on pause, none while paused, next one 10 s after resume: "saves a draft on pause and none while paused" passes.
- Second pause saves no draft: "a second pause saves no draft" passes.
- Pause with a smaller elapsed saves no draft: "a pause with a smaller elapsed saves no draft" passes.
- Pause and resume after the finish do not restart the draft timer: passes.
- Resume while not paused does not restart the timer: passes.
- Empty and unchanged drafts are skipped: "skips empty and unchanged drafts" passes.
- `end` writes only `finishRun`: "end writes only finishRun" passes.
- Drafts wait for session creation: "drafts wait for the session creation" passes.
- A newer write supersedes a waiting draft: passes.
- A failed draft does not block a later `finishRun`: passes.
- A failed draft in flight is dropped when a write waits behind it: passes.
- All 32 recorder tests pass.

## Points to review

- `test/features/timer/data/default_timer_activity_recorder_test.dart:667`: "a failed draft does not block a later finishRun" never moves time forward after `end`. A test that elapses 10 s more would also catch a broken queue reset.
- `lib/features/timer/data/default_timer_activity_recorder.dart`: `resume` has no `_disposed` guard. A resume after dispose would start a periodic draft timer that nothing cancels. Writes are still skipped, so no data is written.
- `lib/features/timer/data/default_timer_activity_recorder.dart:8`: the `completed_phase.dart` import is out of alphabetical order.
- Manual Android check, still to do (the task asks for it in `notes.md`, which is not on the branch): start a workout, kill the app from recents mid-round, reopen it and confirm Statistics. This needs STAT-06-03 merged too.

## Run

implementer: Claude Sonnet 5.5; tests: Claude Sonnet 5.5; reviewer: Claude Opus 5.5
