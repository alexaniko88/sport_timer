# STORY 3: Fake app environment

Epic: [Integration tests](../../index.md)

Status: Depends on [Story 1](../01-run-locally/index.md).

## User outcome

As the developer, I want to start the real app in a test with fake dependencies so that flows run fast, offline and without a Google account.

## Scope

- Extract app start-up from `lib/main.dart` so a test can start the app with its own dependencies. Production behavior does not change.
- Fakes for the user, audio, background keep-alive, clock, and database, in `integration_test/support/`.
- A reset between tests so state does not carry over.
- Excludes: the flows themselves, and changes to production behavior.

## Acceptance criteria

- A test can start the app signed in as a fake user, with no Firebase call and no sound.
- A timer phase of normal length finishes in seconds in a test.
- Each test starts from clean data, whatever ran before it.
- The production app starts and behaves as before, and the layer boundary test still passes.

## Tasks

1. [Extract app start-up](01-extract-app-bootstrap.md).
2. [Add the fakes and the reset](02-add-fakes-and-reset.md).

## Dependencies and open decisions

Depends on [Story 1](../01-run-locally/index.md). Open decision: how the clock is faked (fake clock, or very short durations), decided in Task 3.2 after reading how the timer ViewModel handles time. `CLAUDE.md` says only `main.dart`, `di/di.dart` and `navigation.dart` may know both a contract and its implementation; the extraction must respect that.
