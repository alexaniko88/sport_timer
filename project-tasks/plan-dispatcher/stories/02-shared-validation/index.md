# STORY 2: Shared project validation

Epic: [PlanDispatcher](../../index.md)

## User outcome

Run configured checks through one Python interface and prove Sport Timer parity before retirement.

## Scope

- Implement the shared configured checker in both modes.
- Configure and prove Sport Timer validator parity.

Each task owns one implementation responsibility and its tests. No application feature is added. The [epic contracts](../../contracts.md) supply shared interfaces/error semantics; consumers must not privately redesign them.

## Acceptance criteria

- R2: Confirmed tooling/no improvised helpers is proved by the owning task checks below.
- R10: Configured checker modes and trust is proved by the owning task checks below.
- R11: Sport Timer checker parity is proved by the owning task checks below.
- R16: Compatible consumer cutover is proved by the owning task checks below.

## Tasks

1. [PLD-02-01: Implement the shared configured checker in both modes](01-configurable-checker/index.md).
2. [PLD-02-02: Configure and prove Sport Timer validator parity](02-sport-timer-check-parity/index.md).

## Dependencies and open decisions

No product decision is intentionally left open. Dependencies are the explicit fixed-contract task IDs in each file; unmerged prerequisites defer execution, not specification. Task status remains draft until its independent cold read is resolved. Executor routing and any exclusive/cross-repository boundary are part of each task's contract.

## Shared contracts

Consume [the epic contracts](../../contracts.md), especially the fixed public package interfaces and schema 1. Source and test locations are planned there. The task table below assigns contributions and checks; late assembly is intentional, never a reason to wire a block early.

The checker supports both developer and frozen run mode. Ordered argv checks, file-set mapping/unions, optional groups, added-line severity scans, explicit-file semantics and generated-change invalidation are fixed before the parity task. Sport Timer cases/config stay outside the generic source subtree.

## Requirement coverage

| Requirement | Owning task | Check |
| --- | --- | --- |
| R2: Confirmed tooling/no improvised helpers | [PLD-02-01](01-configurable-checker/index.md) | Its acceptance cases and literal commands in Files and tests |
| R10: Configured checker modes and trust | [PLD-02-01](01-configurable-checker/index.md) | Its acceptance cases and literal commands in Files and tests |
| R11: Sport Timer checker parity | [PLD-02-01](01-configurable-checker/index.md) | Its acceptance cases and literal commands in Files and tests |
| R10: Configured checker modes and trust | [PLD-02-02](02-sport-timer-check-parity/index.md) | Its acceptance cases and literal commands in Files and tests |
| R11: Sport Timer checker parity | [PLD-02-02](02-sport-timer-check-parity/index.md) | Its acceptance cases and literal commands in Files and tests |
| R16: Compatible consumer cutover | [PLD-02-02](02-sport-timer-check-parity/index.md) | Its last two acceptance lines: the old validator still passes and is unchanged |
