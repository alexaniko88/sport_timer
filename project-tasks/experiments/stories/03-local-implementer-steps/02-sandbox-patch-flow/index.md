---
id: EXP-03-02
status: draft
type: feat
depends-on: [EXP-03-01]
---

# Run local steps in the sandbox and return a patch

Story: [Small implementer steps on the local model](../index.md)

Epic: [Experiments](../../../index.md)

## Goal

A local implementer step runs in a throwaway copy and produces a patch the owner can approve.

## Scope

- Write a sandbox and patch script in this repo (a throwaway copy of the repo, a patch, and a leak check), run with `qwen3.8:27b`.
- Show the patch, the model's report and the leak check result before asking for approval.
- Excludes: staging, committing or pushing the patch.

## Dependencies

- [Task 3.1](../01-define-mechanical-steps/index.md).

## Acceptance criteria

- A sample step produces a patch and a report, and the real tree is unchanged.
- The patch applies cleanly, unstaged, after approval.

## Validation

Run one real mechanical step end to end, then run format and analyze on the touched files.

## Implementation context

- `.agents/skills/skill-orchestrator/scripts/` for the new script, and `roles/agent-implementer.md` for the rules the local step must follow (`CLAUDE.md` and `.agents/rules/dart-style.md`).
