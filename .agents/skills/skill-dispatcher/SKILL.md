---
name: skill-dispatcher
description: >
  Picks the next ready task from project-tasks/, asks which AI tool runs it, and starts a runner for it in
  the background. Several runners can work at once, each on its own task and clean clone, and each ends as an
  open PR. Use when the user says "dispatch", "run the next task", "launch a task", "work on the backlog" or
  "what can we run now". For a free-form request with no task, use skill-orchestrator instead.
argument-hint: "[task id]"
model: claude-sonnet-5-5
effort: medium
---

# Dispatcher

You pick tasks and start runners. You do not implement anything yourself. The script `tool/dispatcher.dart` does the mechanical work (which task can start, the models, the clone, every stage, the commits, the push and the PR). You talk to the user, call the script and report what comes back.

This skill's `model` and `effort` are a recommendation and only last for the current turn. It does not matter much: the model of every stage is fixed by the script, not by this session.

## Standing authorization

For tasks from `project-tasks/` started through this skill, the runner commits, pushes its own task branch and opens the PR without asking each time. The script enforces the limits: it never pushes to `master` or `main`, never merges, never touches another branch, checks the commit format and adds the `Co-Authored-By: <tool> <model>` line, scans the diff for private data and uses the repo-local noreply email. You never run `git push`, `git commit` or `gh pr` yourself.

## The loop

Always use `fvm dart tool/dispatcher.dart ...`, never bare `dart`.

1. **Find a task.** Run `fvm dart tool/dispatcher.dart next` (add `--skip=ID,ID` for tasks the user already declined or that you started in this session). It prints JSON: `next` (the first task that can start, or `null`), `alsoReady`, and `waiting` (why each other ready task cannot start). When `next` is `null`, say why in one or two lines from `waiting` and stop.
2. **Offer it.** Show the task id, title, `complexity`, what it touches, and its dependencies, in plain English. Ask which tool runs it: Claude, Codex or Antigravity (recommend Claude). The user can also say "skip" (go back to step 1 with `--skip`) or "stop".
   The models are not a question. Each tool has fixed models per stage, in `tool/dispatcher/role_models.dart`:

   | Tool | Implementer | Tests | Reviewer |
   | --- | --- | --- | --- |
   | Claude | Sonnet 5.5, medium | Sonnet 5.5, medium | Opus 5.5, medium |
   | Codex | GPT-6.1 Terra, medium | GPT-6.1 Terra, medium | GPT-6.1 Sol, medium |
   | Antigravity | Gemini 4 Argon, medium | Gemini 4 Argon, medium | Gemini 4 Argon, high |

   Run `fvm dart tool/dispatcher.dart models` once per session. If it prints a `WARNING` (a fixed model is missing or no longer the newest), tell the user before launching. Pass `--implementer=`, `--tests=` or `--reviewer=` only when the user asks for another model.
3. **Check the limit.** At most 3 runners at once. Run `fvm dart tool/dispatcher.dart status` first. If 3 are `running`, tell the user to wait for one to finish.
4. **Launch.** Start `fvm dart tool/dispatcher.dart launch <ID> --tool=<tool>` as a background command (it runs until the task ends, which can take a long time). Tell the user it started.
5. **Ask once:** "Do you want another task?" If yes, go back to step 1 (skip every task you launched in this session). If no, do not ask again. Wait quietly for the runners.
6. **When a runner ends,** read the last line of its output, `RESULT {json}`, and tell the user:
   - `pullRequest`: the PR link. The task is theirs to review.
   - `blocked`: the exact question or the permission it needs. The branch has a `wip:` commit with the reason in the task's `notes.md`. The task needs to be refined (the `skill-planner` skill) or relaunched. If the message says "Needs permission for: ...", offer to relaunch with `--allow="Bash(<program>:*)"` (Claude only).
   - `failed`: the message and the last lines of output. If `keptWorkspace` is set, the work could not be pushed and the clone was kept there; say so.
   When a run ends and more tasks can start, remind the user, but do not launch anything on your own.

## Rules

- Launch only a task that `next` returned or that the user named and the script accepts (`ready`, on `origin/master`). Never edit a task, its status or its indexes.
- Do not run the stages yourself, even if the script fails. Report the failure.
- Nothing stays on the local disk after a run: the script deletes the clone when the task ends. `status` shows the runs in progress.
- Rules for the runners are in `.agents/skills/skill-dispatcher/roles/` and `references/project-overrides.md`. The task format is in `.agents/rules/project-tasks-format.md`.
