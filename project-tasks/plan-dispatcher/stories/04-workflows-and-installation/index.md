# STORY 4: Portable workflows and project installation

Epic: [PlanDispatcher](../../index.md)

## User outcome

Ship the planner/dispatcher skills and project-only install/restore/update experience.

## Scope

- Package the portable planner and planning review commands.
- Package the thin dispatcher and execution recommendations.
- Install project-local workflows and restore pinned runtimes.
- Update managed workflows transactionally.

Each task owns one implementation responsibility and its tests. No application feature is added. The [epic contracts](../../contracts.md) supply shared interfaces/error semantics; consumers must not privately redesign them.

## Acceptance criteria

- R1: Project-local installation is proved by the owning task checks below.
- R2: Confirmed tooling/no improvised helpers is proved by the owning task checks below.
- R3: Pinned restoration/explicit updates is proved by the owning task checks below.
- R4: Safe eligible-task selection is proved by the owning task checks below.
- R5: Task recommendation/launch approval is proved by the owning task checks below.
- R6: Scoped model recommendations is proved by the owning task checks below.
- R7: Shared CLI execution and preflight is proved by the owning task checks below.
- R9: Worker/test/review and bounded repairs is proved by the owning task checks below.
- R13: Blocked retention/resume/adoption is proved by the owning task checks below.
- R15: Portable planner preparation is proved by the owning task checks below.

## Tasks

1. [PLD-04-01: Package the portable planner and planning review commands](01-portable-planner/index.md).
2. [PLD-04-02: Package the thin dispatcher and execution recommendations](02-portable-dispatcher/index.md).
3. [PLD-04-03: Install project-local workflows and restore pinned runtimes](03-project-installation/index.md).
4. [PLD-04-04: Update managed workflows transactionally](04-explicit-updates/index.md).

## Dependencies and open decisions

No product decision is intentionally left open. Dependencies are the explicit fixed-contract task IDs in each file; unmerged prerequisites defer execution, not specification. Task status remains draft until its independent cold read is resolved. Executor routing and any exclusive/cross-repository boundary are part of each task's contract.

## Shared contracts

R6 (model recommendations) is owned by PLD-04-02 here and by PLD-03-05 in story 3, not by the planner task PLD-04-01. The packaged planner and dispatcher asset lists are fixed in PLD-04-01 and PLD-04-02; engine stage prompts belong to PLD-03-05. PLD-04-02 builds launch requests with `pd request`; there is no coordinator event state machine. All `pd plan` commands run from the active checkout and address the planning clone by plan id.

`install.commit(staging, phase_hook)` (PLD-04-03) is the only backup, replacement and removal mechanism; PLD-04-04 adds only the update journal through `phase_hook`. Wheels live in `artifacts/<version>-<digest12>/`. The packaged `references/task-format.md` (PLD-04-01) is the complete standalone task format that PLD-05-01 points the project rule at. `pd plan prepare` reads `cache_root` from the `ports` test seam, and `pd request --save-default-cli` is the only writer of `host.json`.

Consume [the epic contracts](../../contracts.md), especially the fixed public package interfaces and schema 1. Source and test locations are planned there. The task table below assigns contributions and checks; late assembly is intentional, never a reason to wire a block early.


## Requirement coverage

| Requirement | Owning task | Check |
| --- | --- | --- |
| R2: Confirmed tooling/no improvised helpers | [PLD-04-01](01-portable-planner/index.md) | `test_planner` |
| R7: Shared CLI execution and preflight | [PLD-04-01](01-portable-planner/index.md) | `test_planner` |
| R15: Portable planner preparation | [PLD-04-01](01-portable-planner/index.md) | `test_planner` |
| R4: Safe eligible-task selection | [PLD-04-02](02-portable-dispatcher/index.md) | `test_models`, `test_dispatcher_skill` |
| R5: Task recommendation/launch approval | [PLD-04-02](02-portable-dispatcher/index.md) | `test_models`, `test_dispatcher_skill` |
| R6: Scoped model recommendations | [PLD-04-02](02-portable-dispatcher/index.md) | `test_models`, `test_dispatcher_skill` |
| R7: Shared CLI execution and preflight | [PLD-04-02](02-portable-dispatcher/index.md) | `test_models`, `test_dispatcher_skill` |
| R9: Worker/test/review and bounded repairs | [PLD-04-02](02-portable-dispatcher/index.md) | `test_models`, `test_dispatcher_skill` |
| R1: Project-local installation | [PLD-04-03](03-project-installation/index.md) | `test_install`, `test_release_install` |
| R2: Confirmed tooling/no improvised helpers | [PLD-04-03](03-project-installation/index.md) | `test_install`, `test_release_install` |
| R3: Pinned restoration/explicit updates | [PLD-04-03](03-project-installation/index.md) | `test_install`, `test_release_install` |
| R7: Shared CLI execution and preflight | [PLD-04-03](03-project-installation/index.md) | `test_install`, `test_release_install` |
| R3: Pinned restoration/explicit updates | [PLD-04-04](04-explicit-updates/index.md) | `test_update` |
| R13: Blocked retention/resume/adoption | [PLD-04-04](04-explicit-updates/index.md) | `test_update` |
