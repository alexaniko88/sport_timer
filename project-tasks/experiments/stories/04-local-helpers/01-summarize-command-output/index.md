---
id: EXP-04-01
status: draft
type: feat
depends-on: [EXP-02-02]
---

# Summarize format, analyze and test output locally

Story: [Test, analyze and summary helpers](../index.md)

Epic: [Experiments](../../../index.md)

## Goal

A short, correct summary of command output produced by the local model.

## Scope

- Pass the raw output of `fvm dart format`, `fvm flutter analyze` and `fvm flutter test` to the runner and return a summary.
- Verify each `file:line` in the summary against the raw output.
- Excludes: running the commands through the model. The orchestrator runs them and passes the output.

## Dependencies

- [Story 2 decision](../../02-compare-local-vs-claude/02-record-decision/index.md).

## Acceptance criteria

- On a run with a known failure, the summary reports it. On a clean run, it reports clean.
- Every `file:line` in the summary exists in the raw output.

## Validation

Run it on one failing and one clean output and compare with the raw text.

## Implementation context

- The runner script from Story 1, in `.agents/skills/skill-orchestrator/scripts/`.
