---
id: INT-01-01
status: draft
type: feat
depends-on: []
---

# Add the run script

Story: [Run integration tests locally](../index.md)

Epic: [Integration tests](../../../index.md)

## Goal

A single script at the repository root, next to `rebuild.sh`, that selects an Android target and runs `fvm flutter test` for the integration tests.

## Scope

- Target choice: explicit device ID argument first, then a connected real device, then `sport-timer-emulator`.
- Create `sport-timer-emulator` with `avdmanager` only when it does not exist; never change an existing one. Pin the system image and API level in the script.
- Boot the emulator if it is not running and wait until it has finished booting.
- Remove the installed app before the run so a leftover install cannot break it.
- Use `fvm flutter`, never bare `flutter`.
- Excludes: CI use, iOS, macOS, and the Zed task (Task 1.2).

## Dependencies

None.

## Acceptance criteria

- Works with a connected real device, with no device connected, and with a device ID argument.
- Running it twice in a row works, and the second run does not recreate the emulator.
- Clear error when `adb`, `avdmanager` or the system image is missing.
- Exits with the test run's exit code.

## Validation

Run the script in the three cases above and check the exit codes. The four existing real-SQLite tests are the target until the new suites exist.

## Implementation context

Follow the repository skill [skill-integration-tests](../../../../../.agents/skills/skill-integration-tests/SKILL.md) for the conventions (layout, fakes, running, flow rules). It describes the target setup, so check which files exist first.

`rebuild.sh` is the style reference for repository scripts. The existing tests are in `integration_test/`. Android SDK tools are under the user's SDK path; the script must find them through `ANDROID_HOME` or the standard SDK location, not a hard-coded username.
