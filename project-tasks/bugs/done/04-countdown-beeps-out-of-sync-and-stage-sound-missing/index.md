---
id: BUG-04
status: done
type: fix
complexity: low
depends-on: []
touches:
  - lib/features/timer/domain/audio_manager.dart
  - lib/features/timer/data/default_audio_manager.dart
  - lib/features/timer/presentation/timer_view_model.dart
  - test/features/timer/presentation/timer_view_model_test.dart
  - test/features/timer/presentation/timer_page_test.dart
  - test/snapshots/ui_snapshots_test.dart
skills: []
---

# Countdown beeps do not follow the displayed seconds

Category: [Bugs](../../index.md)

Related: [BUG-05: the stage sound is sometimes missing](../../05-stage-sound-sometimes-missing/index.md), the second half of the original report.

## Goal

In the last 3 seconds of a stage, one beep plays each time the displayed number changes to 3, 2 and 1, in time with the screen. Today the beeps run ahead of the countdown.

## Context

- **Expected:** one beep on each displayed second 3, 2 and 1, then the stage sound at 0.
- **Actual (reported on a Google Pixel 9, Android):** the three beeps do not line up with the numbers on screen.
- **Cause (confirmed in the code):**
  - `TimerViewModel._playSounds` (`lib/features/timer/presentation/timer_view_model.dart`) calls `_audioManager.playPreparationSound()` only once, on the tick where the stage enters its last 3 seconds.
  - `DefaultAudioManager.playPreparationSound` (`lib/features/timer/data/default_audio_manager.dart`) then plays three beeps as a chain: each next beep starts from the `onPlayerComplete` event of the previous one, after `audioPlayer.stop()`.
  - `assets/audio/beep.mp3` lasts about 0.86 s and each beep starts at 200 ms into the file, so each beep plays about 0.66 s. The beeps are therefore about 0.66 s plus the player's latency apart, not 1 s: beeps 2 and 3 come before the screen shows 2 and 1, and the error grows with each beep.
- The ViewModel already ticks on each whole elapsed second (`_tick` schedules the next tick at the next whole second) and reads the time from its time source, so a beep played from the tick follows the displayed number.
- Feature `timer`: contract in `domain/audio_manager.dart`, playback in `data/default_audio_manager.dart`, event logic in `presentation/timer_view_model.dart`.
- All sounds share the one `AudioPlayer` registered in `lib/di/di.dart`. That stays as it is.

## Behavior

- **Contract:** in `AudioManager` (`lib/features/timer/domain/audio_manager.dart`) replace `void playPreparationSound();` with `void playCountdownBeep();`, which plays exactly one beep.
- **Playback:** `DefaultAudioManager.playCountdownBeep()` plays `AssetSource('audio/beep.mp3')` once from `position: const Duration(milliseconds: 200)`, like today's `_playBeepSound`. Remove `playPreparationSound`, the `_preparationSubscription` field and its `onPlayerComplete` listener: no chained beeps remain.
- **When a beep plays (ViewModel):** on a tick, play one countdown beep when all of these hold:
  - the tick is not stale (same `isStale` rule as today: more than 2 s since the last tick),
  - the new state is not `finished`,
  - the stage is longer than 3 seconds (`stageLengthSeconds > _countdownSeconds`, as today),
  - the displayed seconds are 3, 2 or 1 (`next.currentSeconds <= _countdownSeconds`),
  - the displayed number changed: `previous == null`, or the stage changed, or `previous.currentSeconds != next.currentSeconds`.
- So a stage of 4 s or more gives beeps at 3, 2 and 1, then the existing stage sound at 0 (round start, round finish or workout done, unchanged).
- **Edge cases:**
  - Pausing and resuming inside the countdown never repeats a beep for the same number. A tick at pause or resume time that shows the same number plays nothing.
  - A late tick (less than 2 s late) that skips a number plays one beep for the number it shows, not one per skipped number.
  - A stale tick plays no beep, as today.
  - A stage of 3 s or less has no countdown beeps, as today.
- The stage sounds and their rules (`isRoundStart`, `isRoundEnd`, `isWorkoutEnd`) do not change.

## Decisions

- Split from the original BUG-04: this task fixes only the beep timing, whose cause is confirmed. The sometimes-missing stage sound is [BUG-05](../../05-stage-sound-sometimes-missing/index.md), which needs device logs first (user, during planning).
- One beep per tick, driven by the ViewModel, instead of a timed chain in the audio manager. The timer's ticks are the clock the screen uses, so the sound cannot drift from it.

## Out of scope

- New sounds, sound settings, volume, or which events have a sound.
- A separate `AudioPlayer` for the beeps, or any change to `lib/di/di.dart`.
- The missing stage sound (BUG-05).

## Files and tests

- Change `lib/features/timer/domain/audio_manager.dart`, `lib/features/timer/data/default_audio_manager.dart` and `lib/features/timer/presentation/timer_view_model.dart`.
- Rename the fakes' method from `playPreparationSound` to `playCountdownBeep` in `test/features/timer/presentation/timer_view_model_test.dart` (`_FakeAudioManager` records `'beep'`), `test/features/timer/presentation/timer_page_test.dart` and `test/snapshots/ui_snapshots_test.dart`.
- In `timer_view_model_test.dart`, update `plays each sound once per event over the whole workout` and `plays the countdown beep at 3 seconds left` to the new rule, and add tests for the edge cases above. The test helper `_params()` gives preparation 5 s, round 10 s, rest 4 s, 2 rounds.
- `DefaultAudioManager` has no unit test and no test setup for `AudioPlayer`; do not add one.
- No golden changes (no visible change).

## Acceptance

- [x] When a whole workout runs with `_params()`, then the sound calls are, in order: `beep, beep, beep, start` (preparation), `beep, beep, beep, finish` (round 1), `beep, beep, beep, start` (rest), `beep, beep, beep, done` (round 2). Check: `plays each sound once per event over the whole workout` in `test/features/timer/presentation/timer_view_model_test.dart`.
- [x] When the preparation of 5 s runs, then a beep is recorded exactly at elapsed 2 s, 3 s and 4 s (displayed 3, 2, 1) and none before 2 s. Check: a test in `timer_view_model_test.dart` that elapses the fake clock second by second and checks the calls after each step.
- [x] When the timer is paused at displayed 2 and resumed, then no second beep for 2 plays, and the next beep plays when 1 is displayed. Check: a test in `timer_view_model_test.dart`.
- [x] When a late tick (less than 2 s late) jumps from displayed 3 to displayed 1, then exactly one beep plays for that tick. Check: a test in `timer_view_model_test.dart` using a time source skew, like `plays only the current start sound after a late tick`.
- [x] When a stage lasts 3 s or less, or a tick is stale, then no countdown beep plays. Check: the existing `does not beep in a stage of 3 seconds or less` and stale-tick tests in `timer_view_model_test.dart` still pass.
- [x] When the code is searched, then `playPreparationSound` and `onPlayerComplete` no longer appear in `lib/` or `test/`. Check: `grep -rn "playPreparationSound\|onPlayerComplete" lib test` prints nothing.
- [x] When the project checks run, then they pass. Check: `fvm dart tool/agent_check.dart --skip-build`.
