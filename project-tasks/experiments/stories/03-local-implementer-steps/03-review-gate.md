# TASK 3.3: Require Claude review before hand-off

Story: [Small implementer steps on the local model](index.md)

Epic: [Experiments](../../index.md)

Status: Provisional.

## Goal

A weak local edit is always caught by Claude before hand-off.

## Scope

- Make `agent-pr-review` a required stage when any step ran locally, and say so in the hand-off.
- Excludes: changing the review role itself.

## Dependencies

- [Task 3.2](02-sandbox-patch-flow.md).

## Acceptance criteria

- The hand-off states which steps ran locally and that review ran on Claude.
- Skipping the review is not possible in the written flow.

## Validation

Read the updated `SKILL.md` flow for a plan with one local step and check the review stage is present.

## Implementation context

- `.agents/skills/skill-orchestrator/SKILL.md` review and hand-off stages.
