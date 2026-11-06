# STORY 6: Record partial activity

Epic: [Statistics](../../index.md)

## User outcome

As a person training with the timer, I want every second I actually trained or rested to be saved, even when I leave in the middle of a round or the app is killed. That way my statistics show the real work I did.

## Current behavior (observed)

- `DefaultTimerActivityRecorder` checks phase boundaries on every tick. It writes each **fully completed** work or rest phase right away, with the full scheduled duration.
- Leaving the timer during a phase drops that unfinished phase. A round counts only when its work phase finishes.
- After a forced close, rows that were already written survive. Unfinished time is lost.

Result: if you leave 2:30 into a 3:00 round, those 2:30 and the round are not saved.

## Agreed behavior

- **What counts:** only active time that has really passed, in **whole seconds, rounded down**, for both work and rest. Milliseconds never count. Example: leaving at 1:23.8 into a round saves 1:23 of work. A partial phase with less than 1 whole second is not saved.
- **Rounds:** a partial work phase counts as a round once **5 seconds** of it have passed. A partial work phase shorter than 5 s still adds its seconds to work time, but not to the round count. A work phase that runs to its end always counts as a round, even when it is set shorter than 5 s.
- **Not counted:** preparation and paused time, as today.
- **When to save:** the run is kept in memory while the timer page is open. The final records are written **once, when the user leaves the timer page**. This applies whether the timer finished, is running or is paused. Finishing or pausing does not write the final records.
- **Forced close:** the app gets no signal when the OS kills it, so it cannot save at that moment. Instead the recorder keeps a hidden **draft** in the database: every 10 s while running, at each phase change (including finish) and on pause. Statistics never read the draft. On the next app start, an unfinished draft becomes final records. At most, the time since the last draft is lost.
- **Recovered run:** its end time and the date of its last partial phase come from the last draft, not from when the app opens again. It is saved under the account that started it.
- **Dates:** each phase keeps its own logical local completion date and UTC offset, as today. A partial phase's completion instant is the moment the user left (or the last draft).
- **History and UI:** existing records stay as they are, with no data migration of old rows. There is no Statistics UI change. Partial time just adds to the existing daily totals, round counts and day details.

## Scope

Included: counting partial time and rounds, a single final write on leaving the timer, drafts and recovery after a forced close, the schema and query changes these need, and tests.

Excluded: restoring the timer itself after a forced close, marking partial rounds in the UI, changing preparation or pause rules, backup or sync, integration tests (the integration test setup does not exist yet).

## Acceptance criteria

- Leaving partway through a work or rest phase saves the whole seconds that phase actually ran. Completed phases before it keep their full durations.
- A partial work phase of 5 s or more adds one round. One shorter than 5 s adds its seconds but no round. A work phase that runs to its end always adds a round.
- Preparation and paused time never count. Leaving during preparation saves nothing, and the run does not appear in statistics.
- Final records are written once per run, when the user leaves the page, whether the timer finished, is running or is paused. Retrying a failed write cannot double-count.
- After a forced close while training, the next app start saves the run up to its last draft, under the account that started it. Recovery runs only once per draft.
- Deleted or purged statistics cannot come back through recovery.
- Activity keeps its logical local date, including a partial phase that crosses midnight.
- Daily totals, round counts, chart data and day details include partial time and follow the round rule. Existing history is unchanged.

## Tasks

1. [Count partial progress in whole seconds](01-count-partial-progress/index.md).
2. [Save the run once when leaving the timer](02-save-on-leaving-timer/index.md).
3. [Save drafts and recover a run after a forced close](03-checkpoint-and-recover/index.md).

## Decisions

- **Final save on leaving, plus a hidden draft for kills.** The user keeps "save once when leaving the timer page" as the only normal save. The draft exists only so a killed app does not lose the run.
- **Draft moments:** every 10 s while running, at each phase change (including finish) and on pause. There is no extra "app went to background" trigger: the foreground service keeps ticks running, and the recorder stays free of Flutter lifecycle code.
- **Short rounds:** a work phase that runs to its end always counts as a round. The 5 s rule only applies to a partial work phase.
- **Draft storage:** a separate `draft_phases` table linked to `timer_sessions` with `ON DELETE CASCADE`. Statistics never read it, and deleting a session deletes its draft, so deleted history cannot come back.
- **Round rule in SQL, no new phase column (planner choice):** a work row counts as a round when `duration_ms >= 5000` or `duration_ms >= timer_sessions.work_duration_ms`. Full phases always match the second condition, so old rows keep their meaning and `completed_phases` needs no migration.
- **No end-to-end task:** the old task 6.4 was dropped, because the integration test setup does not exist yet. Each task carries its own real-SQLite tests.

## Dependencies

Builds on the completed [recording story](../01-record-activity/index.md). Tasks 6.2 and 6.3 build on the purge in [developer tools](../../../developer-tools/index.md) (`DEV-01-01`), which adds the real-SQLite test setup and the purge epoch that stale writes must respect. [Delete statistics](../05-delete-statistics/index.md) deletes sessions, so the cascade removes their drafts too.
