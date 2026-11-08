# STORY 5: Sport Timer cutover

Epic: [PlanDispatcher](../../index.md)

## User outcome

Replace live consumers atomically, preserve the backlog and retire the old tools only after proof.

## Scope

- Switch Sport Timer workflows and retire the old runner atomically.
- Move the preserved backlog to docs/tasks.
- Retire the Dart validator after parity and live CLI proof.

Each task owns one implementation responsibility and its tests. No application feature is added. The [epic contracts](../../contracts.md) supply shared interfaces/error semantics; consumers must not privately redesign them.

## Acceptance criteria

- R1: Project-local installation is proved by the owning task checks below.
- R4: Safe eligible-task selection is proved by the owning task checks below.
- R7: Shared CLI execution and preflight is proved by the owning task checks below.
- R10: Configured checker modes and trust is proved by the owning task checks below.
- R11: Sport Timer checker parity is proved by the owning task checks below.
- R13: Blocked retention/resume/adoption is proved by the owning task checks below.
- R15: Portable planner preparation is proved by the owning task checks below.
- R16: Compatible consumer cutover is proved by the owning task checks below.
- R18: Pinned adoption/framework-neutral proof is proved by the owning task checks below.

## Tasks

1. [PLD-05-01: Switch Sport Timer workflows and retire the old runner atomically](01-switch-workflow-engine/index.md).
2. [PLD-05-02: Move the preserved backlog to docs/tasks](02-move-task-backlog/index.md).
3. [PLD-05-03: Retire the Dart validator after parity and live CLI proof](03-retire-dart-validator/index.md).

## Dependencies and open decisions

No product decision is intentionally left open. Dependencies are the explicit fixed-contract task IDs in each file; unmerged prerequisites defer execution, not specification. Task status remains draft until its independent cold read is resolved. Executor routing and any exclusive/cross-repository boundary are part of each task's contract.

## Shared contracts

Consume [the epic contracts](../../contracts.md), especially the fixed public package interfaces and schema 1. Source and test locations are planned there. The task table below assigns contributions and checks; late assembly is intentional, never a reason to wire a block early.

- All three tasks run through `skill-orchestrator` with the user present (`executor: orchestrator`). None runs while a dispatcher run is active.
- PLD-05-01 deletes the old skill folders, installs the packaged skills from the local source, moves Sport Timer guidance to `.agents/references/plan-dispatcher-project.md` (listed in `instructions.paths`), and retires the old runner, synchronizer, their tests and `docs/task-automation.md` in one PR. `tool/agent_check.dart` stays.
- PLD-05-02 moves `project-tasks/` to `docs/tasks/` only when `pd status` lists no runs, adds the permanent `test/tool/test_backlog_integrity.py`, and archives itself at the new root.
- PLD-05-03 runs the live Codex smoke and parity first; only when both pass does it delete `tool/agent_check.dart` and its tests, point the developer docs to `pd check`, and rewrite the validator command in the six pending tasks of other epics that still name it. It also sets `executor: plan-dispatcher-v1` on the eight existing ready Sport Timer tasks (D56), returns any that fail `--check-ready` to `draft`, and runs `pd update` because it edits the package (contracts package-edit rule).

## Requirement coverage

| Requirement | Owning task | Check |
| --- | --- | --- |
| R1: Project-local installation | [PLD-05-01](01-switch-workflow-engine/index.md) | second installer run prints `unchanged`; `plan-dispatcher install` group in `ai_setup_test.dart` |
| R7: Shared CLI execution and preflight | [PLD-05-01](01-switch-workflow-engine/index.md), [PLD-05-03](03-retire-dart-validator/index.md) | `pd doctor --json`; `live_codex_smoke.py` exit 0 with `sandbox_check.ok` (cache and network route inside the Codex sandbox) |
| R10: Configured checker modes and trust | [PLD-05-03](03-retire-dart-validator/index.md) | `pd check` and `pd check --skip-build CLAUDE.md` |
| R11: Sport Timer checker parity | [PLD-05-03](03-retire-dart-validator/index.md) | `test/tool/test_plan_dispatcher_parity.py` before and after deletion |
| R13: Blocked retention/resume/adoption | [PLD-05-02](02-move-task-backlog/index.md) | `pd status --json` precondition recorded in `notes.md` |
| R4: Safe eligible-task selection | [PLD-05-02](02-move-task-backlog/index.md), [PLD-05-03](03-retire-dart-validator/index.md) | working-tree `test_backlog_integrity.py` loads tasks from `docs/tasks/`; `--check-ready` exit 0 after the ready tasks move to `plan-dispatcher-v1` |
| R15: Portable planner preparation | [PLD-05-01](01-switch-workflow-engine/index.md) | task-format pointer test and `instructions.paths` test in `ai_setup_test.dart` |
| R16: Compatible consumer cutover | [PLD-05-01](01-switch-workflow-engine/index.md), [PLD-05-02](02-move-task-backlog/index.md), [PLD-05-03](03-retire-dart-validator/index.md) | `git grep` reference scans, `test_backlog_integrity.py --compare-ref <merge base>` (also in CI), `pd update` reporting `unchanged` and `pd doctor` without `artifact_stale` after PLD-05-03, `fvm flutter test` in each PR |
| R18: Pinned adoption/framework-neutral proof | [PLD-05-03](03-retire-dart-validator/index.md) | live smoke on the framework-neutral fixture plus the sandboxed real-project check; release adoption itself is PLD-06-02 |

The combined cutover is verified by PLD-05-03's final command block.
