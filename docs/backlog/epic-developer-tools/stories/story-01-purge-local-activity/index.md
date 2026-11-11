# STORY 1: Purge local activity

Epic: [Developer tools](../../index.md)

As a developer, I can clear local activity for all accounts from a debug-only page so I can start testing with an empty history.

## Scope

- In: a debug-only entry at the bottom of the navigation drawer and a developer page with a single purge action. A confirmation dialog explains the scope. Texts are English only, with no localization.
- Out: other tools in this version; any change to settings or authentication. The story does not depend on the [Delete statistics story](../../../epic-statistics/stories/story-05-delete-statistics/index.md), which is account-specific.

## Requirements

- R1: The entry and page work in debug builds and cannot be opened or used in profile or release builds, including through direct navigation — DEV-01-03.
- R2: Cancelling or dismissing the confirmation leaves activity unchanged. Confirming removes all local activity for all accounts on the device, including sessions and their recorded phases — DEV-01-01, DEV-01-02, DEV-01-03.
- R3: An empty database can be purged safely. Success or failure is reported accurately, and statistics views reflect a successful purge — DEV-01-01, DEV-01-02, DEV-01-03.
- R4: Pending activity writes cannot restore purged history after success; future workouts can still be recorded. Settings and sign-in remain unchanged — DEV-01-01.
- R5: A purge cannot be started twice at the same time — DEV-01-02, DEV-01-03.
- R6: The page and confirmation are usable in both themes and at larger text sizes — DEV-01-03.

## Tasks

1. [Purge activity storage](task-01-purge-activity-storage/index.md)
2. [Add the developer tools view model](task-02-add-developer-tools-view-model/index.md)
3. [Add the developer page](task-03-add-developer-page/index.md)

## Shared contracts

- `ActivityRepository.deleteAllActivity()` (new): `Future<Result<void>> deleteAllActivity()` in `lib/features/statistics/domain/activity_repository.dart`. It deletes every account's local activity and drops writes prepared before the call. Purge activity storage (DEV-01-01) adds it; Add the developer tools view model (DEV-01-02) calls it.
- `DeveloperToolsState` and `DeveloperToolsViewModel` (new) in `lib/features/developer/presentation/`: `state`, `Future<bool> purge()` (blocks a second call while pending), `dispose()`. Add the developer tools view model (DEV-01-02) adds them unwired; Add the developer page (DEV-01-03) creates the ViewModel in `DeveloperToolsPage` and wires the page, drawer entry and `/developer` route together.

## References

Visual references: the [drawer golden](../../../../../test/snapshots/goldens/home_drawer.png) and the [snapshot flow index](../../../../../test/snapshots/README.md). The approved [mockup](mockup.html) shows the new page and dialog.
