---
id: EXP-01-01
status: draft
type: feat
depends-on: []
---

# Add the runner field and dispatch rule

Story: [Plan reader runs on the local model](../index.md)

Epic: [Experiments](../../../index.md)

## Goal

The plan reader role can say it runs locally, and the orchestrator knows how to call it.

## Scope

- Add `runner: local` to `agent-plan-reader.md` frontmatter, with the model name the runner uses.
- Add one rule to the dispatch table in `SKILL.md`: a role with `runner: local` is called through the runner script with the Bash tool, not through the Agent tool.
- The brief is only the plan text, as today.
- Excludes: changing the other roles.

## Dependencies

None.

## Acceptance criteria

- The role file and `SKILL.md` describe the local call in plain steps.
- Roles without `runner` behave exactly as before.

## Validation

Read both files together and check that no step contradicts the other. Run the cold read once on a sample plan.

## Implementation context

- `.agents/skills/skill-orchestrator/SKILL.md` (dispatch table and the "Cold read" step)
- `.agents/skills/skill-orchestrator/roles/agent-plan-reader.md`
- A new self-contained runner script in `.agents/skills/skill-orchestrator/scripts/`, written in this repo.
