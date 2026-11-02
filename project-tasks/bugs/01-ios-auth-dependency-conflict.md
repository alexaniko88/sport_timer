# BUG-01: iOS build fails to resolve authentication dependencies

Category: [Bugs](index.md)

Status: Ready for diagnosis and planning.

## Problem and impact

An unsigned iOS debug build fails during Swift Package Manager dependency resolution, before compilation. This blocks iOS builds and native validation, including the iOS checks for the [statistics database foundation](../statistics/stories/01-record-activity/done/02-add-database-foundation.md).

**Expected:** The iOS dependencies resolve and the app builds; Google sign-in and sign-out remain functional.

**Actual:** Resolution reports incompatible `gtm-session-fetcher` requirements from Firebase iOS SDK and Google Sign-In iOS.

## Reproduction and evidence

1. Use the repository's pinned Flutter SDK and resolve dependencies with `fvm flutter pub get`.
2. Run `fvm flutter build ios --debug --no-codesign` on a configured macOS/Xcode environment.
3. Observe the Swift Package Manager dependency resolution failure.

Observed on branch `feat/database-foundation` during database foundation validation. The checkout pinned `firebase_core 5.1.0`, `firebase_auth 7.0.1`, and `google_sign_in 7.2.0`; those pins and the Swift Package Manager setting also existed on `master`. The installed Firebase plugin required Firebase iOS SDK 13.1.1, which requires `gtm-session-fetcher` 4..<6; the installed Google Sign-In adapter selected a native 9.x range requiring 3.3..<4. The conflict was observed before compilation. A separate build of `master` was not run, so reproduce on the implementation checkout before treating its baseline as confirmed.

References: [Firebase iOS SDK 13.1.1 manifest](https://raw.githubusercontent.com/firebase/firebase-ios-sdk/13.1.1/Package.swift) and [Google Sign-In iOS 9.1.0 manifest](https://raw.githubusercontent.com/google/GoogleSignIn-iOS/9.1.0/Package.swift). Recheck current released versions and their compatibility when planning.

## Scope and dependencies

Diagnose the actual checkout and choose a supported, compatible dependency configuration. Any plugin version changes, downgrade, or adapter change require an explicit plan and approval; no particular fix is assumed here. Preserve existing authentication behavior and avoid unrelated dependency changes. No prerequisite task is required for diagnosis.

## Acceptance criteria

- The native iOS dependencies resolve and an unsigned debug iOS build succeeds from the implementation checkout.
- Google sign-in, sign-out, and existing authentication error behavior remain functional; document any environment-dependent manual verification.
- Android authentication and builds remain compatible, and project dependency versions remain explicitly pinned as required.
- The dependency choice and any remaining limitations are documented with evidence. The statistics task's native SQLite checks are run separately when that task resumes.

## Validation

Reproduce the failure or document why the current checkout differs; verify compatible released package constraints using primary sources. Run package resolution, relevant authentication tests, full analysis and tests, an unsigned iOS debug build, and an Android debug build. Exercise sign-in and sign-out on supported devices or simulators where feasible and report any unverified behavior. Follow the applicable orchestration workflow before editing code.
