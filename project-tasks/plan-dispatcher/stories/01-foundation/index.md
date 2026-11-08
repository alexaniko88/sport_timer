# STORY 1: Foundation and task eligibility

Epic: [PlanDispatcher](../../index.md)

## User outcome

Provide a tested package/task contract and route work only to executors that can run it.

## Scope

- Route planned tasks to a compatible executor.
- Bootstrap the independent Python package and contracts.
- Select eligible tasks and reserve their scope atomically.

Each task owns one implementation responsibility and its tests. No application feature is added. The [epic contracts](../../contracts.md) supply shared interfaces/error semantics; consumers must not privately redesign them.

## Acceptance criteria

- R1: Project-local installation is proved by the owning task checks below.
- R4: Safe eligible-task selection is proved by the owning task checks below.
- R5: Task recommendation/launch approval is proved by the owning task checks below.
- R7: Shared CLI execution and preflight is proved by the owning task checks below.
- R8: Isolated workspace and reservations is proved by the owning task checks below.
- R13: Blocked retention/resume/adoption is proved by the owning task checks below.
- R14: Successful cleanup and safe ownership is proved by the owning task checks below.
- R15: Portable planner preparation is proved by the owning task checks below.
- R16: Compatible consumer cutover is proved by the owning task checks below.

## Tasks

1. [PLD-01-01: Route planned tasks to a compatible executor](01-route-task-executors/index.md).
2. [PLD-01-02: Bootstrap the independent Python package and contracts](02-bootstrap-python-package/index.md).
3. [PLD-01-03: Select eligible tasks and reserve their scope atomically](03-select-and-reserve-tasks/index.md).

## Dependencies and open decisions

No product decision is intentionally left open. Dependencies are the explicit fixed-contract task IDs in each file; unmerged prerequisites defer execution, not specification. Task status remains draft until its independent cold read is resolved. Executor routing and any exclusive/cross-repository boundary are part of each task's contract.

## Shared contracts

Consume [the epic contracts](../../contracts.md), especially the fixed public package interfaces and schema 1. Source and test locations are planned there. The task table below assigns contributions and checks; late assembly is intentional, never a reason to wire a block early.


## Requirement coverage

| Requirement | Owning task | Check |
| --- | --- | --- |
| R4: Safe eligible-task selection | [PLD-01-01](01-route-task-executors/index.md) | Its acceptance cases and literal commands in Files and tests |
| R8: Isolated workspace and reservations | [PLD-01-01](01-route-task-executors/index.md) | Its acceptance cases and literal commands in Files and tests |
| R16: Compatible consumer cutover | [PLD-01-01](01-route-task-executors/index.md) | Its acceptance cases and literal commands in Files and tests |
| R1: Project-local installation | [PLD-01-02](02-bootstrap-python-package/index.md) | Its acceptance cases and literal commands in Files and tests |
| R7: Shared CLI execution and preflight | [PLD-01-02](02-bootstrap-python-package/index.md) | Its acceptance cases and literal commands in Files and tests |
| R15: Portable planner preparation | [PLD-01-02](02-bootstrap-python-package/index.md) | Its acceptance cases and literal commands in Files and tests |
| R16: Compatible consumer cutover | [PLD-01-02](02-bootstrap-python-package/index.md) | Its acceptance cases and literal commands in Files and tests |
| R4: Safe eligible-task selection | [PLD-01-03](03-select-and-reserve-tasks/index.md) | Its acceptance cases and literal commands in Files and tests |
| R5: Task recommendation/launch approval | [PLD-01-03](03-select-and-reserve-tasks/index.md) | Its acceptance cases and literal commands in Files and tests |
| R8: Isolated workspace and reservations | [PLD-01-03](03-select-and-reserve-tasks/index.md) | Its acceptance cases and literal commands in Files and tests |
| R13: Blocked retention/resume/adoption | [PLD-01-03](03-select-and-reserve-tasks/index.md) | Its acceptance cases and literal commands in Files and tests |
| R14: Successful cleanup and safe ownership | [PLD-01-03](03-select-and-reserve-tasks/index.md) | Its acceptance cases and literal commands in Files and tests |
