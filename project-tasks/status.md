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
- **Templates:** 2 of 8 tasks done; 0 in progress; 1 ready; 2 blocked; 3 provisional.
- **Bugs:** 0 tasks reported.
- **Improvements:** 0 of 2 tasks done; both provisional.
- **Available to reuse:** Templates 1.2 `TemplateTile` on `feat/template-tile`; Templates 1.1 data, total-time calculation and en/es names on `feat/templates-feature`; verify availability in the intended checkout. No statistics implementation completed yet.
- **Next tasks:** Statistics 1.1 — verify Serverpod local integration and approve the data model. Templates 1.3 — rebuild the Templates page where Task 1.2 is available. The two epics are independent.

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

## Templates

Epic: [Templates](templates/index.md).

| Task | Status | Prerequisite or reason | Output when done |
| --- | --- | --- | --- |
| [1.1 Move templates into a feature folder](templates/stories/01-template-set-and-tiles/done/01-move-templates-to-feature.md) | ✅ Done | Checks pass; user approved delivery 2026-10-31. Available on `feat/templates-feature`. | The 5 templates as data, total-time calculation, en/es names. |
| [1.2 Build the compact template tile](templates/stories/01-template-set-and-tiles/done/02-build-template-tile.md) | ✅ Done | Task 1.1. | Reusable compact tile with summary, total time and phase bar. |
| [1.3 Rebuild the Templates page](templates/stories/01-template-set-and-tiles/03-rebuild-templates-page.md) | 🟢 Ready | Task 1.2 on `feat/template-tile`; verify it is merged or the checkout has it. | New Templates tab; tap applies the template. |
| [2.1 Add a templates view model](templates/stories/02-selection-follows-settings/01-add-templates-view-model.md) | 🔴 Blocked | Story 1 completed. | Computed selected template or custom, with tests. |
| [2.2 Show the selection and the Custom card](templates/stories/02-selection-follows-settings/02-show-selection-and-custom-card.md) | 🔴 Blocked | Task 2.1. | Highlighted row and visual-only Custom card. |
| [3.1 Confirm the creation behavior](templates/stories/03-create-own-templates/01-confirm-creation-behavior.md) | ⚪ Provisional | Revisit Story 3 after Stories 1 and 2. | Agreed creation, edit, delete and storage decisions. |
| [3.2 Store custom templates](templates/stories/03-create-own-templates/02-store-custom-templates.md) | ⚪ Provisional | Story 3 agreement and Task 3.1. | Repository for own templates. |
| [3.3 Add the creation flow](templates/stories/03-create-own-templates/03-add-creation-flow.md) | ⚪ Provisional | Story 3 agreement and Task 3.2. | "+" action and creation flow. |

## Bugs

Folder: [Bugs](bugs/index.md). Only bug tasks belong here. None reported yet; add a linked row with status, dependencies/blockers, and intended result when a report is created.

## Improvements

Folder: [Improvements](improvements/index.md). Only improvement tasks belong here.

| Task | Status | Prerequisite or reason | Output when done |
| --- | --- | --- | --- |
| [IMP-01 Unify styles across the app](improvements/01-unify-styles-app-wide.md) | ⚪ Provisional | Best after Templates Story 1; scope to be agreed. | Consistent look across screens. |
| [IMP-02 Rethink the navigation drawer](improvements/02-rethink-navigation-drawer.md) | ⚪ Provisional | Direction to be agreed. | Agreed role for the drawer. |

## Active work and handoff

No implementation in progress. Templates 1.2 is complete on branch `feat/template-tile` (worktree `.worktrees/template-tile`, base `397403b`), PR #11 open. No next task started.

When work starts, record the task, the actual branch if applicable, approved plan location, completed substeps, remaining work, checks run, and blockers. Use repository-relative paths and branch/commit identifiers rather than machine-specific absolute paths. This section must be enough for another session to resume safely.

## Completed tasks and reusable outputs

- Templates 1.1, completed 2026-10-31: [task](templates/stories/01-template-set-and-tiles/done/01-move-templates-to-feature.md). Built-in data in [built_in_templates.dart](../lib/features/templates/built_in_templates.dart); shared calculation in [workout_template.dart](../lib/features/templates/workout_template.dart); English/Spanish names in `lib/l10n/`. Existing page consumes feature data.
- Approved plan completed: plain feature model and five constants; minimal existing-page integration; localized names and unused-key cleanup; focused tests; review and handoff checks. Per-template accents replaced with an existing shared color; descriptions removed; layout and last-tap selection retained. User requested removal of redundant memory/plan files; this tracker retains the handoff.
- Evidence: 5 tests pass across both `test/features/templates/` files; touched-file and full analysis clean; changed Dart formatting and shared `verify-branch.sh master` pass. Independent review: no findings. No added TODO/FIXME, personal absolute paths, dependency or platform changes. User approved delivery, commit, push and PR on 2026-10-31.
- Location: branch `feat/templates-feature`, worktree `.worktrees/templates-feature`. Available on this branch; Done does not imply merged into `master`. Task 1.2 is ready where this output exists. Existing large cards and last-tap selection remain until later tasks.

For each completed task, record its identifier/link, completion date, delivered result, relevant file/decision links, validation results, known limits, and where the work exists (branch, commit, or uncommitted checkout). For research, link the approved decision rather than implying feature code exists.

- Templates 1.2, completed 2026-10-31: [task](templates/stories/01-template-set-and-tiles/done/02-build-template-tile.md). `TemplateTile` in `lib/presentation/widgets/template_tile.dart` (name, icon, settings, totalTime, isSelected, isCustom, optional onTap), phase bar of alternating preparation/round/rest segments, `templateTileSummary` and `templateTileSemantics` in en/es. Location: branch `feat/template-tile`, PR #11 open (not merged); task file archived under `done/`. Page still uses old cards; old strings removed in Task 1.3.
- Evidence: 18 tests pass (tile tests plus `test/l10n`); full `fvm flutter analyze` clean; independent review: no critical findings, semantics tap action, border size shift and context reads fixed. Known limits: `totalTime` is passed in by the caller; `isCustom` has a basic outlined style to refine in Story 2; duration formatter duplicates the page one until Task 1.3.

## Maintenance

- Use this file as the shared execution-status summary. Task/story files retain detailed scope and acceptance criteria; keep any repeated status consistent.
- Before implementation, check dependencies and confirm completed outputs exist in the current checkout or intended branch. A Done row alone is not proof the code is available here.
- Mark In progress when actual work starts, and preserve a useful handoff whenever work stops before completion.
- Mark Done only after meeting the task's acceptance criteria and relevant checks, including required user validation. Record the evidence in the same update.
- After completion, reevaluate dependent rows, update the overview and next task, and state which outputs can now be reused. Do not automatically start another task.
- Record a real blocker if a dependency, decision, or failed check prevents progress. Leave unapproved future scope Provisional.
- Update this tracker when tasks are added, moved, split, or removed, preserving valid links and completion history.