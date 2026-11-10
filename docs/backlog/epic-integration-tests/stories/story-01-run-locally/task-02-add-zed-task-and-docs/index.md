---
id: INT-01-02
status: draft
type: feat
depends-on: [INT-01-01]
---

# Expose the script as a Zed task and document it

Story: [Run integration tests locally](../index.md)

Epic: [Integration tests](../../../index.md)

## Goal

The script can be started from Zed in one click, and `CLAUDE.md` documents it as the shared way to run integration tests.

## Scope

- Add a task to `.zed/tasks.json`, which is tracked in git, in the same style as the existing tasks.
- Add the script to the commands section of `CLAUDE.md` with one line on what it does and the `sport-timer-emulator` default.
- Excludes: any change to the other `.zed/` files, which are local symlinks and stay excluded.

## Dependencies

[Task 1.1](../task-01-add-run-script/index.md).

## Acceptance criteria

- The Zed task appears in the task list and runs the script.
- `CLAUDE.md` mentions the script, the default emulator, the real-device option, and that iOS and macOS are not covered.

## Validation

Run the task from Zed once. Check that `git status` shows only `.zed/tasks.json`, `CLAUDE.md` and the script.

## Implementation context

Follow the repository skill [skill-integration-tests](../../../../../../.agents/skills/skill-integration-tests/SKILL.md) for the conventions (layout, fakes, running, flow rules). It describes the target setup, so check which files exist first.

`.zed/tasks.json` and the commands section of `CLAUDE.md`.
