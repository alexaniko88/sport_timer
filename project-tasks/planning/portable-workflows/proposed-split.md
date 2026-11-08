# Proposed PlanDispatcher task split

Proposed epic: PlanDispatcher (`PLD`). The user accepted this split subject to another fresh Opus review. This file is an interview artifact, not the executable backlog. Acceptance approval, detailed task contracts, cold reads and final whole-plan review remain outstanding.

Shared proposed technical contracts: [design.md](design.md). Confirmed requirements and refinements: [planning.md](planning.md). Earlier independent findings and their disposition: [opus-early-review.md](opus-early-review.md). Later D43/D44 explicitly supersede native per-stage T3 execution/session requirements.

All package source initially lives under `tool/plan_dispatcher/`, with its own packaging metadata, tests and packaged workflow resources. All implementation tasks include their relevant tests. No app feature is changed. Dependency arrows below refer to fixed planned contracts; tasks do not become executable merely by being listed here.

## 1. Foundation

| Proposed task | Responsibility | Prerequisites |
| --- | --- | --- |
| PLD-01-01 | Add a legacy executor gate so the old dispatcher skips tasks marked `executor: plan-dispatcher-v1`; make the gate task itself legacy-compatible | None |
| PLD-01-02 | Create the independent Python package, configuration/task models and readers, stable executor/result/check interfaces, packaging fixtures and Python CI | PLD-01-01 |
| PLD-01-03 | Implement ready-task eligibility, dependency/cycle checks, deterministic recommendations, atomic same-checkout reservations and status/release behavior | PLD-01-02 |

Every later implementation task depends transitively on the legacy gate and carries its new executor marker. Before the new engine is usable, the existing orchestrator executes the explicitly planned Python work. Do not broaden old allowlists on every launch or claim these tasks are runnable through the old Flutter-only roles.

## 2. Shared validation

| Proposed task | Responsibility | Prerequisites |
| --- | --- | --- |
| PLD-02-01 | Implement the shared Python checker, frozen approved command definitions, bounded file-selection/mapping rules, independent evidence and scope checks | PLD-01-02 |
| PLD-02-02 | Express Sport Timer's current validator behavior as project configuration and add parity fixtures against the existing Dart validator; do not remove it yet | PLD-02-01 |

The generic checker remains framework-independent. Sport Timer's mappings/commands belong in consumer configuration. Preserve accepted D39 rather than silently adopting the earlier suggestion to keep the Dart validator permanently.

## 3. Execution

| Proposed task | Responsibility | Prerequisites |
| --- | --- | --- |
| PLD-03-01 | Prepare engine-owned task clones, task branches, local runtime/artifact-cache inputs and approved setup; retain failures without touching the active checkout | PLD-01-03, PLD-02-01 |
| PLD-03-02 | Implement the Claude headless CLI adapter and its report/permission/timeout contract tests | PLD-01-02 |
| PLD-03-03 | Implement the Codex headless CLI adapter and its report/permission/timeout contract tests | PLD-01-02 |
| PLD-03-04 | Implement the Antigravity headless CLI adapter, including exit-zero soft-denial cases | PLD-01-02 |
| PLD-03-05 | Implement the single resumable worker/check/reviewer lifecycle, fresh repair workers, total repair budget, authorization/run binding and SHA-pinned gates | PLD-03-01, PLD-03-02, PLD-03-03, PLD-03-04 |
| PLD-03-06 | Assemble archive/candidate preparation, engine-owned commits, idempotent GitHub publication and successful cleanup; prove the whole lifecycle in a non-Flutter Git fixture | PLD-03-05 |

The package scaffold fixes the input/output contracts shared by adapters, lifecycle, runtime preparation and installer. Runtime preparation consumes a documented local wheel-cache manifest, also used by the later installer; it must be testable with local built artifacts before the installer UI exists.

The lifecycle block can end at a publication action until PLD-03-06 supplies its consumer. The assembly task owns all wiring and verifies the full flow. It must prepare task notes/archive/link changes before the final candidate is checked and reviewed. The pushed head must be exactly that candidate. Final reviewer results live in local reports/PR description, avoiding another tracked change after review.

CLI tests use fake executables and report fixtures. Live provider smoke runs are separate opt-in evidence, never implied by native T3 provider availability. Every invocation environment uses these same CLIs under D44.

## 4. Workflows and installation

| Proposed task | Responsibility | Prerequisites |
| --- | --- | --- |
| PLD-04-01 | Package the framework-independent planner, shorter task contract, interview/reference assets, visual design checkpoints and fresh independent planning review instructions | PLD-01-02, PLD-02-01, PLD-03-06 |
| PLD-04-02 | Package the thin dispatcher skill, environment/CLI selection, available-model recommendations/overrides and one-task-per-thread interaction | PLD-01-03, PLD-03-06, PLD-04-01 |
| PLD-04-03 | Implement project-only setup, confirmed command configuration, all-three/default subset skill integration, runtime restoration, managed-file ownership and explicit updates | PLD-03-01, PLD-04-01, PLD-04-02 |

Planner/dispatcher assets are developed as package resources before replacing the live Sport Timer skills. Installation offers the already-agreed default of Claude/Codex/Antigravity, without installing those applications or editing global settings. The installer assembles the runtime/cache protocol defined earlier and preserves unrelated project files.

## 5. Sport Timer cutover

| Proposed task | Responsibility | Prerequisites |
| --- | --- | --- |
| PLD-05-01 | Install/connect the local package and portable skills with Sport Timer configuration, preserving project-specific rules and architecture-check coverage | PLD-02-02, PLD-04-03 |
| PLD-05-02 | Move the existing backlog to `docs/tasks/`, preserve IDs/status/evidence/attachments and repair all readers, links, rules and tests in one compatible change | PLD-05-01 |
| PLD-05-03 | Retire the replaced Dart dispatcher/synchronizer/validator and their obsolete tests; update consumers/docs/CI without weakening retained checks | PLD-05-02 |

The temporary local-source configuration allows the old backlog root until its atomic move. Existing long-format tasks remain readable; the move does not approve drafts or erase their requirements. Any code/rule changes needed by the new skill assets must preserve a working app and test suite after each cutover PR.

## 6. Extraction and distribution

| Proposed task | Responsibility | Prerequisites |
| --- | --- | --- |
| PLD-06-01 | Agent-operated handoff: create public MIT `alexaniko88/plan-dispatcher`, extract generic sources/history/notices, set up Python CI and publish a verified initial tagged release | PLD-05-03 |
| PLD-06-02 | Adopt that exact release in Sport Timer, remove the temporary source subtree only after restoration succeeds, and verify a second non-Flutter consumer installation | PLD-06-01 |

These tasks explicitly name their source and destination repositories. Creation/first publication is an agent-operated cross-repository handoff with its own authorization checkpoint under the applicable Git rules, not hidden work inside a repo-only task worker. The user should not perform manual branch or filesystem housekeeping. Consumer adoption has rollback to the known-good local version and preserves the backlog.

## Proposed acceptance topics for the next approval

Expose the following before treating the design as fully agreed: default deterministic task order; two total fresh repair invocations; same-checkout/single-machine reservation visibility; no automatic stale-lock takeover; no unsupported-model substitution; checker parity and frozen configuration; final reviewed/pushed SHA equality; blocked local retention and successful clone cleanup; cleanup failure as publication success with warning; local Python installation/cache restoration; project-only pinned updates; exact extraction/reinstall boundary; and deterministic non-Flutter proof versus separately reported live CLI smoke evidence.

The final review requested under D41 applies after the detailed executable tasks and their cold reads exist. The current additional Opus review checks this proposed split before those files are written.
