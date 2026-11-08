# Proposed PlanDispatcher task split

Proposed epic: PlanDispatcher (`PLD`). Revised after the second Opus review: six stories and 20 tasks, separating updates from setup and fixing cutover ownership. The earlier 19-task shape was accepted subject to that review; this revision requires agreement. This file is an interview artifact, not the executable backlog. Acceptance approval, detailed task contracts, cold reads and final whole-plan review remain outstanding.

Shared proposed technical contracts: [design.md](design.md). Confirmed requirements and refinements: [planning.md](planning.md). Earlier independent findings and their disposition: [opus-early-review.md](opus-early-review.md). Later D43/D44 explicitly supersede native per-stage T3 execution/session requirements.

All package source initially lives under `tool/plan_dispatcher/`, with its own packaging metadata, tests and packaged workflow resources. All implementation tasks include their relevant tests. No app feature is changed. Dependency arrows below refer to fixed planned contracts; tasks do not become executable merely by being listed here.

## 1. Foundation

| Proposed task | Responsibility | Prerequisites |
| --- | --- | --- |
| PLD-01-01 | Add/document executor routing and canonical planned-task branches so the legacy dispatcher skips orchestrator/new-engine/handoff tasks; make the gate task itself legacy-compatible | None |
| PLD-01-02 | Create the dependency-free Python package, pd entry point, configuration/task readers, stable stage/check/runtime/GitHub interfaces, offline test entry point and Python CI | PLD-01-01 |
| PLD-01-03 | Implement ready-task eligibility, dependency/cycle checks, deterministic recommendations, GitHub read adapter, atomic same-checkout reservations and status/release behavior | PLD-01-02 |

Every later implementation task depends transitively on the legacy gate and carries its explicit executor marker. Before the new engine is usable, the existing orchestrator executes the explicitly planned Python work using named offline test commands. The gate updates the orchestrator's branch selection for local tasks, so busy detection recognizes task IDs. Do not broaden old allowlists on every launch or claim these tasks are runnable through the old Flutter-only roles.

## 2. Shared validation

| Proposed task | Responsibility | Prerequisites |
| --- | --- | --- |
| PLD-02-01 | Implement run-bound and developer checker modes, ordered command definitions, bounded file selection/mapping, added-line scans, optional groups, evidence and scope checks | PLD-01-02 |
| PLD-02-02 | Express Sport Timer's validator behavior as consumer-owned configuration and shared old/new parity fixtures outside the extractable package; do not remove it yet | PLD-02-01 |

The generic checker remains framework-independent. Sport Timer's mappings/commands belong in consumer configuration. Preserve accepted D39 rather than silently adopting the earlier suggestion to keep the Dart validator permanently. Define the complete checker rule inventory before implementation: command ordering, include/exclude and prefix/suffix mapping, existing-file filtering, explicit files, build groups, and failure/advisory added-line scans. Both Dart/Python tests read the same consumer-owned case table during parity; no unimplemented Dart dry-run API is assumed.

## 3. Execution

| Proposed task | Responsibility | Prerequisites |
| --- | --- | --- |
| PLD-03-01 | Prepare external engine-owned clones/branches/runtime and approved setup; implement doctor/auth/identity preflight and canonical Git-common state; retain failures without touching the active checkout | PLD-01-03, PLD-02-01 |
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
| PLD-04-01 | Package the portable planner/task contract and own planning-clone preparation plus read-only interview/cold-review commands using shared CLI adapters | PLD-03-01, PLD-03-02, PLD-03-03, PLD-03-04 |
| PLD-04-02 | Package the thin dispatcher skill and implement environment/CLI selection, configured/available model recommendations/overrides and one-task-per-thread interaction | PLD-01-03, PLD-03-06, PLD-04-01 |
| PLD-04-03 | Implement project-only setup/integrations/restore from local source or a pinned release, confirmed command configuration, default-all/subset selection and managed-file ownership | PLD-03-01, PLD-04-01, PLD-04-02 |
| PLD-04-04 | Implement explicit updates with active-run/version checks, modified-file protection and atomic rollback | PLD-04-03 |

Planner/dispatcher assets are developed as package resources before replacing the live Sport Timer skills. Planner preparation/reviews do not depend on task publishing. Installation offers the already-agreed default of Claude/Codex/Antigravity, without installing those applications or editing global settings. The installer assembles the runtime/cache protocol defined earlier and preserves unrelated project files; update rollback is a separate bounded task.

## 5. Sport Timer cutover

| Proposed task | Responsibility | Prerequisites |
| --- | --- | --- |
| PLD-05-01 | Atomically install portable skills/local package, retire the Dart dispatcher/synchronizer/models and corresponding obsolete tests, update AI-setup assertions and preserve project-owned guidance/task-format pointers | PLD-02-02, PLD-04-04 |
| PLD-05-02 | Exclusively move the backlog to `docs/tasks/`, preserve content and repair readers/links/scopes; archive this self-moving task at its new root | PLD-05-01 |
| PLD-05-03 | Retire only the Dart validator after parity, switch developer consumers to pd check and run the planned live Codex fixture smoke | PLD-05-02 |

The temporary local-source configuration allows the old backlog root until its atomic move. Existing long-format tasks remain readable; the move does not approve drafts or erase their requirements. The package owns the canonical task-format asset; the local rule is a pointer, not a second definition. Sport Timer-specific guidance lives outside managed skill folders. Every cutover PR must keep the app and tests working; do not leave old role files inside newly managed folders.

PLD-05-02 is orchestrator-only and requires no active or blocked task runs because it changes the root used for archives. It updates pending PLD links/scopes and archives itself under docs/tasks. PLD-05-03 can use the new engine; its separate live Codex worker/reviewer fixture uses local Git/fake GitHub and does not claim live verification of absent providers.

## 6. Extraction and distribution

| Proposed task | Responsibility | Prerequisites |
| --- | --- | --- |
| PLD-06-01 | Non-dispatchable agent-operated handoff: create public MIT alexaniko88/plan-dispatcher with fresh initial commit, transfer generic sources/notices, set up CI/release and archive the handoff in a Sport Timer completion PR | PLD-05-03 |
| PLD-06-02 | Adopt the exact release in Sport Timer, remove temporary sources only after restoration succeeds and verify a temporary non-Flutter consumer installation | PLD-06-01 |

These tasks explicitly name their source and destination repositories. Creation/first publication is an agent-operated cross-repository handoff with its own authorization checkpoint under the applicable Git rules, not hidden work inside a repo-only task worker. No source history is transferred. PLD-06-01 completes through its Sport Timer archive PR recording the immutable release; merging that PR unblocks PLD-06-02. The user should not perform manual branch/filesystem housekeeping. Consumer adoption has rollback to the known-good local version and preserves the backlog. The second consumer is temporary and removed after verification.

## Command and port ownership

| Interface | Owner | Consumers |
| --- | --- | --- |
| pd entry point; config/task/stage/check/runtime/GitHub schemas; offline test runner | PLD-01-02 | All Python tasks |
| pd next/status/release; GitHub read adapter; repository reservation lock | PLD-01-03 | Workspace/lifecycle/dispatcher skill |
| pd check developer/run modes; file selection/scans/groups | PLD-02-01 | Worker/lifecycle/planner/consumer tools |
| Sport Timer parity cases/config outside generic package | PLD-02-02 | Cutover/validator retirement |
| pd doctor; auth/identity/capability preflight; external clones/runtime/cache protocol | PLD-03-01 | Lifecycle/planner prepare/installer |
| CLI describe/invoke/normalize/denial contracts | PLD-03-02/03/04 respectively | Doctor/lifecycle/planner reviews/model availability |
| pd start/run/resume/adopt; candidate/fix/review state and authorization | PLD-03-05 | Publication assembly/dispatcher skill |
| pd cleanup; Git/GitHub writes; archive, candidate-finalization and full lifecycle wiring | PLD-03-06 | Dispatcher/install/cutover |
| pd plan prepare/review; canonical task format and planner assets | PLD-04-01 | Planner and local task-format pointer |
| Provider/model recommendation policy, override handling and dispatcher assets | PLD-04-02 | Skill coordinator/launch |
| Setup, managed integrations, local-source and pinned-release install/restore | PLD-04-03 | Sport Timer cutover/released adoption |
| pd update and transactional rollback | PLD-04-04 | Installed consumers |

## Executor ownership

- PLD-01-01: legacy-compatible dispatcher task (or explicitly invoked orchestrator).
- PLD-01-02 through PLD-04-04: orchestrator, with exact offline Python commands and canonical task branches; legacy dispatcher skips them.
- PLD-05-01: orchestrator, because it replaces the running workflow assets/old engine.
- PLD-05-02: orchestrator, exclusive backlog-root migration with no active/blocked runs.
- PLD-05-03: plan-dispatcher-v1, with prepared live Codex fixture verification.
- PLD-06-01: handoff, never auto-selected by either dispatcher; separate source completion PR.
- PLD-06-02: orchestrator, because removing the local engine source and switching distribution must not delete its own running engine/version context.

## Proposed acceptance topics for the next approval

Expose the following before treating the design as fully agreed: default deterministic task order; two total fresh repair invocations; same-checkout/single-machine reservation visibility; no automatic stale-lock takeover; no unsupported-model substitution; checker parity and frozen configuration; final reviewed/pushed SHA equality; blocked local retention and successful clone cleanup; cleanup failure as publication success with warning; local Python installation/cache restoration; project-only pinned updates; exact extraction/reinstall boundary; and deterministic non-Flutter proof versus separately reported live CLI smoke evidence.

The final review requested under D41 applies after the detailed executable tasks and their cold reads exist. The current additional Opus review checks this proposed split before those files are written.
