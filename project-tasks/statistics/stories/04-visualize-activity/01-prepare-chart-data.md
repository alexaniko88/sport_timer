# TASK 4.1: Prepare chart data and periods

Story: [Visualize activity](index.md)

Epic: [Statistics](../../index.md)

Status: Ready for planning.

## Goal and scope

Prepare account-scoped data for the agreed perspectives and calendar periods described in the [story](index.md). Preserve recorded local dates and existing completed-phase rules; do not change activity recording or introduce synchronization.

## Dependencies

Completed recording and daily-list stories; verify the current checkout. No dependency on day details.

## Acceptance criteria

- Week and month yield daily totals; year yields monthly totals for work, rest, total and rounds. Period boundaries use calendar dates and the locale's first weekday.
- Past zero-activity dates, future dates and active days (at least one completed work round) are distinguishable. Period totals match the underlying daily activity, including year/month boundaries and leap days.
- Account separation and stored local date assignments remain intact; partial phases are never added.

## Validation and context

Test aggregation, boundaries, zero/future dates, active-day criteria, account isolation and historical dates. Inspect `lib/features/statistics/domain/`, `data/`, and `presentation/statistics_view_model.dart` before planning; follow existing repository and state boundaries.
