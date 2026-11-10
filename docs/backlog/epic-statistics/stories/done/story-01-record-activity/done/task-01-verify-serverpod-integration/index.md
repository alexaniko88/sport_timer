---
id: STAT-01-01
status: done
type: feat
depends-on: []
---

# Choose local storage and define the data model

Story: [Story 1 overview](../../index.md)

Epic: [Statistics](../../../../../index.md)

## Dependencies

[Story overview](../../index.md).

## Goal

Choose local storage and define the record model and repository boundary for completed activity. Database integration belongs to [Task 1.2](../task-02-add-database-foundation/index.md).

## Decision and evidence

- Use SQLite through `sqflite`, retaining Firebase authentication. Cross-device synchronization is future scope; a Serverpod backend remains an option, not a prerequisite.
- The [sqflite package](https://pub.dev/packages/sqflite) documents Android, iOS, and macOS support, transactions, and database version management. The [Flutter SQLite guide](https://docs.flutter.dev/cookbook/persistence/sqlite) shows the Flutter setup. Pin compatible versions of `sqflite`, `path`, and a UUID package during integration.
- The checkout uses Flutter 3.47.7 and Dart 3.13.5, with Android and iOS projects. The macOS scaffold is incomplete. Package resolution, native builds, and actual `sqflite` runtime behavior remain to be verified in Task 1.2.
- The [story model](../../index.md#storage-model) records stable IDs, immutable ownership, millisecond durations and UTC instants, fixed local dates and offsets, pause and termination metadata, uniqueness, relationships, and indexes. It defines account-scoped aggregation and the repository boundary.
- `TimerSchedule` omits zero-duration stages, includes preparation when nonzero, and identifies a rest with the round just completed. Its stage position is the zero-based index used for phase uniqueness. A delayed tick may cross multiple boundaries; future recording must reconcile those boundaries on ticks, pause, and exit and keep required writes alive beyond the page lifecycle.
- Capture the Firebase UID when a run starts. An authentication change cannot reassign pending writes; signed-out starts cannot create account-owned records. A forced close preserves committed records, but cannot guarantee a pending write or invent a termination time.

## Acceptance criteria

- The selected local storage and supported platforms are documented, along with remaining runtime and native validation.
- The story defines the data model, relationship, unique constraint, indexes, daily aggregation, transaction behavior, migrations, and refresh strategy.
- Ownership, background execution, pause handling, and known versus unknown termination are accounted for without requiring a deployed backend.
- Future synchronization is explicitly separate scope; no database implementation or authentication replacement is included in this task.

## Validation

Check the chosen package documentation and current checkout. Review the model and affected task links for consistency. Task 1.2 must validate package resolution, actual local database behavior, migrations, and platform builds; documentation alone is not a runtime test.

Completion evidence: The storage decision and data model were reviewed, including stable phase IDs across retries and discarding stale account results. The documentation checks passed for 23 relative links and `git diff --check`; no database runtime or native build was claimed. Implementation commit `5fd4ad3` on branch `feat/verify-serverpod-integration`.
