---
id: BUG-03
status: ready
type: fix
complexity: 2
depends-on: []
touches:
  - pubspec.yaml
  - android/gradle.properties
  - ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved
  - CLAUDE.md
skills: []
---

# Android Firebase plugins report Kotlin Gradle Plugin usage

Category: [Bugs](../index.md)

## Goal

Android builds on built-in Kotlin, without the warning that `firebase_auth` and `firebase_core` apply the Kotlin Gradle Plugin (KGP). The fix moves both plugins to the releases that dropped KGP and turns built-in Kotlin on.

## Context

- **Actual:** `fvm flutter build apk --debug` prints `Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): firebase_auth, firebase_core`. The build succeeds.
- **Cause (confirmed):** `firebase_core` 5.1.0 and `firebase_auth` 7.0.1 have `apply plugin: 'kotlin-android'` in `android/build.gradle`, and Flutter warns when it finds that line. `firebase_core` 5.2.0 and `firebase_auth` 7.1.0 removed it (changelogs: "migrate plugins to built-in Kotlin on Flutter 3.44"). The project runs Flutter 3.47.7.
- **Proof (scratch worktree of `master`, 24 November 2026):** with the two pins bumped, `fvm flutter build apk --debug` built with no KGP warning, both with `android.builtInKotlin=false` and `true`. `fvm flutter build ios --debug --no-codesign` also built, so the iOS conflict of [BUG-01](../done/task-01-ios-auth-dependency-conflict/index.md) does not come back. That iOS build changed both `Package.resolved` files exactly as in the Contract.
- `android/gradle.properties` line 5 is `android.builtInKotlin=false`, under the comment `# This builtInKotlin flag was added automatically by Flutter migrator`.
- `CLAUDE.md`, section "Dependencies and Android build", has the line that starts `- The Android build uses Gradle 9.3.1, AGP 9.1.0 and Kotlin 2.4.0.`

## Contract

Exact edits, all existing files. Change nothing else in them.

- `pubspec.yaml`: `firebase_core: 5.1.0` becomes `firebase_core: 5.2.0`, and `firebase_auth: 7.0.1` becomes `firebase_auth: 7.1.0`. Keep the exact pins (no `^`).
- `android/gradle.properties`: `android.builtInKotlin=false` becomes `android.builtInKotlin=true`. Keep the comment above it.
- Both `Package.resolved` files (`ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/` and `ios/Runner.xcworkspace/xcshareddata/swiftpm/`), the same edit in each. In the pin with this `identity`, replace `revision` and `version`:

  | `identity` | Old `revision` | Old `version` | New `revision` | New `version` |
  | --- | --- | --- | --- | --- |
  | `app-check` | `c7eb17e5545f36e43dc50e70da09c2e999714e16` | `12.0.0` | `b7c71458b70284cc0f5a87103f66f0b1d98b1873` | `12.1.0` |
  | `firebase-ios-sdk` | `dc6dfd442b1f3ec215ed62b8beb2623ffab010d6` | `13.1.1` | `efad2b784dfae43404dc1fcfdf272981b235e71f` | `13.2.0` |
  | `google-ads-on-device-conversion-ios-sdk` | `0208e2681ec81f8a9c81084696f60fcce26cb7ee` | `3.7.0` | `665eb0eab22172138bf5b3ce6d75e62b82c2ab59` | `3.8.0` |
  | `googleappmeasurement` | `1a3546fb9189292e9d64db9e72add7a286c0f85a` | `13.0.1` | `abc3a85c786aa7077d93ab7f6709dfc9e1b6d557` | `13.2.0` |

  If an old value in the table does not match the file, stop and report it instead of editing.
- `CLAUDE.md`: replace the whole line that starts `- The Android build uses Gradle 9.3.1, AGP 9.1.0 and Kotlin 2.4.0.` with:

  ```markdown
  - The Android build uses Gradle 9.3.1, AGP 9.1.0 and Kotlin 2.4.0, on built-in Kotlin (`android.builtInKotlin=true` in `android/gradle.properties`). Since `firebase_core` 5.2.0 and `firebase_auth` 7.1.0, no plugin applies the Kotlin Gradle plugin, so the build prints no "plugins that apply KGP" warning.
  ```

## Decisions

- Keep the `android.builtInKotlin` line and set it to `true`; do not delete it. The `true` build is the verified one.
- Edit the `Package.resolved` files by hand with the values above, because runners cannot run an iOS build. They are the values the real iOS build wrote.
- The Android build (no KGP warning) and a phone run (Firebase starts, Google sign-in and sign-out work) are checked by the user after merge. The runner's check skips builds.

## Out of scope

- `android.newDsl` (a separate compatibility flag).
- `google_sign_in` and every other package.
- Dart code. If analyze or a test fails because of the bump, stop and report it instead of changing app code.

## Files and tests

- No new files and no new tests: no Dart code changes. The existing suite must still pass.

## Acceptance

- [ ] When the bumped pins, the flag, the `Package.resolved` edits and the `CLAUDE.md` line are in place, then format, analyze, the tests and the AI setup test pass. Check: `fvm dart tool/agent_check.dart --skip-build`.
