---
id: INT-04-02
status: draft
type: feat
depends-on: [INT-04-01]
---

# Timer from a template

Story: [Smoke flows](../index.md)

Epic: [Integration tests](../../../index.md)

## Goal

A flow that picks a built-in workout template and starts a timer with its values.

## Scope

- Open the templates screen from setup, pick a template, check that the setup shows it, and start the timer.
- Confirm the exact steps against the current screens (see [test/snapshots/README.md](../../../../../../test/snapshots/README.md)).
- Excludes: every template's values, and finishing the timer (covered by Task 4.1).

## Dependencies

[Task 4.1](../task-01-timer-from-setup/index.md), for the working helper and the flow structure.

## Acceptance criteria

- The flow passes on Android through the run script.
- The timer shows the picked template's name or values before and after starting.

## Validation

Run through the script. Refresh goldens only if a captured screen changes.

## Implementation context

Follow the repository skill [skill-integration-tests](../../../../../../.agents/skills/skill-integration-tests/SKILL.md) for the conventions (layout, fakes, running, flow rules). It describes the target setup, so check which files exist first.

`lib/features/templates/`, and the `/templates` route in `lib/navigation.dart`.
