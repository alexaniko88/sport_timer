---
name: skill-integration-tests
description: >-
  Write, change, arrange or run integration tests in the Sport Timer app with Flutter's
  integration_test on Android: the fake app environment, smoke flows, real-SQLite data tests,
  and the local run script. Use when the user asks for an integration test, an end-to-end flow,
  a fake or mock environment for the app, or to run the integration suite. Not for unit,
  widget or golden tests.
---

# Integration tests in Sport Timer

The plan and decisions are in `docs/backlog/epic-integration-tests/index.md`. Read it first, and read the story or task you are working on. This skill describes the target setup. Several parts may not exist yet, so check which files are really in `integration_test/` and `lib/main.dart` before relying on them. Never assume a helper exists.

## What these tests are for

- A few **smoke flows** for the most important user paths, in the running app: timer from setup, timer from a template, finished session in statistics. No screen details. Those belong to unit, widget and golden tests.
- **Data tests** that need a real platform, such as real SQLite through `sqflite`. They cannot run with plain `flutter test`.
- Do not add a flow for something a widget test can prove. Do not test the login screen or Google sign-in.

## Tool and platform

- Flutter `integration_test` only. No Maestro, no Patrol, unless the user opens a new decision.
- **Android only.** Default target is the emulator `sport-timer-emulator`. A connected real device is also allowed and wins. iOS and macOS are out of scope (see `docs/backlog/bugs/task-01-ios-auth-dependency-conflict/index.md`).
- Local only. No CI job unless a story adds one.
- Always `fvm flutter`, never bare `flutter`.

## Layout

```
integration_test/
  all_tests.dart     imports every suite so the app builds once
  data/              real-SQLite tests (the first four tests of the project)
  flows/             smoke flows, one file per flow
  support/           app bootstrap, fakes, reset helper
```

- Register a new suite in `all_tests.dart`. A suite that is not imported there does not run in the normal command.
- Moving the old tests is a task of its own. Use `git mv` and do not rewrite their logic.

## How to run

Use the repository run script (see `CLAUDE.md` for its name) or its Zed task. It picks the device, removes a leftover installed app, and runs the aggregator. For one file while developing, run `fvm flutter test integration_test/flows/<file>.dart -d <device>`. Run only the files you touched, and the whole suite before hand-off.

## Writing a flow

1. Start the app only through the helper in `support/`. It resets `getIt`, the static `GoRouter`, the settings storage and the database, registers the fakes, and calls `runApp`.
2. **No real waiting.** Phases finish in seconds because of the fake clock or short durations. Never use a long `Future.delayed` or wait for real workout time.
3. **Avoid `pumpAndSettle` on a running timer screen.** It hangs on endless animations. Pump explicitly or advance the fake clock, and wait for a condition (`pumpUntilFound`-style helper) with a timeout and a clear failure message.
4. Find widgets by key or semantics label first. Use localized text only when there is no better handle, and read it from `AppLocalizations`, not as a hard-coded string.
5. One flow per file, one path per test, steps in the order the user does them. A failure must show which step broke.
6. Each test starts from clean data. Never depend on another test having run.
7. If a step needs something from the OS (permission dialog, notification, lock screen, app switch, process death), stop. `integration_test` cannot do it. Record it as a manual check and tell the user.

## Fakes

- Hand-written fakes of the domain contracts (`UserRepository`, `AudioManager`, `BackgroundKeepAlive`, `ActivityAccountSource`), in the style of the existing unit-test fakes. No mocking package.
- Keep the real SQLite repository with a throwaway database file for tests that check recording and statistics, as the existing data tests do.
- Fakes live in `integration_test/support/`. Do not put test code in `lib/`.
- The only production change allowed for testability is the start-up extraction in `lib/main.dart` and registration in `lib/di/di.dart`. Only `main.dart`, `di/di.dart` and `navigation.dart` may know both a contract and its implementation. Follow `CLAUDE.md`.

## Before hand-off

- `fvm flutter analyze` is clean, including `integration_test/`.
- The aggregator runs green on Android, twice in a row (it proves the reset works).
- If a screen changed, refresh the UI snapshots and `test/snapshots/README.md` as `CLAUDE.md` says.
- List what was not covered, such as native dialogs, background and lock screen, process death and iOS, so the user knows what stays manual.
