# TASK 2.1: Run the comparison on a real plan

Story: [Compare local and Claude on a real plan](index.md)

Epic: [Experiments](../../index.md)

Status: Blocked by Story 1.

## Goal

Two plan reader reports on the same plan, one local and one Claude.

## Scope

- Pick one finished plan with 4 or more steps.
- Run the role on `qwen3.8:27b` and on Claude, with the same brief.
- Measure the time of each run. Check each `path:line` in both reports against the code by hand.
- Excludes: changing the plan between runs.

## Dependencies

- [Story 1](../01-local-plan-reader/index.md).

## Acceptance criteria

- Both reports and both timings are stored where Task 2.2 can read them.
- The result of the `path:line` check is kept for each report.

## Validation

The two reports follow the same format and cover the same plan text.

## Implementation context

- Plan history is in the `project-tasks/done/` folders and the git log.
