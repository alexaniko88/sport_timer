---
id: IMP-06
status: ready
type: improve
complexity: 3
depends-on: []
touches:
  - android/app/src/main/res/drawable/ic_stat_sport_timer.xml
  - android/app/src/main/res/raw/keep.xml
  - lib/features/timer/data/default_background_keep_alive.dart
  - test/features/timer/data/default_background_keep_alive_test.dart
skills: []
---

# Add a barbell notification icon on Android

Improvements: [Improvements](../index.md)

Related: [Adaptive launcher icon for iOS and Android (IMP-07)](../task-07-adaptive-launcher-icon/index.md).

## Goal

Give the Android workout notification its own small icon: a white barbell on a transparent background. Today the notification borrows the launcher icon, and Adaptive launcher icon for iOS and Android (IMP-07) turns the launcher icon into an opaque red square, which Android would draw as a plain white square in the status bar. This task must merge before IMP-07.

## Context

- Current behavior: `lib/features/timer/data/default_background_keep_alive.dart` passes `const AudioServiceConfig(androidNotificationChannelId: 'sport_timer.workout', androidNotificationChannelName: 'Workout', androidStopForegroundOnPause: false)` (with a comment above the last argument) to `AudioService.init` in `_createHandler()`. It does not set `androidNotificationIcon`, so `audio_service` 0.18.19 uses its default `'mipmap/ic_launcher'`.
- Android draws a notification small icon from its alpha channel only (every visible pixel becomes white). Today's launcher PNG is a black barbell on transparent, so the notification shows a barbell. After IMP-07 the launcher icon is opaque, so it would show a filled square.
- The file is in the `timer` feature, `data` layer, which may use platform packages (`audio_service`). There is no test for `DefaultBackgroundKeepAlive` yet and no fake for `AudioService.init`.
- `android/app/src/main/res/` has `drawable/` (only `launch_background.xml`) and no `raw/` folder yet.
- iOS is not affected: `audio_service` uses no notification icon there.
- The barbell is the drawing in the `BARBELL` constant (100 × 100 canvas) of IMP-07's approved [mockup.html](../task-07-adaptive-launcher-icon/mockup.html). This task needs no mockup of its own: the notification icon is a single-color silhouette of that drawing.
- File-reading tests in this repo follow `test/architecture/ai_setup_test.dart`: `dart:io` reads a repository-relative path.

## Contract

- `android/app/src/main/res/drawable/ic_stat_sport_timer.xml` — new here: an Android vector drawable, resource name `ic_stat_sport_timer`. Content is fixed, see Decisions.
- `android/app/src/main/res/raw/keep.xml` — new here: tells the release build's resource shrinker to keep `ic_stat_sport_timer`. `audio_service` looks the icon up by name at runtime, so no code references it and shrinking would otherwise remove it. The `audio_service` 0.18.19 README asks for this file when custom notification icons are used. Content is fixed, see Decisions.
- `DefaultBackgroundKeepAlive.notificationConfig` — new here: `@visibleForTesting static const AudioServiceConfig notificationConfig = AudioServiceConfig(...)`, holding today's three arguments (and their comment) plus `androidNotificationIcon: 'drawable/ic_stat_sport_timer'`. `_createHandler()` passes `config: notificationConfig`. `@visibleForTesting` comes from the existing `package:flutter/foundation.dart` import. It is a static field, so it goes with the fields at the top of the class.
- `AudioServiceConfig.androidNotificationIcon` — existing `audio_service` parameter, a `String` in the format `'<resource type>/<name>'`.
- Consumer: the Android foreground-service notification that `audio_service` shows while a workout runs. No Dart code reads the drawable.

## Decisions

- Add a dedicated notification icon instead of letting the notification use the new red launcher icon. Accepted recommendation: Android would show the opaque launcher icon as a white square.
- Use a vector drawable, not PNGs, so the task is plain text and needs no image tools.
- Keep the drawable in release builds with a `raw/keep.xml` that names only this drawable (not the README's `@drawable/*`), so it does not change what is kept for the rest of the app.
- Name it `ic_stat_sport_timer` (Android's `ic_stat_` prefix for status bar icons), not `ic_notification`, so it never collides with `icons_launcher`'s own `ic_notification.png` output.
- The config becomes a `@visibleForTesting` static constant so a unit test can read the icon name; the values passed to `AudioService.init` do not change otherwise.
- The drawable content is fixed. Create it exactly as below. The path is the mockup's barbell (two rounded plates, the bar, two posts and the crossbar). The group scales it by 1.3 around its center so it fills most of the 24 dp icon, and stroke width 6 gives lines of about 2 dp, the usual weight for status bar icons. The path has no `fillColor`, so it draws strokes only.

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="100"
    android:viewportHeight="100">
    <group
        android:pivotX="50"
        android:pivotY="51"
        android:scaleX="1.3"
        android:scaleY="1.3">
        <path
            android:pathData="M20.5,30 H24.5 A3.5,3.5 0 0 1 28,33.5 V48.5 A3.5,3.5 0 0 1 24.5,52 H20.5 A3.5,3.5 0 0 1 17,48.5 V33.5 A3.5,3.5 0 0 1 20.5,30 Z M75.5,30 H79.5 A3.5,3.5 0 0 1 83,33.5 V48.5 A3.5,3.5 0 0 1 79.5,52 H75.5 A3.5,3.5 0 0 1 72,48.5 V33.5 A3.5,3.5 0 0 1 75.5,30 Z M28,41 H72 M41,41 V72 M59,41 V72 M41,57 H59"
            android:strokeColor="#FFFFFFFF"
            android:strokeWidth="6"
            android:strokeLineCap="round"
            android:strokeLineJoin="round" />
    </group>
</vector>
```

- The keep file content is fixed. Create it exactly as below:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@drawable/ic_stat_sport_timer" />
```

## Out of scope

- The launcher icon itself (IMP-07).
- Notification color (`notificationColor`), text, actions or channel settings.
- `icons_launcher`'s `notification_image` option: not used.
- Building the APK. The Android build that compiles the drawable runs later in IMP-07's full `fvm dart tool/agent_check.dart` (with builds); the runner does not run it.

## Files and tests

- New: the two resource files in Contract and `test/features/timer/data/default_background_keep_alive_test.dart`.
- `test/features/timer/data/default_background_keep_alive_test.dart` (unit tests): it reads `DefaultBackgroundKeepAlive.notificationConfig`, and it reads the two resource files with `dart:io` at their repository-relative paths, as `test/architecture/ai_setup_test.dart` does. The resource checks live in this file because it mirrors the Dart file that names the drawable, so `agent_check` runs them when that file changes. No fake for `AudioService.init` is needed.

## Acceptance

- [ ] When the workout notification config is built, then `androidNotificationIcon` is `'drawable/ic_stat_sport_timer'`. Check: `test/features/timer/data/default_background_keep_alive_test.dart` "uses the barbell drawable as the notification icon".
- [ ] When the workout notification config is built, then the channel id is `'sport_timer.workout'`, the channel name is `'Workout'` and `androidStopForegroundOnPause` is `false`, as before. Check: `test/features/timer/data/default_background_keep_alive_test.dart` "keeps the workout channel and foreground settings".
- [ ] When `android/app/src/main/res/drawable/ic_stat_sport_timer.xml` is read, then it is a `<vector>` whose `android:pathData` is the barbell path in Decisions, with no `fillColor` and `#FFFFFFFF` as its only color. Check: `test/features/timer/data/default_background_keep_alive_test.dart` "the notification icon drawable draws the barbell in white strokes only".
- [ ] When `android/app/src/main/res/raw/keep.xml` is read, then it keeps `@drawable/ic_stat_sport_timer` and nothing else (no `@drawable/*`). Check: `test/features/timer/data/default_background_keep_alive_test.dart` "keep.xml keeps only the notification icon".
- [ ] When the change is checked, then format, analyze, the mirrored test and the boundary test pass. Check: `fvm dart tool/agent_check.dart --skip-build`.
