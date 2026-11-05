# STORY 1: Purge local activity

Epic: [Developer tools](../../index.md)

## User outcome

As a developer, I can clear local activity for all accounts from a debug-only page so I can start testing with an empty history.

## Scope

Add a debug-only entry at the bottom of the navigation drawer and a developer page with a single purge action. Explain the scope in a confirmation dialog. Preserve settings and authentication; do not add other tools in this version. Texts are English only, with no localization.

## Acceptance criteria

- The entry and page work in debug builds and cannot be opened or used in profile or release builds, including through direct navigation.
- Canceling or dismissing the confirmation leaves activity unchanged. Confirming removes all local activity for all accounts on the device, including sessions and their recorded phases.
- An empty database can be purged safely. Success or failure is communicated accurately, and statistics views reflect a successful purge.
- Pending activity writes cannot restore purged history after success; future workouts can still be recorded. Settings and sign-in remain unchanged.
- A purge cannot be started twice at the same time.
- The page and confirmation are usable in both themes and at larger text sizes.

## Tasks

1. [Purge activity storage](01-purge-activity-storage/index.md).
2. [Add the developer page](02-add-developer-page/index.md).

## Dependencies and open decisions

No open decisions. DEV-01-02 depends on DEV-01-01. The story does not depend on the [account-specific deletion story](../../../statistics/stories/05-delete-statistics/index.md).

Visual references: the [drawer golden](../../../../test/snapshots/goldens/home_drawer.png) and the [snapshot flow index](../../../../test/snapshots/README.md). The approved [mockup](02-add-developer-page/mockup.html) shows the new page and dialog.
