---
id: STAT-05-01
status: draft
type: feat
depends-on: []
---

# Delete local statistics

Story: [Delete statistics](../index.md)

Epic: [Statistics](../../../index.md)

## Goal

Let a user confirm deletion of all their locally stored statistics while preserving other accounts and future recording.

## Scope

Deliver the menu action, confirmation, account-scoped deletion, feedback and refreshed state described in the [story](../index.md). Handle pending writes and account changes without resurrecting deleted history or affecting another account. Individual deletions, turning off recording and cross-device deletion are excluded.

## Dependencies

The [recording](../../done/story-01-record-activity/index.md) and [daily list](../../done/story-02-daily-list/index.md) foundations; verify the implementation checkout before planning. The chart story is independent.

## Acceptance criteria

- The top-bar action opens a clear confirmation; cancel and dismissal preserve history.
- Confirmation removes all local history for the account on this device, including when empty, and refreshes the available statistics views. Other accounts remain unchanged.
- Errors are visible and do not claim success. Pending writes cannot restore deleted history after success, and account changes cannot redirect deletion to another account.
- A later workout records and appears normally. The action and dialog are localized and accessible in both themes and at larger text sizes.

## Validation

Cover confirmation and cancellation, empty and populated histories, deletion failure, account isolation and changes, pending writes, refresh, and recording a later workout using appropriate unit, widget and real-SQLite tests. Check accessibility and localization. Refresh affected snapshots and update the [flow index](../../../../../../test/snapshots/README.md), including the menu and confirmation as appropriate.

## Implementation context

Inspect `lib/features/statistics/domain/activity_repository.dart`, `data/sqflite_activity_repository.dart`, `data/activity_access.dart`, and the Statistics presentation and timer recording code before planning. Review the [visual references](../index.md#dependencies-and-visual-context) and current navigation. Choose how to coordinate deletion with pending writes during implementation planning; backlog approval does not approve application code changes.
