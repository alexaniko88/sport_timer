# Notes

## Status before migration

Ready for diagnosis. The fix needs an agreed diagnosis and plan before code changes.

## Summary

- `AudioManager` now has `playCountdownBeep()` in place of `playPreparationSound()`.
- `DefaultAudioManager.playCountdownBeep()` plays `beep.mp3` once from 200 ms. I removed the chained `onPlayerComplete` beeps, the `_preparationSubscription` field and the unused `dart:async` import.
- `TimerViewModel._playSounds` now plays one beep whenever the displayed second changes to 3, 2 or 1. The earlier guards are unchanged: not stale, not finished, stage longer than 3 s. Beeps now follow the ticks instead of a timed chain.
- `fvm dart format` changed nothing, and `fvm flutter analyze --no-pub` on the three touched files reports no issues.
- I did not run any tests. The role says not to write tests, so I left the test renames and new tests for the tests stage. Until the fakes in `test/features/timer/presentation/timer_view_model_test.dart`, `test/features/timer/presentation/timer_page_test.dart` and `test/snapshots/ui_snapshots_test.dart` are renamed to `playCountdownBeep`, those tests won't compile. The grep acceptance check (`playPreparationSound` / `onPlayerComplete` no longer in `lib/` or `test/`) will also fail until then.

## Evidence

- Whole workout call order: `plays each sound once per event over the whole workout` in `timer_view_model_test.dart` — passed
- Preparation of 5 s beeps at elapsed 2, 3 and 4 s and not before 2 s: `plays one beep on each displayed second 3, 2 and 1` — passed
- Pause and resume at displayed 2 does not repeat the beep, and the next beep plays at 1: `does not repeat a beep when paused and resumed on the same number` — passed
- A late tick from 3 to 1 plays exactly one beep: `plays one beep when a late tick skips from 3 to 1` — passed
- No beep in a stage of 3 s or less, or on a stale tick: `does not beep in a stage of 3 seconds or less` and the existing stale-tick tests — passed
- `grep -rn "playPreparationSound\|onPlayerComplete" lib test` prints nothing — passed
- Project checks (`fvm dart tool/agent_check.dart --skip-build`): not verified (not run; the role only asks for the touched tests, format and analyze)

## Review notes

None.

## Run

implementer: Claude Sonnet 5.5; tests: Claude Sonnet 5.5; reviewer: Claude Opus 5.5

## Commands denied

- `F="test/features/timer/presentation/timer_view_model_test.dart test/features/timer/presentation/timer_page_test.dart test/snapshots/ui_snapshots_test.dart"; fvm dart format $F; fvm flutter analyze --no-pub $F | tail -5; fvm flutter test test/features/timer/presentation/timer_view_model_test.dart test/features/timer/presentation/timer_page_test.dart 2>&1 | tail -15; grep -rn "playPreparationSound\|onPlayerComplete" lib test; git status --short`
