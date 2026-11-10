# STORY 2: Arrange the existing integration tests

Epic: [Integration tests](../../index.md)

## User outcome

As the developer, I want the existing real-SQLite tests and the future flows in a clear structure, built once per run, so that the suite stays fast and easy to extend.

## Scope

- Move the four existing tests into `integration_test/data/` and add `integration_test/all_tests.dart` that imports every suite.
- Excludes: rewriting the tests, new flows, and the support folder content (Story 3).

## Acceptance criteria

- The four tests run from the aggregator with the same results as before.
- The app builds and installs once per run, not once per file.
- Git history of the moved files is kept (`git mv`).

## Tasks

1. [Move the tests and add the aggregator](task-01-move-tests-and-add-aggregator/index.md).

## Dependencies and open decisions

Depends on [Story 1](../story-01-run-locally/index.md) so the run script can verify the result. No open decisions.
