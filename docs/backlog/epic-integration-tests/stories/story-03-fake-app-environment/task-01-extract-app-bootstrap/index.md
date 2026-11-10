---
id: INT-03-01
status: draft
type: feat
depends-on: []
---

# Extract app start-up

Story: [Fake app environment](../index.md)

Epic: [Integration tests](../../../index.md)

## Goal

A test can start the app without Firebase and with its own registered dependencies, while the production `main()` stays the same in behavior.

## Scope

- Split `main()` so Firebase setup and the dependency registration are separate steps from `runApp`, and a test can call `runApp(MyApp())` after registering fakes in `getIt`.
- Make dependency registration replaceable for tests (for example, by resetting `getIt` and registering fakes), without adding test code paths to production logic.
- Excludes: the fakes (Task 3.2) and any new production feature.

## Dependencies

[Story 1](../../story-01-run-locally/index.md).

## Acceptance criteria

- Production start-up behaves exactly as before.
- A test can start `MyApp` with a fake user and without Firebase being initialized.
- `test/architecture/layer_boundaries_test.dart` and `test/di/di_test.dart` still pass.

## Validation

`fvm flutter analyze` and `fvm flutter test`, plus a manual start of the app. The final proof is the first flow in Story 4.

## Implementation context

Follow the repository skill [skill-integration-tests](../../../../../../.agents/skills/skill-integration-tests/SKILL.md) for the conventions (layout, fakes, running, flow rules). It describes the target setup, so check which files exist first.

`lib/main.dart`, `lib/di/di.dart` and `lib/navigation.dart`. Pages call `getIt<T>()` when they create their ViewModel, so fakes registered before `runApp` are picked up. The router in `navigation.dart` is a static `GoRouter`, so check that its state is reset between tests.
