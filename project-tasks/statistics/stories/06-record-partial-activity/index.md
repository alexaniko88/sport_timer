# STORY 6: Record partial activity

Epic: [Statistics](../../index.md)

Status: Ready for planning.

## User outcome

As a person training with the timer, I want every second I actually trained or rested to be saved, even when I leave in the middle of a round or the app is killed. That way my statistics show the real work I did.

## Current behavior (observed)

- `DefaultTimerActivityRecorder` checks phase boundaries on every tick. It writes each **fully completed** work or rest phase right away, with the full scheduled duration.
- Leaving the timer during a phase drops that unfinished phase. A round counts only when its work phase finishes.
- After a forced close, rows that were already written survive. Unfinished time is lost.

Result: if you leave 2:30 into a 3:00 round, those 2:30 and the round are not saved.

## Agreed behavior

- **What counts:** only active time that has really passed, in **whole seconds, rounded down**, for both work and rest. Milliseconds never count. Example: leaving at 1:23.8 into a round saves 1:23 of work.
- **Rounds:** a work round counts toward the round total once **5 seconds** of it have passed. A partial work phase shorter than 5 s still adds its seconds to work time, but not to the round count.
- **Not counted:** preparation and paused time, as today.
- **When to save:** the run is kept in memory while the timer page is open. The final records are written **once, when the user leaves the timer page**. This applies whether the timer finished, is running or is paused. Finishing or pausing does not write the final records.
- **Forced close:** the app gets no signal when the OS kills it, so it cannot save at that moment. Instead the recorder keeps a **draft checkpoint** in the database. On the next app start, an unfinished draft becomes final records. At most, the time since the last checkpoint is lost.
- **Recovered run:** its end time and the date of its last partial phase come from the last checkpoint, not from when the app opens again.
- **Dates:** each phase keeps its own logical local completion date and UTC offset, as today. A partial phase's completion instant is the moment the user left (or the last checkpoint).
- **History and UI:** existing records stay as they are, with no data migration of old rows. There is no Statistics UI change. Partial time just adds to the existing daily totals, round counts and day details.

## Scope

Included: counting partial time and rounds, a single final write on leaving the timer, draft checkpoints and recovery after a forced close, the schema and query changes these need, and tests.

Excluded: restoring the timer itself after a forced close, marking partial rounds in the UI, changing preparation or pause rules, backup or sync.

## Acceptance criteria

- Leaving partway through a work or rest phase saves the whole seconds that phase actually ran. Completed phases before it keep their full durations.
- A partial work phase of 5 s or more adds one round. One shorter than 5 s adds its seconds but no round.
- Preparation and paused time never count. Leaving during preparation saves nothing, and the run does not appear in statistics.
- A finished timer is saved once, when the user leaves the page, with no duplicate rows.
- Final records are written once per run, no matter whether the user leaves while finished, running or paused. Retrying a failed write cannot double-count.
- After a forced close while training, the next app start saves the run up to its last checkpoint, under the account that started it. Recovery runs only once per draft.
- Activity keeps its logical local date, including a partial phase that crosses midnight.
- Daily totals, round counts, chart data and day details include partial time and follow the 5-second round rule. Existing history is unchanged.

## Tasks

1. [Count partial progress in whole seconds](01-count-partial-progress.md).
2. [Save the run once when leaving the timer](02-save-on-leaving-timer.md).
3. [Checkpoint the run and recover it after a forced close](03-checkpoint-and-recover.md).
4. [Verify partial recording end to end](04-verify-partial-recording.md).

## Dependencies and open decisions

Builds on the completed [recording story](../done/01-record-activity/index.md). Check its availability in the implementation checkout. Coordinate with [Delete statistics](../05-delete-statistics/index.md) and the developer purge in [developer tools](../../../developer-tools/index.md): deleting or purging history must also remove pending drafts, so a later recovery cannot bring deleted history back.

To settle during planning (recommendations, not agreed requirements):

- **Checkpoint moments:** recommended on each phase change, when the app goes to the background, and every ~10 s while running. The user accepted that the last few seconds can be lost after a kill. Only the final records are written on leaving.
- **Round rule for short configured rounds:** recommended that a work round that fully completes always counts, even if it is configured shorter than 5 s.
- **Storage shape:** how a draft is stored (a draft table, or session rows marked as unfinished) and how the round rule reaches the queries (a stored flag, or a duration condition in SQL). The choice must use a non-destructive migration.
