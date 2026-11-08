---
id: IMP-06
status: ready
type: improve
complexity: low
depends-on: []
touches:
  - android/app/src/main/res/drawable/ic_stat_sport_timer.xml
  - android/app/src/main/res/raw/keep.xml
  - lib/features/timer/data/default_background_keep_alive.dart
skills: []
---

# Add a barbell notification icon on Android

Improvements: [Improvements](../index.md)

Related: [IMP-07: Adaptive launcher icon](../07-adaptive-launcher-icon/index.md).
## Goal

Give the Android workout notification its own small icon: a white barbell on a transparent background. Today the notification borrows the launcher icon, and [IMP-07](../07-adaptive-launcher-icon/index.md) turns the launcher icon into an opaque red square, which Android would draw as a plain white square in the status bar. This task must merge before IMP-07.

## Context

- Current behavior: `lib/features/timer/data/default_background_keep_alive.dart` builds `const AudioServiceConfig(androidNotificationChannelId: 'sport_timer.workout', androidNotificationChannelName: 'Workout', androidStopForegroundOnPause: false)` inside `_createHandler()`. It does not set `androidNotificationIcon`, so `audio_service` 0.18.19 uses its default `'mipmap/ic_launcher'`.
- Android draws a notification small icon from its alpha channel only (every visible pixel becomes white). Today's launcher PNG is a black barbell on transparent, so the notification shows a barbell. After IMP-07 the launcher icon is opaque, so it would show a filled square.
- The file is in the `timer` feature, `data` layer, which may use platform packages (`audio_service`).
- The barbell drawing matches the approved mockup [../07-adaptive-launcher-icon/mockup.html](../07-adaptive-launcher-icon/mockup.html) (its `BARBELL` constant, 100 x 100 canvas). This task needs no mockup approval of its own: the notification icon is a single-color silhouette of that drawing.

## Contract

- `android/app/src/main/res/drawable/ic_stat_sport_timer.xml` (new here): an Android vector drawable, resource name `ic_stat_sport_timer`.
- `AudioServiceConfig.androidNotificationIcon` (existing `audio_service` parameter, type `String`, format `'<resource type>/<name>'`): set to `'drawable/ic_stat_sport_timer'` in the existing `const AudioServiceConfig(...)` in `_createHandler()`.
- `android/app/src/main/res/raw/keep.xml` (new here): tells the release build's resource shrinker to keep `ic_stat_sport_timer`. `audio_service` looks the icon up by name at runtime, so nothing in code references it and shrinking would otherwise remove it. The `audio_service` 0.18.19 README ("If you use any custom icons in notification, create the file `android/app/src/main/res/raw/keep.xml`") asks for this file.
- Consumers: the Android foreground-service notification shown by `audio_service` while a workout runs. No Dart code reads the drawable.

## Behavior

- The notification small icon in the status bar and the notification shade is the white barbell, on every Android version the app supports.
- The rest of the notification (channel id, channel name, foreground behavior while paused) does not change.
- iOS is not affected (`audio_service` uses no notification icon there).

The drawable file content is fixed. Create it exactly as below:

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

Create `android/app/src/main/res/raw/keep.xml` exactly as below. It keeps only this drawable, so it does not change what is kept for the rest of the app:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@drawable/ic_stat_sport_timer" />
```

Why these numbers: the path is the mockup's barbell (two rounded plates, the bar, two posts and the crossbar). The group scales it by 1.3 around its center so it fills most of the 24 dp status bar icon, and stroke width 6 gives lines of about 2 dp, the usual weight for status bar icons. The path has no `fillColor`, so it draws strokes only.

## Decisions

- Add a dedicated notification icon instead of letting the notification use the new red launcher icon. Accepted recommendation: Android would show the opaque launcher icon as a white square.
- Use a vector drawable, not PNGs, so the task is plain text and needs no image tools.
- Keep the drawable in release builds with a `raw/keep.xml` that names only this drawable, as the `audio_service` README asks. Planner proposal backed by the package documentation.
- Name it `ic_stat_sport_timer` (Android's `ic_stat_` prefix for status bar icons), not `ic_notification`, so it never collides with `icons_launcher`'s own `ic_notification.png` output.

## Out of scope

- The launcher icon itself ([IMP-07](../07-adaptive-launcher-icon/index.md)).
- Notification color (`notificationColor`), text, actions or channel settings.
- `icons_launcher`'s `notification_image` option: not used.

## Files and tests

- Create `android/app/src/main/res/drawable/ic_stat_sport_timer.xml` with the exact content in Behavior.
- Create `android/app/src/main/res/raw/keep.xml` with the exact content in Behavior.
- Edit `lib/features/timer/data/default_background_keep_alive.dart`: add `androidNotificationIcon: 'drawable/ic_stat_sport_timer',` to the `const AudioServiceConfig(...)`. Keep the existing comment and the other arguments.
- No new test. The change is one constant argument passed to a platform package and one resource file; a unit test would only repeat the literal. There is no existing test for `DefaultBackgroundKeepAlive`, and no fake for `AudioService.init`.
- Run: `fvm dart format lib/features/timer/data/default_background_keep_alive.dart`, `fvm flutter analyze --no-pub lib/features/timer/data/default_background_keep_alive.dart`, and `fvm dart tool/agent_check.dart --skip-build`.
- The Android build that compiles the drawable is run later by IMP-07's full `fvm dart tool/agent_check.dart` (with builds). If the user wants it earlier, they can run `fvm flutter build apk --debug` themselves; the runner does not.

## Acceptance

- [ ] When the workout notification is set up, then `AudioServiceConfig` sets `androidNotificationIcon: 'drawable/ic_stat_sport_timer'`. Check: `rg -n "androidNotificationIcon: 'drawable/ic_stat_sport_timer'" lib/features/timer/data/default_background_keep_alive.dart`.
- [ ] When `android/app/src/main/res/drawable/ic_stat_sport_timer.xml` is read, then it is a vector drawable that draws the barbell in white strokes only, with no fill and no other color, exactly as given in Behavior. Check: compare the file with the XML in Behavior, and `rg -n "fillColor" android/app/src/main/res/drawable/ic_stat_sport_timer.xml` finds nothing.
- [ ] When a release build shrinks resources, then `ic_stat_sport_timer` is kept. Check: `rg -n 'tools:keep="@drawable/ic_stat_sport_timer"' android/app/src/main/res/raw/keep.xml`.
- [ ] When the change is checked, then format, analyze and the regression tests pass. Check: `fvm dart tool/agent_check.dart --skip-build`.
