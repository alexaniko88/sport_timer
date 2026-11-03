# TASK 1.3: Keep the Codex shim and setup test consistent

Story: [Plan reader runs on the local model](index.md)

Epic: [Experiments](../../index.md)

Status: Ready for planning.

## Goal

The new frontmatter field does not break the shared AI setup for Codex and Antigravity.

## Scope

- Decide what Codex and Antigravity do with `runner: local` (use their own model, or ignore the field) and say it in the role file.
- Update `.codex/agents/agent-plan-reader.toml` and `test/architecture/ai_setup_test.dart` only if the rule needs it.
- Excludes: running Ollama from Codex or Antigravity.

## Dependencies

- [Task 1.1](01-runner-field-and-dispatch-rule.md).

## Acceptance criteria

- `fvm flutter test test/architecture/ai_setup_test.dart` passes.
- The TOML model and effort still match the role frontmatter where the test requires it.

## Validation

`fvm flutter test test/architecture/ai_setup_test.dart`.

## Implementation context

- `.codex/agents/agent-plan-reader.toml`
- `test/architecture/ai_setup_test.dart`
