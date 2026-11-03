# TASK 4.3: Finished session in statistics

Story: [Smoke flows](index.md)

Epic: [Integration tests](../../index.md)

Status: Blocked by [Task 4.1](01-timer-from-setup.md).

## Goal

A flow that finishes a timer and then sees that day's activity in the Statistics tab.

## Scope

- Run a short timer to the end with the fake environment, open Statistics, and check that today's totals show the finished work.
- Use the real SQLite repository with a throwaway database, as the existing data tests do, so recording and reading are both exercised.
- Confirm the exact steps against the current screens (see [test/snapshots/README.md](../../../../test/snapshots/README.md)).
- Excludes: charts, calendar and day details, which belong to the [statistics epic](../../../statistics/index.md).

## Dependencies

[Task 4.1](01-timer-from-setup.md).

## Acceptance criteria

- After a finished session, Statistics shows an entry for today with non-zero totals.
- A fresh test run with clean data shows no entry.
- The flow passes on Android through the run script.

## Validation

Run through the script. If the statistics screen changes later, this flow should be rechecked together with its goldens.

## Implementation context

Follow the repository skill [skill-integration-tests](../../../../.agents/skills/skill-integration-tests/SKILL.md) for the conventions (layout, fakes, running, flow rules). It describes the target setup, so check which files exist first.

`lib/features/statistics/` (domain, data and presentation) and `lib/features/timer/data/default_timer_activity_recorder.dart`. The existing `integration_test/timer_activity_recording_test.dart` shows how recording is wired against a real database.
