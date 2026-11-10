---
name: skill-dispatcher
description: >
  Runs one ready task of the backlog folder (`tasks_dir`, default docs/backlog) from start to an open PR, in
  the thread or CLI it is opened in. It suggests a model for the implementer, tests and reviewer stages, then
  coordinates one subagent per stage in the task's own worktree, and ends with a pushed branch and a PR. Use
  when the user says "dispatch", "run task <id>", "work on <id>", "launch a task" or names `skill-dispatcher <id>`.
argument-hint: "[task id]"
model: claude-sonnet-5-5
effort: medium
---

# Dispatcher

You run one task and coordinate it. You never write code, tests or reviews yourself: a fresh subagent does each stage. The dispatcher commands do the mechanical work: the worktree, the commits, the guard, the push and the PR. You call them, hand the work from one stage to the next and report the end.

`<dart>` below is the `dart` value of `planner_dispatcher.yaml`, `<base_branch>` its `base_branch` and `<tasks_dir>` its `tasks_dir` (default `docs/backlog`). Run every dispatcher command from the project root.

## Standing authorization

Opening this skill authorizes the whole run: the commits, the push of the task's own branch and the PR, without asking again. Only when `planner_dispatcher.yaml` sets `publish: ask`, ask once before `finish` or `block`: "The task is ready to push. Push the branch and open the PR?" (for a block: "…and push the blocked work?"). With a no, stop and leave the worktree. The commands enforce the limits: they never push to `<base_branch>`, `main` or `master`, never merge and never force-push, and the guard checks the commit subjects, the git email and the diff for private data before every push. You never run `git commit`, `git push` or `gh pr` yourself.

## Questions

A well planned task needs no question. You ask the models (step 3), and the publish question when `publish: ask` is set. Then you work without asking, except when the run cannot go on without the user (step 9): you ask right away, in the thread, and go on with the answer. Never end the run to have it launched again for something one quick answer solves.

Stop and show the error only when something is serious: a command of steps 4 or 10 fails, or your tool cannot start subagents. The worktree then stays with the work.

## Steps

1. **The task.** Use the task id the user gave. Without one, run `<dart> run planner_dispatcher:dispatcher check` and take the first task of `ready`; when it is empty, say why in one line from `waiting` and stop. Name every task by its label, the title followed by the id (`Save template (TPL-03-02)`).
2. **Your tool.** You know which tool you run in: `claude` (Claude Code), `codex` (Codex) or `antigravity` (Antigravity, `agy`). For any other tool, use its short lowercase name, for example `kimi`.
3. **The models.** Run `<dart> run planner_dispatcher:dispatcher models <ID> --tool=<tool>`. Show the task label, its complexity and one line per stage, then ask once:
   - With `"suggested": true`: "These are the models for the implementer, tests and reviewer. Accept, or type the ones to change (for example `reviewer: opus:high`)."
   - With `"suggested": false`: "There is no suggestion for <tool>. Type the model of the implementer, tests and reviewer (`model` or `model:effort`)."

   Antigravity can only pick Flash for a subagent; an Argon stage inherits the model of this session, so with Antigravity the session must run Gemini 4 Argon. If it does not, say so with the question.
4. **Start.** Run `<dart> run planner_dispatcher:dispatcher start <ID> --tool=<tool>`, adding `--implementer=`, `--tests=` or `--reviewer=` (as `model` or `model:effort`) for each stage the user changed, and all three when there was no suggestion. It creates the worktree in `.worktrees/<ID>`, runs the project setup, claims the task and prints JSON: the task (`label`, `path`), `worktree`, `runnerDirectory`, and `stages` (per stage its `name` and the `call` parameters of the subagent). If it fails, show the error and stop.
5. **Implementer.** Start the implementer subagent (see "Subagents") with the brief below. Read its report:
   - "Blocked" is not "None": ask the user that question (step 9), send the answer to the same subagent and read its new report.
   - Otherwise run `<dart> run planner_dispatcher:dispatcher commit <ID> --role=implementer --message='<the report's Commit line>'`, always in single quotes and with any `'` of the line removed, so the shell never runs part of it. If the command refuses the subject, fix only its form (type, lowercase, no final period, at most 72 characters) and run it again.
6. **Tests.** The same with the tests subagent, and `--role=tests`.
7. **Checks.** Run `<dart> run planner_dispatcher:dispatcher checks <ID>`. It runs the project's `check` commands in the worktree and prints only `passed`, the `commands`, and for a failure the `failed` command and the `tail` of its output. When one fails, send the implementer the extra line "The project checks failed. Fix them without changing what the task asks:" with `failed` and `tail`, commit its fix and run `checks` again. When they still fail, ask the user (step 9) with the failing command and its last lines, and the choices: one more fix, finish anyway (the failure goes to "Points to review") or stop.
8. **Review.** Start the reviewer subagent with the extra line "Review the diff of this branch against origin/<base_branch>." Its report ends with a `json` block `{"findings": [...]}`; if there is none, ask it once for the block.
   - No `critical` or `general` finding: the review passed.
   - Otherwise, in round 1: start the implementer with the extra line "Fix only these review findings:" and one line per critical or general finding (`<file>:<line>: <summary> Fix: <fix>`), commit its fix, run the checks again (step 7) and review again.
   - Still `critical` or `general` findings in round 2: ask the user (step 9) with the list of them, and the choices: one more fix round, finish anyway (they go to "Points to review") or stop.
9. **Ask the user** (when a step says so). Show the question in a few lines: what is needed and why, the options with your recommendation first, and that they can type their own answer. Wait for the answer, note it for the report, and go on where the step left off. A permission dialog of the tool is answered in the tool itself; the subagent then goes on.
   Only when the user says to stop, or the answer needs the task to be planned again: write the question to `<runnerDirectory>/question.md` and run `<dart> run planner_dispatcher:dispatcher block <ID>`. It reads only that file, writes the question to the task's `notes.md`, pushes a `wip:` commit and removes the worktree. Then go to step 11.
10. **Finish.** Write `<runnerDirectory>/report.md` with these sections and run `<dart> run planner_dispatcher:dispatcher finish <ID>`:
    - `## Summary`: the implementer's summary, in a few bullets.
    - `## Evidence`: the tests' evidence, one line per acceptance criterion.
    - `## Checks`: "All checks passed (<each of `commands` in backticks>)", adding "after one fix" when the implementer fixed them.
    - `## Points to review`: the review's `minor` findings (`<file>:<line>: <summary>`), the stages' open notes, any check failure or finding the user chose to finish with, and under "Decisions during the run" each question of step 9 with the user's answer. Or "None".

    It moves the task to `done/`, runs the guard, pushes, opens the PR, removes the worktree and prints `RESULT {json}` with `prUrl`. If it fails, show the error: the worktree stays with the work. Once the cause is fixed (for example `gh auth login`), run `finish` again: it does not close the task twice and reuses a PR already open.
11. **Report** in a few lines: the PR link, or that the task is blocked and the exact question. Add the models each stage used, and any points to review. A blocked task goes back to `skill-planner` when it must be planned again, then runs again with `skill-dispatcher <ID>`: `start` continues its branch on its own.

## Subagents

Start every stage as a new subagent with a clean context, never one that saw this conversation, with the `call` parameters of that stage from step 4. Wait for it to end and read its final message: that is its report.

An answer of the user goes to the subagent that asked, and a check fix or a review fix to the implementer that already did the task, when the tool can continue it, so it does not read everything again: Claude Code `SendMessage` to its agent id, Codex `send_input` to its agent. When the tool cannot continue a subagent, start a new one of the same stage with the same brief and the extra lines. The reviewer is always new.

- **Claude Code:** the Agent tool, `subagent_type: "general-purpose"`, in the foreground, with `model` and `effort` from `call`.
- **Codex:** `spawn_agent` with `model`, `reasoning_effort` and `fork_turns` from `call`, then wait for it.
- **Antigravity:** `define_subagent` once per stage (write tools on for the implementer and tests, off for the reviewer), then `invoke_subagent` with `Model` from `call` and the brief as `Prompt`.
- **Another tool:** its own subagent tool, with the model from `call`. If it has none, stop and tell the user: this skill needs subagents.

The brief of every stage, with the values of step 4:

```text
You are the <stage> of the task <label>.
Work only inside <worktree>: every path below is relative to it. Run every shell command as `cd <worktree> && <command>`.
Read .agents/skills/skill-dispatcher/roles/<stage>.md and follow it exactly.
The task is <path>. The base branch is origin/<base_branch>.
<extra lines, if the step names any>
```

## Rules

- One task per thread. Several threads can run at once, each on its own task: `start` claims the task, so `check` shows it as busy elsewhere.
- Never edit a task, its status or its indexes, and never edit the work of a stage yourself. Do not run the stages yourself, even when a subagent fails: start it again once, then ask the user (step 9).
- Never run `git commit`, `git push`, `git checkout` or `gh pr` yourself: use the dispatcher commands.
- The roles and their limits are in `.agents/skills/skill-dispatcher/roles/`, `references/runner-rules.md`, the stack rules in `.agents/rules/stacks/` and `.agents/planner-dispatcher/project-overrides.md`. You do not need to read them: the subagents do.
- The suggested models come only from the `models` command; a project changes them under `models` in `planner_dispatcher.yaml`.
