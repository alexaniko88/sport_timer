# BUG-03: Android Firebase plugins report Kotlin Gradle Plugin usage

Category: [Bugs](index.md)

Status: Ready for diagnosis and planning.

## Problem and impact

The user reports that running the app on a physical phone repeatedly prints a Flutter warning that `firebase_auth` and `firebase_core` apply the Kotlin Gradle Plugin (KGP). The warning says future Flutter versions will fail to build with plugins that apply KGP. This is a build-time compatibility warning; a current build failure has not been reported.

**Expected:** The Android app builds and runs without this plugin KGP warning, using a configuration compatible with Flutter's built-in Kotlin migration.

**Actual:** The warning names both Firebase plugins when the app is run on the user's phone.

## Reproduction and environment

1. Resolve dependencies with `fvm flutter pub get`.
2. Connect an Android phone and run `fvm flutter run` using the repository's pinned SDK.
3. Check the build output for the warning naming `firebase_auth` and `firebase_core`.

The checkout pins Flutter 3.47.7, `firebase_core` 5.1.0 and `firebase_auth` 7.0.1. Android uses AGP 9.1.0 and declares Kotlin 2.4.0. `android/gradle.properties` sets `android.builtInKotlin=false` and `android.newDsl=false`. The phone model, Android version and exact run command are unknown. The report has not been independently reproduced on a device.

## Investigation context

Flutter describes the disabled built-in Kotlin flag as a temporary compatibility setting and requires migration of the app and its plugins before enabling built-in Kotlin. See the [Flutter migration overview](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/) and [app developer guide](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers). The app module does not explicitly apply `kotlin-android`, though `android/settings.gradle` declares the plugin with `apply false`; determine the actual plugin application path before changing configuration.

On 3 November 2026, the pinned versions matched the latest releases shown in the [Core changelog](https://pub.dev/packages/firebase_core/changelog) and [Auth changelog](https://pub.dev/packages/firebase_auth/changelog). This alone does not establish built-in Kotlin compatibility or a fix. Recheck releases, plugin build scripts and upstream issues during diagnosis. The existing [iOS authentication dependency conflict](01-ios-auth-dependency-conflict.md) may constrain Firebase dependency changes.

## Scope and dependencies

Diagnose the warning and implement a supported migration or dependency fix when available. Preserve Firebase initialization, authentication and platform compatibility; avoid suppressing the warning without resolving its cause. If upstream support prevents a fix, document the blocker and relevant existing issue or prepare a specific upstream report for the user to submit. Do not assume a plugin upgrade or flag change is sufficient. There is no prerequisite for diagnosis; coordinate any dependency changes with BUG-01.

## Acceptance criteria

- An Android debug build and physical-device run complete without the reported Firebase KGP warning, and the chosen configuration supports built-in Kotlin without relying on the legacy KGP compatibility flag.
- Firebase initialization and Google sign-in and sign-out continue to work on Android; relevant authentication error behavior remains intact.
- Dependency changes remain pinned and their effects on other supported platforms, including the existing iOS conflict, are assessed and reported.
- If a supported fix is unavailable, record reproducible evidence, the upstream blocker and the next actionable step; keep the bug open until the warning is resolved and verified.

## Validation

Reproduce or explain any difference on the implementation checkout. Check current official Flutter and FlutterFire guidance and the resolved plugin build scripts. Run dependency resolution, relevant authentication tests, analysis and the full test suite, plus an Android debug build and a physical-device run. Exercise authentication on the device where feasible. Validate other affected platform builds when dependencies change and report any unavailable checks. Follow the applicable orchestration workflow before implementation.
