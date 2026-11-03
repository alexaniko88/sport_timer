# STORY 1: Purge local activity

Epic: [Developer tools](../../index.md)

Status: Ready for planning.

## User outcome

As a developer, I can clear local activity for all accounts from a debug-only page so I can start testing with an empty history.

## Scope

Add a debug-only navigation drawer entry and developer page with a single purge action. Explain the scope in a confirmation dialog. Preserve settings and authentication; do not add other tools in this version.

## Acceptance criteria

- The entry and page work in debug builds and cannot be opened or used in profile or release builds, including through direct navigation.
- Canceling or dismissing the confirmation leaves activity unchanged. Confirming removes all local activity for all accounts on the device, including sessions and their recorded phases.
- An empty database can be purged safely. Success or failure is communicated accurately, and statistics views reflect a successful purge.
- Pending activity writes cannot restore purged history after success; future workouts can still be recorded. Settings and sign-in remain unchanged.
- The page and confirmation are accessible and usable in both themes and at larger text sizes.

## Tasks

1. [Add the developer page and activity purge](01-add-developer-page-and-purge.md).

## Dependencies and visual context

Uses the existing activity database and recording foundation; verify the implementation checkout before planning. The [account-specific deletion story](../../../statistics/stories/05-delete-statistics/index.md) is independent; coordinate shared behavior if it has been implemented by then.

The [drawer snapshot](../../../../test/snapshots/goldens/home_drawer.png) and [snapshot flow index](../../../../test/snapshots/README.md) show the current navigation. There is no developer page or purge confirmation snapshot yet. Check the implementation checkout for current UI before planning.
