---
id: BUG-05
status: draft
type: fix
complexity: 6
depends-on: [BUG-04]
touches:
  - lib/features/timer/data/default_audio_manager.dart
  - lib/features/timer/presentation/timer_view_model.dart
skills: []
---

# The stage sound is sometimes missing

Category: [Bugs](../index.md)

Related: [BUG-04: countdown beeps do not follow the displayed seconds](../done/task-04-countdown-beeps-out-of-sync-and-stage-sound-missing/index.md), split from the same report.

## Goal

The sound that marks a stage change (round start, round finish) plays every time. Today it is sometimes missing. This task stays `draft` until the cause is confirmed on a device.

## Context

- **Expected:** at displayed 0, the round finish sound plays when a round ends and the round start sound when a round starts. Both are `assets/audio/3beeps.mp3`. The workout done sound plays at the end of the last round.
- **Actual (reported on a Google Pixel 9, Android; Android version not recorded):** the sound at the end of a round, and at times at the start of a round, sometimes does not play. It is intermittent. Not checked on iOS or macOS.
- **Reproduction:** a workout with preparation, round and rest longer than 3 s and 2 or more rounds; start it and listen at each stage change.
- **Code facts:**
  - `TimerViewModel._playSounds` (`lib/features/timer/presentation/timer_view_model.dart`) calls `playRoundFinishSound`, `playRoundStartSound` and `playWorkoutDoneSound` once per event.
  - A stale tick (more than 2 s since the last tick, for example after the screen was locked) skips the round finish sound on purpose and plays only the sound of the current position.
  - All sounds share one `AudioPlayer` registered in `lib/di/di.dart`. The background keep-alive uses its own `AudioPlayer` with a silent loop (`lib/features/timer/data/default_background_keep_alive.dart`).
  - `DefaultAudioManager` sets an Android audio context with `AndroidAudioFocus.gainTransientMayDuck`.
- **Suspected causes (not confirmed):**
  1. The chained countdown beeps of the old `playPreparationSound` call `stop()` or play another beep on the shared player while the stage sound starts. By the asset lengths the chain should end about 0.8 s before the stage change, so this is unlikely. [BUG-04](../done/task-04-countdown-beeps-out-of-sync-and-stage-sound-missing/index.md) removes the chain anyway.
  2. Ticks are late with the screen off, so a stale tick skips the round finish sound by design.
  3. Android audio focus or player state between the shared player and the keep-alive player drops a `play` call.

## Next step (before this task can be `ready`)

1. Wait until BUG-04 is merged, then repeat the reproduction on the Pixel 9, once with the screen on and once with it off.
2. If no stage sound is missing in about 10 stage changes each way, close this bug as fixed by BUG-04.
3. If a sound is still missing, capture the logs of a run (`fvm flutter run` on the phone, plus `adb logcat` filtered on `flutter` and `audioplayers`). Note whether the screen was on or off and which stage change lost its sound. The planner then confirms the cause and writes the fix here.

## Decisions

- Split from the original BUG-04 because the cause needs device evidence, while the beep timing fix did not (user, during planning).

## Out of scope

- The countdown beep timing (BUG-04).
- New sounds, settings or volume.

## Files and tests

To be decided once the cause is confirmed.

## Acceptance

- [ ] When a workout with 2 or more rounds runs on the Pixel 9 with the screen on and with the screen off, then every round start and round finish sound plays. Check: manual run on the device, recorded in `notes.md`, plus a unit test for the confirmed cause.
