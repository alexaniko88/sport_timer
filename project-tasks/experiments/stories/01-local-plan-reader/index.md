# STORY 1: Plan reader runs on the local model

Epic: [Experiments](../../index.md)

Status: Ready for planning.

## User outcome

As the repo owner, I want the orchestrator's cold plan read to run on a local model so that this check costs no Claude usage and stays on my machine.

## Scope

- A `runner` field in the role file frontmatter, and the dispatch rule in `SKILL.md` for it.
- A fallback to Claude when Ollama or the runner script is not available.
- The Codex shim and `ai_setup_test.dart` stay consistent with the role file.
- Excludes: any other role, and any model other than `qwen3.8:27b`.

## Acceptance criteria

- With Ollama running, the orchestrator's cold read goes through the runner and returns the same report format as today.
- With Ollama stopped or the script missing, the orchestrator runs the role on Claude and says so in one line.
- The local run sees only the plan text and never writes a file.
- `fvm flutter test test/architecture/ai_setup_test.dart` passes.

## Tasks

1. [Add the runner field and dispatch rule](01-runner-field-and-dispatch-rule.md).
2. [Fall back to Claude when the local setup is missing](02-fallback-to-claude.md).
3. [Keep the Codex shim and setup test consistent](03-codex-shim-and-setup-test.md).

## Dependencies and open decisions

- Open: use the `multi-qwen-dense` alias (64k context) or `qwen3.8:27b` directly.
