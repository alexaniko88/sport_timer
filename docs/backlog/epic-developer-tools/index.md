---
abbr: DEV
---

# EPIC: Developer tools

## Goal

Give developers a place in debug builds to perform useful local maintenance while developing and testing the app.

## Agreed behavior and boundaries

- Open the developer page from the bottom of the navigation drawer in debug builds only. In profile and release builds the drawer entry and the `/developer` route do not exist, so the page and its actions cannot be reached.
- The first tool purges all locally stored activity for every account on the device, after confirmation. Settings and authentication remain untouched.
- Other developer controls are outside the first version; future ideas are provisional.

## Decisions and current constraints

- **Debug gate:** one `developerToolsEnabled` flag, set from `kDebugMode` by the app and settable by tests, so the release behavior is tested too.
- **No localization:** the developer page is never seen by end users, so its texts are plain English constants in the code, with no ARB keys.
- **Purge means purge:** writes queued before a purge (for example by the timer recorder) are dropped silently and can never bring purged history back.
- The app stores activity in a local SQLite database (`activity.db`). The [delete statistics story](../epic-statistics/stories/story-05-delete-statistics/index.md) is a separate, user-facing, account-specific action; this epic does not depend on it.

## Stories

1. [Purge local activity](stories/story-01-purge-local-activity/index.md) — debug-only page and purge action.

## Delivery order

[DEV-01-01](stories/story-01-purge-local-activity/task-01-purge-activity-storage/index.md) (storage purge) first, then [DEV-01-02](stories/story-01-purge-local-activity/task-02-add-developer-page/index.md) (developer page).
