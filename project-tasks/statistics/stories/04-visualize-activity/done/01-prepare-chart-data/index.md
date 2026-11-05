---
id: STAT-04-01
status: done
type: feat
depends-on: []
---

# Prepare chart data and periods

Story: [Visualize activity](../../index.md)

Epic: [Statistics](../../../../index.md)

## Goal and scope

Prepare account-scoped data for the agreed perspectives and calendar periods described in the [story](../../index.md). Preserve recorded local dates and existing completed-phase rules; do not change activity recording or introduce synchronization.

## Dependencies

Completed recording and daily-list stories; verify the current checkout. No dependency on day details.

## Acceptance criteria

- Week and month yield daily totals; year yields monthly totals for work, rest, total and rounds. Period boundaries use calendar dates and the locale's first weekday.
- Past zero-activity dates, future dates and active days (at least one completed work round) are distinguishable. Period totals match the underlying daily activity, including year/month boundaries and leap days.
- Account separation and stored local date assignments remain intact; partial phases are never added.

## Validation and context

Test aggregation, boundaries, zero/future dates, active-day criteria, account isolation and historical dates. Inspect `lib/features/statistics/domain/`, `data/`, and `presentation/statistics_view_model.dart` before planning; follow existing repository and state boundaries.

## Completion evidence

Calendar periods and account-scoped daily and monthly chart data are implemented, preserving stored local dates and completed-phase totals. Future dates, recorded activity and active days are represented separately.

Validation: focused unit tests passed (11); full Flutter suite passed (411); Android integration suite passed (16) on a connected device; touched-file formatting and analysis passed. Review passed with no findings.
