# TASK 3.1: Define which steps count as mechanical

Story: [Small implementer steps on the local model](index.md)

Epic: [Experiments](../../index.md)

Status: Provisional.

## Goal

A short, clear rule the orchestrator uses to decide if a step goes to the local model.

## Scope

- List what is allowed and what is not, with one example each, in `SKILL.md`.
- Excludes: moving any step before the rule is agreed.

## Dependencies

- [Story 2 decision](../02-compare-local-vs-claude/02-record-decision.md).

## Acceptance criteria

- A step can be classified from the rule alone, with no judgment call.

## Validation

Classify the steps of two past plans with the rule and check the results make sense.

## Implementation context

- `.agents/skills/skill-orchestrator/SKILL.md`, `roles/agent-implementer.md`.
