---
id: INT-02-01
status: draft
type: feat
depends-on: []
---

# Move the tests and add the aggregator

Story: [Arrange the existing integration tests](../index.md)

Epic: [Integration tests](../../../index.md)

## Goal

The four existing SQLite tests live in `integration_test/data/` and run through one aggregator file.

## Scope

- Move `activity_access_test.dart`, `activity_database_test.dart`, `activity_repository_test.dart` and `timer_activity_recording_test.dart` into `integration_test/data/`.
- Add `integration_test/all_tests.dart` that initializes the binding once and calls each suite's `main()`.
- Update the run script to target the aggregator.
- Check that each suite still works when called together (each creates its own throwaway database file, so no clash is expected; confirm).
- Excludes: changing test logic.

## Dependencies

[Story 1](../../01-run-locally/index.md).

## Acceptance criteria

- All existing tests pass through the aggregator on Android.
- Only one build and install happens per run.
- The old file locations no longer exist and nothing references them.

## Validation

Run the script and compare the test count and results with a run before the move. Run `fvm flutter analyze`.

## Implementation context

Follow the repository skill [skill-integration-tests](../../../../../.agents/skills/skill-integration-tests/SKILL.md) for the conventions (layout, fakes, running, flow rules). It describes the target setup, so check which files exist first.

Each existing file calls `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` in its own `main()`; the aggregator must not break that. They were added in the statistics epic: [Task 1.5](../../../../statistics/stories/01-record-activity/done/05-verify-recording/index.md) records their last Android run.
