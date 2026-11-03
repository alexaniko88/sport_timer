# TASK 3.2: Add the fakes and the reset

Story: [Fake app environment](index.md)

Epic: [Integration tests](../../index.md)

Status: Blocked by [Task 3.1](01-extract-app-bootstrap.md).

## Goal

Ready-to-use fakes and a single setup helper in `integration_test/support/` that give every test a clean, fast, signed-in app.

## Scope

- Fakes of the existing domain contracts: `UserRepository` (a signed-in fake user), `AudioManager`, `BackgroundKeepAlive`, and the account source for statistics.
- A fast clock so a full workout finishes in seconds. Decide the mechanism by reading the timer ViewModel (fake clock or very short durations) and record the choice in this task.
- A throwaway database per test and fresh settings storage.
- One helper that resets `getIt`, the router and the data, registers the fakes, and starts the app.
- Excludes: the smoke flows themselves, and fakes for contracts no flow needs.

## Dependencies

[Task 3.1](01-extract-app-bootstrap.md).

## Acceptance criteria

- A test using the helper starts on the home screen as a signed-in fake user, with no network, no sound and no leftover data.
- A timer phase finishes in seconds.
- Two tests in a row do not affect each other.

## Validation

A small test of the helper itself, run through the aggregator from [Story 2](../02-arrange-existing-tests/index.md) on Android. Use the hand-written fake style of the existing unit tests; no mocking package.

## Implementation context

Follow the repository skill [skill-integration-tests](../../../../.agents/skills/skill-integration-tests/SKILL.md) for the conventions (layout, fakes, running, flow rules). It describes the target setup, so check which files exist first.

Contracts are in `lib/features/*/domain/` (`user_repository.dart`, `audio_manager.dart`, `background_keep_alive.dart`, `activity_account_source.dart`). The existing integration tests already build real SQLite databases with throwaway file names and a fake account source; reuse that approach.
