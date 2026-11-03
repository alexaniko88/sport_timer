# TASK 4.1: Timer from setup

Story: [Smoke flows](index.md)

Epic: [Integration tests](../../index.md)

Status: Blocked by [Story 2](../02-arrange-existing-tests/index.md) and [Story 3](../03-fake-app-environment/index.md).

## Goal

A flow that sets up a short timer on the setup tab, starts it, lets it finish, and returns to home. It also proves the fake environment from Story 3 works end to end.

## Scope

- Confirm the exact steps against the current screens (see the navigation flow in [test/snapshots/README.md](../../../../test/snapshots/README.md)).
- Cover: start from home, run through preparation, rounds and rest, reach the finished state, and go back.
- Avoid `pumpAndSettle` on the running timer screen; use explicit pumps or the fake clock.
- Excludes: timer styles, sounds, pause details.

## Dependencies

[Story 2](../02-arrange-existing-tests/index.md) and [Story 3](../03-fake-app-environment/index.md).

## Acceptance criteria

- The flow passes on Android through the run script and finishes in seconds of real time.
- The test fails if the timer never finishes or the app does not return to home.

## Validation

Run through the script on `sport-timer-emulator` and on a real device if one is available. No snapshot change is expected; if a screen changes, refresh the goldens per `CLAUDE.md`.

## Implementation context

Follow the repository skill [skill-integration-tests](../../../../.agents/skills/skill-integration-tests/SKILL.md) for the conventions (layout, fakes, running, flow rules). It describes the target setup, so check which files exist first.

Routes and pages in `lib/navigation.dart` and `lib/features/timer/presentation/`. Tapping widgets by text works, but prefer keys or semantics labels where the text is localized.
