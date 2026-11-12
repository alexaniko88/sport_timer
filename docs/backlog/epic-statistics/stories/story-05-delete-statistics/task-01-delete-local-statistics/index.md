---
id: STAT-05-01
status: ready
type: feat
complexity: 8
depends-on: [DEV-01-01, STAT-06-03]
touches:
  - lib/features/statistics/domain/activity_repository.dart
  - lib/features/statistics/data/activity_access.dart
  - lib/features/statistics/data/sqflite_activity_repository.dart
  - test/features/statistics/data/activity_access_test.dart
skills: []
---

# Delete local statistics

Story: [Delete statistics](../index.md)

Epic: [Statistics](../../../index.md)

## Goal

Add a storage operation that deletes the signed-in account's local activity (sessions, phases and drafts), and make that account's earlier pending writes harmless. No UI. Serves R3, R4, R5 and R6.

## Context

- `lib/features/statistics/data/activity_access.dart` (`ActivityAccess`): writes go through private `_ActivitySessionCreation` and `_ActivitySessionHandle`, which carry `accountId`. `_generation` is bumped when the account changes; `_requireAccount()` throws `StateError('No signed-in account')`.
- From DEV-01-01: the global `_purgeEpoch`, captured synchronously when a creation or handle is issued and compared inside each write's `db.transaction`; a stale write writes nothing, returns normally and does not emit. `deleteAllActivity()` is the model for this task: epoch bump before any `await`, one transaction deleting `completed_phases` then `timer_sessions`, `_notifyChange()` after success. `test/features/statistics/data/activity_access_test.dart` holds the real in-memory SQLite setup and the switchable fake accounts.
- From STAT-06-02 / STAT-06-03: the handle writes are `createPreparedSession`, `addPhases`, `endSession`, `finishRun` and `saveDraft`; `draft_phases` references `timer_sessions(id)` with `ON DELETE CASCADE`; `recoverUnfinishedRuns` handles each draft session in its own transaction.
- `lib/features/statistics/data/sqflite_activity_repository.dart`: `_run(…, checkAccount: …)` turns exceptions and `StateError` into `Failure`.

## Contract

- `ActivityRepository.deleteAccountActivity()` — new here, as in the story's shared contracts, with a short comment (deletes the signed-in account's local activity; that account's writes issued before the call are dropped).
- `SqfliteActivityRepository.deleteAccountActivity()` — new here: `_run(_access.deleteAccountActivity)`.
- `ActivityAccess.deleteAccountActivity()` — new here, `Future<void>`:
  1. Synchronously, before any `await`: throw `StateError('Activity access is closed')` when closed; `account = _requireAccount()`; `generation = _generation`; bump the account epoch: `_accountEpochs[account] = (_accountEpochs[account] ?? 0) + 1` (new private `Map<String, int> _accountEpochs`). The bump stays even if the delete fails.
  2. One `db.transaction`: first, if `_generation != generation` or `_accounts.currentAccountId != account`, throw `StateError('Account changed during delete')` (rollback, nothing deleted). Then `DELETE FROM completed_phases WHERE session_id IN (SELECT id FROM timer_sessions WHERE account_id = ?)`, then `DELETE FROM timer_sessions WHERE account_id = ?` (drafts go by cascade).
  3. After success, `_notifyChange()`, also when nothing was deleted.
- Account epoch on writes — changed here: a creation or handle also stores `_accountEpochs[accountId] ?? 0` when it is issued (read synchronously at the same point as the global epoch). Every handle write treats it as stale when the global epoch **or** its account's epoch changed since it was issued, with the existing stale behavior (writes nothing, returns normally, no emit). Put the check in one private helper used by all five writes.
- Recovery — no change: a deleted session's drafts go by cascade, so `recoverUnfinishedRuns` finds nothing to restore for it. The acceptance case below guards this.
- Test fakes — no change: every hand-written `ActivityRepository` fake in `test/` sends unknown members to `noSuchMethod`, so the new method needs no stub. STAT-05-02 adds the configurable fakes it needs.

## Decisions

- **Same rule as the purge:** the account's earlier writes are dropped silently and return success, so the recorder neither retries nor reports a failure. Accepted by the user.
- **Account change aborts:** deleting another account's data, or the wrong one, is worse than a failed delete. Accepted by the user.
- **Overlapping writes:** a write issued after the epoch bump but before the transaction carries the new epoch and may still be removed by the delete. Accepted, as for the purge; tests create post-delete data only after awaiting the delete.

## Out of scope

- UI and view models (STAT-05-02). The all-accounts purge. Schema changes.

## Files and tests

- Tests: new cases in `test/features/statistics/data/activity_access_test.dart`, with the existing setup (in-memory database, switchable accounts, `SqfliteActivityRepository` on top). Check rows with `SELECT COUNT(*)`.

## Acceptance

- [ ] Given sessions, phases and drafts for accounts A and B with A signed in, when `deleteAccountActivity()` runs, then A has no rows in `timer_sessions`, `completed_phases` and `draft_phases`, B's rows are unchanged, and it returns `Success`. Check: `test/features/statistics/data/activity_access_test.dart` "deletes only the signed-in account".
- [ ] Given A has no activity, when `deleteAccountActivity()` runs, then it returns `Success` and `changes` emits. Check: `test/features/statistics/data/activity_access_test.dart` "deleting an empty account succeeds".
- [ ] When no account is signed in or the access is closed, then it returns `Failure` and nothing is deleted. Check: `test/features/statistics/data/activity_access_test.dart` "delete needs an account and an open access".
- [ ] Given the account switches from A to B after the call starts and before its transaction, when the delete finishes, then it returns `Failure` and neither account loses rows. Check: `test/features/statistics/data/activity_access_test.dart` "account change aborts the delete".
- [ ] Given a creation and a handle for A issued before the delete, when `createPreparedSession`, `finishRun` and `saveDraft` run after it, then nothing is written for A, each returns `Success` and `changes` does not emit. Check: `test/features/statistics/data/activity_access_test.dart` "drops the account's writes from before the delete".
- [ ] Given a handle for B issued before A's delete, when B's `finishRun` runs after it, then B's run is stored. Check: `test/features/statistics/data/activity_access_test.dart` "other accounts keep their pending writes".
- [ ] Given A has an unfinished draft, when A's statistics are deleted and `recoverUnfinishedRuns` runs, then nothing is restored for A and it returns `Success`. Check: `test/features/statistics/data/activity_access_test.dart` "recovery restores nothing after a delete".
- [ ] When A records a new session after the delete, then it is stored and appears in `readDailyActivity()`. Check: `test/features/statistics/data/activity_access_test.dart` "records new activity after a delete".
- [ ] Given a purge (`deleteAllActivity`) and then a new handle, when it writes, then it is stored, so the two epochs do not block each other. Check: `test/features/statistics/data/activity_access_test.dart` "purge and account delete epochs are independent".
- [ ] When the checks run, then everything passes. Check: `fvm dart tool/agent_check.dart --skip-build`.
