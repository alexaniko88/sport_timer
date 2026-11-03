# STORY 1: Run integration tests locally

Epic: [Integration tests](../../index.md)

Status: Ready for planning.

## User outcome

As the developer, I want one command that prepares an Android target and runs the integration tests so that I can check the app quickly without setting up anything by hand.

## Scope

- A run script that picks the target, makes sure the app is not left installed from an earlier run, and runs the integration tests.
- Emulator handling for `sport-timer-emulator`.
- A Zed task and `CLAUDE.md` documentation.
- Excludes: writing fakes or flows, iOS, macOS and CI.

## Acceptance criteria

- With a real Android device connected, the script runs the tests on it.
- With no device connected, the script uses `sport-timer-emulator`: it creates it if it does not exist, leaves an existing one unchanged, boots it and waits until it is ready.
- An optional device ID argument overrides the automatic choice.
- A leftover installed app from an earlier run does not break the next run.
- The script fails with a clear message when the Android SDK tools are missing.
- A Zed task runs the script, and `CLAUDE.md` lists it with the other commands.

## Tasks

1. [Add the run script](01-add-run-script.md).
2. [Expose the script as a Zed task and document it](02-add-zed-task-and-docs.md).

## Dependencies and open decisions

No dependencies. Open decision: the Android system image and API level for the emulator, decided in Task 1.1.
