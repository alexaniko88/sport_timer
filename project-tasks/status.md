# Project task status

This is the shared progress tracker for local task implementation. Read it before starting or resuming a task, together with its task file and applicable parent indexes: story/epic indexes for story tasks, or the Bugs/Improvements index for standalone tasks.

## Status meanings

| Status | Meaning |
| --- | --- |
| 🟢 Ready | Prerequisites are satisfied; ready for planning and the required approval. |
| 🟡 In progress | Work has actually started; read the handoff before continuing. |
| 🔴 Blocked | A dependency or decision prevents starting. The reason must be recorded. |
| ✅ Done | Acceptance criteria and relevant checks passed; completion evidence is recorded. |
| ⚪ Provisional | Future scope that still needs agreement before implementation. |

Ready does not mean implementation is already approved. Done does not imply committed, merged, deployed, or available in every checkout.

## Current overview

- **Statistics:** 0 of 12 tasks done; 0 in progress; 1 ready; 7 blocked; 4 provisional.
- **Bugs:** 0 tasks reported.
- **Improvements:** 0 tasks proposed.
- **Available to reuse:** no statistics implementation has been completed yet. The existing files describe planned capabilities only.
- **Next task:** Statistics 1.1 — verify Serverpod local integration and approve the data model.

## Statistics

Epic: [Statistics](statistics/index.md).

The output column describes the intended deliverable. It becomes available for reuse only after the task is Done and its evidence/location has been checked.

| Task | Status | Prerequisite or reason | Output when done |
| --- | --- | --- | --- |
| [1.1 Verify Serverpod integration](statistics/stories/01-record-activity/01-verify-serverpod-integration.md) | 🟢 Ready | None; research and decision task. | Approved integration approach and data model. |
| [1.2 Add database foundation](statistics/stories/01-record-activity/02-add-database-foundation.md) | 🔴 Blocked | Task 1.1. | Local database setup, models, generation, and migrations. |
| [1.3 Add activity repository](statistics/stories/01-record-activity/03-add-activity-repository.md) | 🔴 Blocked | Task 1.2. | Account-scoped persistence and daily queries. |
| [1.4 Connect timer recording](statistics/stories/01-record-activity/04-connect-timer-recording.md) | 🔴 Blocked | Task 1.3. | Automatic completed-phase recording. |
| [1.5 Verify recording](statistics/stories/01-record-activity/05-verify-recording.md) | 🔴 Blocked | Task 1.4; verify Story 1 criteria. | Verified recording integration and documented platform limits. |
| [2.1 Add daily statistics state](statistics/stories/02-daily-list/01-add-daily-statistics-state.md) | 🔴 Blocked | Story 1 completed. | Daily summary state and refresh handling. |
| [2.2 Show daily tiles](statistics/stories/02-daily-list/02-show-daily-tiles.md) | 🔴 Blocked | Task 2.1. | Daily history list and screen states. |
| [2.3 Verify daily statistics](statistics/stories/02-daily-list/03-verify-daily-statistics.md) | 🔴 Blocked | Task 2.2; verify Story 2 criteria. | Verified daily summary and UI behavior. |
| [3.1 Confirm day details](statistics/stories/03-day-details/01-confirm-day-details.md) | ⚪ Provisional | Revisit Story 3 after Stories 1 and 2. | Agreed day-detail behavior and layout. |
| [3.2 Query day activity](statistics/stories/03-day-details/02-query-day-activity.md) | ⚪ Provisional | Story 3 agreement and Task 3.1. | Selected-day activity grouped by run. |
| [3.3 Show day details](statistics/stories/03-day-details/03-show-day-details.md) | ⚪ Provisional | Story 3 agreement and Task 3.2. | Day-detail navigation and view. |
| [3.4 Verify day details](statistics/stories/03-day-details/04-verify-day-details.md) | ⚪ Provisional | Story 3 agreement and Task 3.3. | Verified day-detail behavior. |

## Bugs

Folder: [Bugs](bugs/index.md). Only bug tasks belong here. None reported yet; add a linked row with status, dependencies/blockers, and intended result when a report is created.

## Improvements

Folder: [Improvements](improvements/index.md). Only improvement tasks belong here. None proposed yet; add a linked row with status, dependencies/blockers, and intended result when a task is created.

## Active work and handoff

None. No task implementation has started.

When work starts, record the task, actual branch/worktree if applicable, approved plan location, completed substeps, remaining work, checks run, and blockers. Use repository-relative paths and branch/commit identifiers rather than machine-specific absolute paths. This section must be enough for another session to resume safely.

## Completed tasks and reusable outputs

None yet.

For each completed task, record its identifier/link, completion date, delivered result, relevant file/decision links, validation results, known limits, and where the work exists (branch, commit, or uncommitted checkout). For research, link the approved decision rather than implying feature code exists.

## Maintenance

- Use this file as the shared execution-status summary. Task/story files retain detailed scope and acceptance criteria; keep any repeated status consistent.
- Before implementation, check dependencies and confirm completed outputs exist in the current checkout or intended worktree. A Done row alone is not proof the code is available here.
- Mark In progress when actual work starts, and preserve a useful handoff whenever work stops before completion.
- Mark Done only after meeting the task's acceptance criteria and relevant checks, including required user validation. Record the evidence in the same update.
- After completion, reevaluate dependent rows, update the overview and next task, and state which outputs can now be reused. Do not automatically start another task.
- Record a real blocker if a dependency, decision, or failed check prevents progress. Leave unapproved future scope Provisional.
- Update this tracker when tasks are added, moved, split, or removed, preserving valid links and completion history.
