# STORY 4: Smoke flows

Epic: [Integration tests](../../index.md)

## User outcome

As the developer, I want the three most important user paths checked in the running app so that a broken main flow is caught before release.

## Scope

- Three flows in `integration_test/flows/`, each started through the fake environment:
  1. Set up a timer, run it to the end, and return to home.
  2. Start a timer from a workout template.
  3. After a finished session, see its activity in Statistics.
- Excludes: settings persistence, timer styles, login, drawer navigation, and screen details covered by existing widget and golden tests. More flows can be added later.

## Acceptance criteria

- Each flow passes on Android through the run script and the aggregator.
- The whole smoke suite runs in about a minute on the emulator, on top of the one-time build. Treat this as a target to confirm, not a measured fact.
- Failures point to the step that broke.

## Tasks

1. [Timer from setup](task-01-timer-from-setup/index.md).
2. [Timer from a template](task-02-timer-from-template/index.md).
3. [Finished session in statistics](task-03-session-in-statistics/index.md).

## Dependencies and open decisions

Needs the fake environment and the aggregator. The final list of flows and their exact steps are confirmed in Task 4.1 from the current screens. For visual and navigation context see [test/snapshots/README.md](../../../../../test/snapshots/README.md) and the images in `test/snapshots/goldens/`; check the implementation checkout when work starts, because screens may have changed.
