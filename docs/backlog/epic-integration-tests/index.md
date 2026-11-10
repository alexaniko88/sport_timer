---
abbr: INT
---

# EPIC: Integration tests

## Goal

Give the app a fast, repeatable integration test process that runs locally on Android. A few smoke flows prove that the most important user paths work in the real app, with a fake environment so nothing waits for real workout time or needs a Google account.

## Agreed behavior and boundaries

- First version covers three smoke flows only: run a timer from setup, run a timer from a template, and see a finished session in statistics. Details of each screen stay with the unit, widget and golden tests.
- Platform: Android only. An emulator named `sport-timer-emulator` is the default, and a connected real device is also allowed and wins over the emulator. iOS and macOS are out of scope; iOS builds are blocked by [BUG-01](../bugs/task-01-ios-auth-dependency-conflict/index.md).
- Local only. No CI job in this epic; a manual or nightly CI job is a possible later story.
- Tests run in the app process with fakes (user, audio, keep-alive, clock, database). They never call Firebase or Google sign-in.
- One command runs everything: a single script, also exposed as a Zed task.
- Out of scope (stay manual checks): native permission dialogs, notification shade, background and lock-screen behavior, and process death. Patrol is a provisional later option if a flow ever needs native control.

## Decisions and current constraints

- **Tool: Flutter `integration_test`.** It is free, already a dev dependency, fully configurable, and runs in-process so fakes can be swapped in. Maestro was rejected because it is black-box (cannot swap in fakes, and it needs a `Semantics(identifier:)` on every target) and its docs list Flutter desktop as unsupported. Patrol was not chosen because no flow needs native control yet.
- **Known `integration_test` limits** (they shape the suite): no native UI, no lock-screen or app-switch automation, debug builds only, each file is a separate build and install, `pumpAndSettle` hangs on endless animations, and state carries over between tests in one run. Android can also leave the app installed after a run, so the script must clean up first.
- **Speed:** one aggregator entry file imports every suite so the app builds once. No test waits for real workout time.
- **Layout:** `integration_test/data/` (the four existing real-SQLite tests), `integration_test/flows/` (smoke flows), `integration_test/support/` (fake bootstrap and fakes), and `integration_test/all_tests.dart`.
- **Existing tests:** the four files in `integration_test/` check real SQLite behavior that `flutter test` cannot (schema, migrations, rollback, account isolation). They stay and are moved, not rewritten.
- **Shared Zed task:** `.zed/tasks.json` is tracked in git, so the new task is committed with the script.
- **Production change:** only a small extraction of app start-up from `lib/main.dart` so a test can start the app with its own dependencies. Composition rules in `CLAUDE.md` still apply.
- Unresolved: the exact fake-clock mechanism (decided in Story 3 after reading the timer ViewModel) and the Android system image for the emulator (decided in Story 1).

## Skill

The repository skill [skill-integration-tests](../../../.agents/skills/skill-integration-tests/SKILL.md) holds the conventions for writing and running these tests. Each implementation task links to it.

## Stories

1. [Run integration tests locally](stories/story-01-run-locally/index.md): one script, emulator handling, Zed task and docs. Ready for planning.
2. [Arrange the existing integration tests](stories/story-02-arrange-existing-tests/index.md): new folders and the aggregator. Depends on Story 1.
3. [Fake app environment](stories/story-03-fake-app-environment/index.md): test bootstrap, fakes, state reset. Depends on Story 1.
4. [Smoke flows](stories/story-04-smoke-flows/index.md): the three flows. Depends on Stories 2 and 3.

## Delivery order

Story 1 first. Stories 2 and 3 can then proceed independently. Story 4 needs both. The first usable result is Story 1 plus 2: one command running the existing tests.
