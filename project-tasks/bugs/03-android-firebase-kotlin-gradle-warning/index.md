---
id: BUG-03
status: draft
type: fix
complexity: medium
depends-on: [BUG-01]
touches:
  - android/gradle.properties
  - pubspec.yaml
  - CLAUDE.md
skills: []
---

# Android Firebase plugins report Kotlin Gradle Plugin usage

Category: [Bugs](../index.md)

## Goal

Android builds without the warning that `firebase_auth` and `firebase_core` apply the Kotlin Gradle Plugin (KGP), on built-in Kotlin. **Blocked upstream:** this task stays `draft` until FlutterFire removes the KGP line from its plugins.

## Context

- **Warning (reproduced on `master` on 5 November 2026 with `fvm flutter build apk --debug`, Flutter 3.47.7, AGP 9.1.0):** `Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): firebase_auth, firebase_core. Future versions of Flutter will fail to build if your app uses plugins that apply KGP.` The build itself succeeds.
- `android/gradle.properties` sets `android.builtInKotlin=false` and `android.newDsl=false` (both added by the Flutter migrator). `CLAUDE.md` ("Dependencies and Android build") says the flag must stay until the Firebase plugins migrate.
- **Cause (confirmed):**
  - The FlutterFire plugins apply KGP only when the app opts out of built-in Kotlin with `android.builtInKotlin=false`. Their build files say: "AGP 9+ has built-in Kotlin support unless Flutter opts out via android.builtInKotlin=false" ([FlutterFire discussion #18756](https://github.com/firebase/flutterfire/discussions/18756)).
  - Flutter finds KGP use by searching the plugins' `build.gradle` text, so it warns even when that line is skipped.
- **Experiment (5 November 2026):** with `firebase_core` 4.15.0, `firebase_auth` 6.7.0 (the [BUG-01](../01-ios-auth-dependency-conflict/index.md) versions) and `android.builtInKotlin=true`, `fvm flutter build apk --debug` succeeded, but the warning was still printed. So the app side can migrate today, but the warning only goes away when FlutterFire removes the line ([FlutterFire issue #18304, "Migrates to built-in Kotlin"](https://github.com/firebase/flutterfire/issues/18304), open).
- Not tested yet: the app running on a phone with built-in Kotlin on (Firebase initialization, Google sign-in and sign-out).

## Next step (before this task can be `ready`)

Watch FlutterFire issue #18304 and the [core](https://pub.dev/packages/firebase_core/changelog) and [auth](https://pub.dev/packages/firebase_auth/changelog) changelogs. When a release removes the KGP line and fits the pins chosen in BUG-01 (or a `google_sign_in_ios` release lifts the BUG-01 limit), plan the task:

- the plugin versions;
- set `android.builtInKotlin=true` (or remove the line);
- update the `CLAUDE.md` line;
- confirm on a phone.

## Decisions

- Do nothing until upstream migrates. Keep `android.builtInKotlin=false` for now, even though `true` builds today (user, during planning).

## Out of scope

- Hiding the warning without removing its cause.
- `android.newDsl` (a separate compatibility flag).
- The iOS dependency conflict (BUG-01).

## Files and tests

To be decided when the upstream release exists. Expected: `pubspec.yaml`, `android/gradle.properties` and `CLAUDE.md`.

## Acceptance

- [ ] When the Android app is built, then the KGP warning naming `firebase_auth` and `firebase_core` is not printed and the build succeeds with built-in Kotlin. Check: `fvm flutter build apk --debug`.
- [ ] When the app runs on an Android phone, then Firebase starts and Google sign-in and sign-out work. Check: manual run with `fvm flutter run`, recorded in `notes.md`.
