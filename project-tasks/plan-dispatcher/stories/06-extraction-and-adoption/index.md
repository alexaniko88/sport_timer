# STORY 6: Independent release and consumer adoption

Epic: [PlanDispatcher](../../index.md)

## User outcome

Publish the fresh generic MIT project and adopt its immutable release without losing consumer data.

## Scope

- Publish the independent public PlanDispatcher project.
- Adopt the pinned release and remove temporary source.

Each task owns one implementation responsibility and its tests. No application feature is added. The [epic contracts](../../contracts.md) supply shared interfaces/error semantics; consumers must not privately redesign them.

## Acceptance criteria

- R1: Project-local installation is proved by the owning task checks below.
- R3: Pinned restoration/explicit updates is proved by the owning task checks below.
- R16: Compatible consumer cutover is proved by the owning task checks below.
- R17: Fresh public MIT extraction is proved by the owning task checks below.
- R18: Pinned adoption/framework-neutral proof is proved by the owning task checks below.

## Tasks

1. [PLD-06-01: Publish the independent public PlanDispatcher project](01-publish-independent-project/index.md).
2. [PLD-06-02: Adopt the pinned release and remove temporary source](02-adopt-pinned-release/index.md).

## Dependencies and open decisions

No product decision is intentionally left open. Dependencies are the explicit fixed-contract task IDs in each file; unmerged prerequisites defer execution, not specification. Task status remains draft until its independent cold read is resolved. Executor routing and any exclusive/cross-repository boundary are part of each task's contract.

## Shared contracts

Consume [the epic contracts](../../contracts.md), especially the fixed public package interfaces and schema 1. Source and test locations are planned there. The task table below assigns contributions and checks; late assembly is intentional, never a reason to wire a block early.

The handoff target is new public alexaniko88/plan-dispatcher, fresh main history, MIT, v0.1.0. It is not auto-selected by a dispatcher. Source completion requires an archived Sport Timer PR with immutable released commit/tag; adoption waits for its merge. The second consumer is a temporary removed fixture.

The handoff checklist lives in [PLD-06-01](01-publish-independent-project/index.md). Its archived `notes.md` `## Release` section (repository, tag, 40-hex commit, source SHA) is the single input PLD-06-02 reads; adoption refuses if it is missing or the tag does not resolve to that commit.

## Requirement coverage

| Requirement | Owning task | Check |
| --- | --- | --- |
| R1: Project-local installation | [PLD-06-01](01-publish-independent-project/index.md) | Its acceptance cases and literal commands in Files and tests |
| R16: Compatible consumer cutover | [PLD-06-01](01-publish-independent-project/index.md) | Its acceptance cases and literal commands in Files and tests |
| R17: Fresh public MIT extraction | [PLD-06-01](01-publish-independent-project/index.md) | Its acceptance cases and literal commands in Files and tests |
| R1: Project-local installation | [PLD-06-02](02-adopt-pinned-release/index.md) | Its acceptance cases and literal commands in Files and tests |
| R3: Pinned restoration/explicit updates | [PLD-06-02](02-adopt-pinned-release/index.md) | Its acceptance cases and literal commands in Files and tests |
| R16: Compatible consumer cutover | [PLD-06-02](02-adopt-pinned-release/index.md) | Its acceptance cases and literal commands in Files and tests |
| R18: Pinned adoption/framework-neutral proof | [PLD-06-02](02-adopt-pinned-release/index.md) | Its acceptance cases and literal commands in Files and tests |
