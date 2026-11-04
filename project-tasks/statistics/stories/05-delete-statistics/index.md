# STORY 5: Delete statistics

Epic: [Statistics](../../index.md)

Status: Ready for planning.

## User outcome

Clear my recorded statistics when I no longer want to keep my workout history.

## Scope

- Offer **Delete statistics** in a menu in the Statistics screen's top bar. Explain in a confirmation dialog that all statistics for the signed-in account on this device will be deleted.
- Delete the account's entire local activity history only after confirmation. Other accounts' history is unaffected.
- Continue recording future workouts normally. Individual day or run deletion, editing, disabling recording, and cross-device deletion are outside this story.

## Acceptance criteria

- Cancel or dismiss the confirmation without changing history. Confirming deletes the signed-in account's history and updates the screen to its empty state.
- Deletion works safely when history is already empty. A failure is reported without falsely presenting deletion as successful.
- Pending activity writes cannot bring deleted history back after successful deletion; future workouts can still be recorded and displayed.
- Account changes during the operation cannot delete or display another account's data. Existing account isolation remains intact.
- The action and confirmation are accessible and localized, and work in both themes and at larger text sizes.

## Tasks

1. [Delete local statistics](01-delete-local-statistics.md).

## Dependencies and visual context

Uses the completed [recording](../done/01-record-activity/index.md) and [daily list](../done/02-daily-list/index.md) foundations; verify their availability in the implementation checkout. It is independent of [visualization](../done/04-visualize-activity/index.md); ensure any available views refresh after deletion.

Current visual references: [statistics](../../../../test/snapshots/goldens/statistics.png), [empty](../../../../test/snapshots/goldens/statistics_empty.png), [error](../../../../test/snapshots/goldens/statistics_error.png), and the [snapshot flow index](../../../../test/snapshots/README.md). These do not capture a deletion menu or confirmation. Check the implementation checkout for the current layout before planning.
