---
id: DEV-01-01
status: draft
type: feat
depends-on: [STAT-05-01]
---

# Add the developer page and activity purge

Story: [Purge local activity](../index.md)

Epic: [Developer tools](../../../index.md)

## Goal

Let a developer safely clear all accounts' local activity from a page available only in debug builds.

## Scope

Deliver the drawer entry, protected page, confirmation, all-account activity purge, feedback and refresh described in the [story](../index.md). Preserve settings and authentication. Additional tools and user-facing account-specific deletion are excluded.

## Dependencies

The existing activity database and recording foundation; verify their availability on the implementation checkout. The [account-specific deletion task](../../../../statistics/stories/05-delete-statistics/01-delete-local-statistics/index.md) is independent.

## Acceptance criteria

- Debug builds expose the page through the drawer. Profile and release builds cannot access the page or execute its action, including through direct navigation.
- Confirmation identifies all accounts' local activity as the deletion scope. Canceling or dismissing changes nothing; confirmation clears sessions and phases across accounts, including when already empty.
- A failed purge reports failure without claiming success. Successful purge refreshes available statistics, prevents pending writes from restoring purged history, and leaves future recording functional.
- Settings and authentication are unchanged. The page and dialog are accessible in both themes and at larger text sizes.

## Validation

Use appropriate unit, widget and real-SQLite tests for build-mode access, direct navigation, confirmation and cancellation, multiple accounts, empty and populated data, failure, pending writes, refresh, and later recording. Verify settings and authentication are preserved. Check accessibility and both themes. Refresh affected snapshots and update the [flow index](../../../../../test/snapshots/README.md), including meaningful new page and dialog states.

## Implementation context

Inspect `lib/features/home/presentation/home_page.dart`, `lib/navigation.dart`, `lib/features/statistics/data/activity_database.dart`, `lib/features/statistics/data/activity_access.dart` and timer recording before planning. The current schema has sessions and dependent phases with a restrictive foreign key; choose a safe deletion and write-coordination approach during planning. Review the [visual context](../index.md#dependencies-and-visual-context). Backlog approval does not approve application code changes.
