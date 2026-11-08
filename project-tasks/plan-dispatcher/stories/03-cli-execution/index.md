# STORY 3: CLI execution and reviewed publication

Epic: [PlanDispatcher](../../index.md)

## User outcome

Own one resumable task lifecycle from isolated preparation through checked publication and cleanup.

## Scope

- Prepare external workspaces, runtimes and preflight.
- Implement the Claude CLI stage adapter.
- Implement the Codex CLI stage adapter.
- Implement the Antigravity CLI stage adapter.
- Run and resume the worker/check/review lifecycle.
- Assemble reviewed publication, archiving and cleanup.

Each task owns one implementation responsibility and its tests. No application feature is added. The [epic contracts](../../contracts.md) supply shared interfaces/error semantics; consumers must not privately redesign them.

## Acceptance criteria

- R1: Project-local installation is proved by the owning task checks below.
- R3: Pinned restoration/explicit updates is proved by the owning task checks below.
- R6: Scoped model recommendations is proved by the owning task checks below.
- R7: Shared CLI execution and preflight is proved by the owning task checks below.
- R8: Isolated workspace and reservations is proved by the owning task checks below.
- R9: Worker/test/review and bounded repairs is proved by the owning task checks below.
- R10: Configured checker modes and trust is proved by the owning task checks below.
- R12: Exact-reviewed publication and idempotence is proved by the owning task checks below.
- R13: Blocked retention/resume/adoption is proved by the owning task checks below.
- R14: Successful cleanup and safe ownership is proved by the owning task checks below.
- R18: Pinned adoption/framework-neutral proof is proved by the owning task checks below.

## Tasks

1. [PLD-03-01: Prepare external workspaces, runtimes and preflight](01-prepare-workspaces/index.md).
2. [PLD-03-02: Implement the Claude CLI stage adapter](02-claude-cli-adapter/index.md).
3. [PLD-03-03: Implement the Codex CLI stage adapter](03-codex-cli-adapter/index.md).
4. [PLD-03-04: Implement the Antigravity CLI stage adapter](04-antigravity-cli-adapter/index.md).
5. [PLD-03-05: Run and resume the worker/check/review lifecycle](05-task-lifecycle/index.md).
6. [PLD-03-06: Assemble reviewed publication, archiving and cleanup](06-publish-and-cleanup/index.md).

## Dependencies and open decisions

No product decision is intentionally left open. Dependencies are the explicit fixed-contract task IDs in each file; unmerged prerequisites defer execution, not specification. Task status remains draft until its independent cold read is resolved. Executor routing and any exclusive/cross-repository boundary are part of each task's contract.

## Shared contracts

Consume [the epic contracts](../../contracts.md), especially the fixed public package interfaces and schema 1. Source and test locations are planned there. The task table below assigns contributions and checks; late assembly is intentional, never a reason to wire a block early.

PLD-03-05 owns the phases, `pd start`/`pd resume` and the engine stage prompts, and stops at `pending_publication` while its `candidate`/`publish`/`cleanup` ports are `None`. PLD-03-06 fills those ports and owns the framework-neutral fixture flow. There is no `pd run` command. Which stage outcomes repair and which block is decided once, in PLD-03-05 "Stage outcome rules"; PLD-03-06 only raises the codes. The same scope rule (task `touches` plus the engine-owned task folder and parent index) is used in the `checking` phase and in the candidate step.


## Requirement coverage

| Requirement | Owning task | Check |
| --- | --- | --- |
| R1: Project-local installation | [PLD-03-01](01-prepare-workspaces/index.md) | Its acceptance cases and literal commands in Files and tests |
| R3: Pinned restoration/explicit updates | [PLD-03-01](01-prepare-workspaces/index.md) | Its acceptance cases and literal commands in Files and tests |
| R7: Shared CLI execution and preflight | [PLD-03-01](01-prepare-workspaces/index.md) | Its acceptance cases and literal commands in Files and tests |
| R8: Isolated workspace and reservations | [PLD-03-01](01-prepare-workspaces/index.md) | Its acceptance cases and literal commands in Files and tests |
| R13: Blocked retention/resume/adoption | [PLD-03-01](01-prepare-workspaces/index.md) | Its acceptance cases and literal commands in Files and tests |
| R7: Shared CLI execution and preflight | [PLD-03-02](02-claude-cli-adapter/index.md) | Its acceptance cases and literal commands in Files and tests |
| R9: Worker/test/review and bounded repairs | [PLD-03-02](02-claude-cli-adapter/index.md) | Its acceptance cases and literal commands in Files and tests |
| R10: Configured checker modes and trust | [PLD-03-02](02-claude-cli-adapter/index.md) | Its acceptance cases and literal commands in Files and tests |
| R7: Shared CLI execution and preflight | [PLD-03-03](03-codex-cli-adapter/index.md) | Its acceptance cases and literal commands in Files and tests |
| R9: Worker/test/review and bounded repairs | [PLD-03-03](03-codex-cli-adapter/index.md) | Its acceptance cases and literal commands in Files and tests |
| R10: Configured checker modes and trust | [PLD-03-03](03-codex-cli-adapter/index.md) | Its acceptance cases and literal commands in Files and tests |
| R7: Shared CLI execution and preflight | [PLD-03-04](04-antigravity-cli-adapter/index.md) | Its acceptance cases and literal commands in Files and tests |
| R9: Worker/test/review and bounded repairs | [PLD-03-04](04-antigravity-cli-adapter/index.md) | Its acceptance cases and literal commands in Files and tests |
| R10: Configured checker modes and trust | [PLD-03-04](04-antigravity-cli-adapter/index.md) | Its acceptance cases and literal commands in Files and tests |
| R6: Scoped model recommendations | [PLD-03-05](05-task-lifecycle/index.md) | Its acceptance cases and literal commands in Files and tests |
| R7: Shared CLI execution and preflight | [PLD-03-05](05-task-lifecycle/index.md) | Its acceptance cases and literal commands in Files and tests |
| R9: Worker/test/review and bounded repairs | [PLD-03-05](05-task-lifecycle/index.md) | Its acceptance cases and literal commands in Files and tests |
| R12: Exact-reviewed publication and idempotence | [PLD-03-05](05-task-lifecycle/index.md) | Its acceptance cases and literal commands in Files and tests |
| R13: Blocked retention/resume/adoption | [PLD-03-05](05-task-lifecycle/index.md) | Its acceptance cases and literal commands in Files and tests |
| R8: Isolated workspace and reservations | [PLD-03-06](06-publish-and-cleanup/index.md) | Its acceptance cases and literal commands in Files and tests |
| R9: Worker/test/review and bounded repairs | [PLD-03-06](06-publish-and-cleanup/index.md) | Its acceptance cases and literal commands in Files and tests |
| R12: Exact-reviewed publication and idempotence | [PLD-03-06](06-publish-and-cleanup/index.md) | Its acceptance cases and literal commands in Files and tests |
| R13: Blocked retention/resume/adoption | [PLD-03-06](06-publish-and-cleanup/index.md) | Its acceptance cases and literal commands in Files and tests |
| R14: Successful cleanup and safe ownership | [PLD-03-06](06-publish-and-cleanup/index.md) | Its acceptance cases and literal commands in Files and tests |
| R18: Pinned adoption/framework-neutral proof | [PLD-03-06](06-publish-and-cleanup/index.md) | Its acceptance cases and literal commands in Files and tests |
