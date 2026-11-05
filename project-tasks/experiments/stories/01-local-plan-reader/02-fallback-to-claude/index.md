---
id: EXP-01-02
status: draft
type: feat
depends-on: [EXP-01-01]
---

# Fall back to Claude when the local setup is missing

Story: [Plan reader runs on the local model](../index.md)

Epic: [Experiments](../../../index.md)

## Goal

A missing or failing local setup never blocks the orchestrator.

## Scope

- Detect: Ollama not running, model not installed, script missing, or a timeout.
- On any of these, run the role on Claude with the model and effort from its frontmatter, and say so in one line.
- Excludes: retries or automatic model switching.

## Dependencies

- [Task 1.1](../01-runner-field-and-dispatch-rule/index.md).

## Acceptance criteria

- Each of the four failure cases ends with a Claude run and a one-line notice.
- No failure case leaves a partial report mixed into the plan.

## Validation

Stop Ollama and run the cold read. Rename the script and run it again. Both must finish on Claude.

## Implementation context

- `SKILL.md` fallback wording.
