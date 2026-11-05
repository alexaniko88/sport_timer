# BUG-04: Countdown beeps are out of sync and the stage sound is sometimes missing

[Bugs](index.md)

Status: Ready for diagnosis. The fix needs an agreed diagnosis and plan before code changes.

## Problem

At the end of a stage, the timer plays three countdown beeps followed by a final sound. The beeps do not line up with the seconds shown on screen, and the final sound that marks the end of a round sometimes does not play at all. The same final sound is also missing at times when a round starts.

## Expected behavior

- During the last 3 seconds of a stage, one beep plays on each displayed second (3, 2, 1), in time with the countdown on screen.
- When the stage reaches 0, the stage sound always plays: the round finish sound when a round ends, the round start sound when a round starts.
- The workout done sound still plays at the end of the last round.

## Actual behavior (reported)

- The three countdown beeps are not aligned with the displayed seconds.
- The final sound at the end of a round sometimes does not play.
- The sound at the start of a round sometimes does not play.

## Reproduction

1. Set a workout with a preparation, round and rest time longer than 3 seconds each, and 2 or more rounds.
2. Start the timer and listen to the last 3 seconds of the preparation, a round and a rest.
3. Compare each beep with the number on screen, and check that a sound plays when the stage changes.

The issue is intermittent for the final sound.

## Environment

- Observed on a physical Google Pixel 9 (Android). The Android version is not recorded.
- Not yet checked on iOS or macOS.

## Impact

The user relies on the sounds to know when to start and stop working without looking at the screen. Beeps that run ahead of the clock and a missing start or stop sound make the timer unreliable during a workout.

## Observed code facts

- `TimerViewModel._playSounds` (`lib/features/timer/presentation/timer_view_model.dart`) calls `playPreparationSound()` only once, on the tick where the stage enters its last 3 seconds. It does not ask for one beep per second.
- `DefaultAudioManager.playPreparationSound` (`lib/features/timer/data/default_audio_manager.dart`) plays the 3 beeps as a chain: each new beep starts from the `onPlayerComplete` event of the previous one, after `audioPlayer.stop()`. Each beep starts at a 200 ms offset in `beep.mp3`, which lasts about 0.86 s, so each beep plays for about 0.66 s plus the player's stop and start latency. The spacing therefore depends on the asset length and device latency, not on the timer's seconds.
- The countdown beeps, the round start and finish sounds (`3beeps.mp3`) and the workout done sound all use the same `AudioPlayer` singleton registered in `lib/di/di.dart`.
- Round start and round finish play the same asset, `3beeps.mp3`.
- The background keep-alive uses its own `AudioPlayer` (`lib/features/timer/data/default_background_keep_alive.dart`).

## Suspected causes (not confirmed)

- **Beeps out of sync:** the chained beeps follow the audio completion events instead of the timer ticks, so they drift from the displayed seconds (likely ahead of the clock on a fast device, behind it on a slow one).
- **Missing stage sound:** because all sounds share one player, the countdown chain can still be running when the stage sound starts. Its listener can then call `stop()` or play another beep on the same player, cutting off or replacing the stage sound. It can also react to the completion of the stage sound itself and play an extra beep.

These need to be confirmed during diagnosis, for example with logs of the tick time and each play call on a real device.

## Scope

- Diagnose why the countdown beeps drift and why the stage sound is sometimes lost, on the platforms where it happens.
- Fix the timing so each countdown beep follows its displayed second, and the stage sound always plays.
- Exclusions: new sounds, sound settings, volume controls, or changes to which events have a sound.

## Dependencies

None.

## Acceptance criteria

- In the last 3 seconds of each stage longer than 3 seconds, exactly one beep plays per displayed second, at the moment the number changes (within a small tolerance agreed during planning).
- The round finish, round start and workout done sounds play every time their event happens, and no countdown beep cuts them off or replaces them.
- No extra beep plays after a stage sound.
- Pause, resume and a late tick after a locked screen keep the existing rules: no stacked or stale sounds.

## Validation

- Unit tests in `test/features/timer/presentation/timer_view_model_test.dart` for the sound calls per tick (the fake `AudioManager` there records the calls).
- Tests for the audio manager behavior if its contract or sequencing changes, following the existing test conventions.
- Manual check on the Google Pixel 9 where the bug was seen, then on an iOS device, with a short workout, listening to every stage change.
- `fvm dart tool/agent_check.dart` on the changed files.

## Implementation context

- Feature `timer`: the event logic is in `presentation/timer_view_model.dart`, the playback in `data/default_audio_manager.dart`, and the contract in `domain/audio_manager.dart`.
- Any change to the `AudioManager` contract must also update the fakes in `test/features/timer/presentation/timer_view_model_test.dart`, `test/features/timer/presentation/timer_page_test.dart` and `test/snapshots/ui_snapshots_test.dart`.
