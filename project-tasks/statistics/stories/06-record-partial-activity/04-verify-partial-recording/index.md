---
id: STAT-06-04
status: draft
type: feat
depends-on: [STAT-06-01, STAT-06-02, STAT-06-03]
---

# Verify partial recording end to end

Story: [Record partial activity](../index.md)

Epic: [Statistics](../../../index.md)

## Goal

Confirm across the whole app that partial activity reaches the Statistics screens correctly for normal exits and after a forced close.

## Scope

- Cross-ticket checks only. Basic correctness is already covered by each task's own tests.
- Excluded: new features or UI changes.

## Dependencies

[Task 6.1](../01-count-partial-progress/index.md), [Task 6.2](../02-save-on-leaving-timer/index.md), [Task 6.3](../03-checkpoint-and-recover/index.md).

## Acceptance criteria

- Starting a workout, leaving mid-round, and opening Statistics shows the partial seconds and the right round count (5-second rule) in the daily list and day details.
- Leaving a finished workout shows the same totals as before this story, with no duplicates.
- A workout killed mid-round appears in Statistics after reopening the app, up to the last checkpoint.
- Existing history from before the upgrade shows unchanged totals.

## Validation

Extend the integration tests (see the [session-in-statistics smoke flow](../../../../integration-tests/stories/04-smoke-flows/03-session-in-statistics/index.md) if available in the checkout) for the leave-mid-round flow. Record a manual Android kill-and-reopen check. Statistics UI does not change, so goldens should not change. If they do, investigate before refreshing them.

## Implementation context

`integration_test/` and the `skill-integration-tests` skill for the fake app environment and the run script.
