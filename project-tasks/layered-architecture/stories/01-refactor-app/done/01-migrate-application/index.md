---
id: ARCH-01-01
status: done
type: feat
depends-on: [ARCH-01-02]
---

# Migrate the existing application

Story: [Refactor the application into layers](../../index.md)

Epic: [Layered application architecture](../../../../index.md)

## Goal

Apply the agreed feature-first layer separation to the entire app in one coordinated, behavior-preserving change.

## Scope

Inventory every feature and shared concern in the implementation checkout, then reorganize its domain models and contracts, data implementations, presentation code, navigation, dependency setup, and affected tests according to the [epic decisions](../../../../index.md). Replace platform-specific types in domain-facing contracts with appropriate app-owned representations. Keep persisted formats and existing behavior compatible. Do not implement absent features or unrelated product changes.

## Dependencies

None. Coordinate with [architecture guidance and guardrails](../02-document-and-protect-boundaries/index.md) in the same delivery. Do not assume the unfinished statistics branch has been merged; include statistics if present in the implementation checkout.

## Acceptance criteria

- Every existing feature and shared concern has a clear home and follows the agreed dependency direction, with platform integrations confined to appropriate data or composition code.
- Feature-specific pages, ViewModels, and states are organized in presentation; shared UI remains appropriately shared. No empty layers or pass-through use cases are required.
- Authentication, navigation, timer behavior, appearance, and stored settings and other existing data work as before, including across app restart and upgrade where applicable.
- Tests and imports follow the new structure; any relevant behavior previously coupled to a platform type remains covered.

## Validation

Run focused tests for affected behavior, full analysis and the full test suite. Check the existing [snapshot flow index](../../../../../../test/snapshots/README.md) and [snapshot test](../../../../../../test/snapshots/ui_snapshots_test.dart); verify unchanged goldens, updating captures and the index only if an agreed visible or navigation change requires it. Verify relevant Android and iOS builds and platform integration tests when affected, reporting environment limitations. Check persisted-data compatibility and the current checkout's affected integrations.

## Implementation context

Inspect `lib/features/`, `lib/presentation/`, `lib/di/`, navigation, and their tests before planning. Existing snapshots capture login, setup, account, templates, statistics, timer styles and timer states; live timer effects and interactive authentication have coverage limits documented in the snapshot index. Follow the applicable orchestration workflow.

## Completion evidence

- Every feature now follows `lib/features/<name>/{domain,data,presentation}` (only the layers it needs); shared UI is in `lib/shared/presentation/` and pure helpers in `lib/core/`.
- `UserRepository` returns the app-owned `AppUser`; `BackgroundKeepAlive` no longer uses a Flutter type; the three `part` libraries are normal imports; single-type helpers are extensions under per-layer `extensions/` folders.
- `fvm flutter analyze` reports no issues and the full suite passes (275 tests) with the UI goldens unchanged. `pubspec.yaml`, `android/` and `ios/` are unchanged, so no native build was needed. Stored data (SharedPreferences keys, `activity.db` schema) and the DI order were checked unchanged.
- One review round: no Critical findings; the two General findings were fixed.
