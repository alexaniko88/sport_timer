# EPIC: Developer tools

Status: Agreed scope.

## Goal

Give developers a place in debug builds to perform useful local maintenance while developing and testing the app.

## Agreed behavior and boundaries

- Open the developer page from the navigation drawer in debug builds only. The page and its actions must also be inaccessible through navigation in profile and release builds.
- The first tool purges all locally stored activity for every account on the device, after confirmation. Settings and authentication remain untouched.
- Other developer controls are outside the first version; future ideas are provisional.

## Current context

The app stores activity in a local SQLite database. The separate [delete statistics story](../statistics/stories/05-delete-statistics/index.md) is a user-facing, account-specific action; it is not a prerequisite for this developer tool.

## Stories

1. [Purge local activity](stories/01-purge-local-activity/index.md) — debug-only page and purge action; ready for planning.
