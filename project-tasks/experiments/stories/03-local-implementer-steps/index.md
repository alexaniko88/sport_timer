# STORY 3: Small implementer steps on the local model

Epic: [Experiments](../../index.md)

## User outcome

As the repo owner, I want small, fully specified edits to run on the local model so that typing-heavy steps cost no Claude usage, without lowering code quality.

## Scope

- Only mechanical steps: a field, a `copyWith`, an ARB key, a rename.
- Work happens in a throwaway copy of the repo and returns a patch. The owner approves before it is applied.
- Claude's `agent-pr-review` runs before hand-off on every change that includes a local step.
- Excludes: design decisions, new screens, and anything not fully specified in the plan.

## Acceptance criteria

- The real working tree is unchanged by the local run, and a leak is reported.
- A patch is applied only after approval, and unstaged.
- Format and analyze pass on the touched files after the patch is applied.

## Tasks

1. [Define which steps count as mechanical](01-define-mechanical-steps/index.md).
2. [Run local steps in the sandbox and return a patch](02-sandbox-patch-flow/index.md).
3. [Require Claude review before hand-off](03-review-gate/index.md).

## Dependencies and open decisions

- Provisional: confirm after Story 2 that the local model is good enough to write code, since Story 2 only measures reading.
