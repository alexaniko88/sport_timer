---
name: skill-dispatcher-check
description: >
  Shows which backlog tasks (`tasks_dir`, default docs/backlog) can start now, how complex each one is (1 to
  10), what it touches and which other ready tasks it overlaps with, as a table to pick from. Read-only: it
  starts nothing, changes nothing and suggests no tool or model. Use when the user says "check the backlog",
  "what can we work on", "which tasks are ready" or "what can we run now".
model: claude-sonnet-5-5
effort: low
---

# Dispatcher check

You show the user which tasks can start now, so they can open a new thread or CLI for each one and run `skill-dispatcher` there. You start nothing, edit nothing and run no git command that writes. You never ask a question, and you suggest no tool or model: the user picks those.

`<dart>` below is the `dart` value of `planner_dispatcher.yaml`. Run the command from the project root.

## Steps

1. Run `<dart> run planner_dispatcher:dispatcher check`. It reads the tasks on `origin/<base_branch>` and prints JSON:
   - `ready`: every task that can start now, in backlog order. Each has `label`, `id`, `path`, `type`, `complexity` (1 to 10, or `null` when the task has none), `touches`, `dependsOn` and `overlapsWith` (other ready tasks that can change the same files).
   - `waiting`: every other ready task, with why it cannot start (waits for a task, already has a branch or a PR, overlaps a running task).
2. If the command fails, show its error in one line and stop.
3. Show the result as below, and nothing else.

## Output

One table of the ready tasks, in the order of `ready`:

```markdown
| Task | Type | Complexity | Touches | Overlaps with |
| --- | --- | --- | --- | --- |
| Save template (TPL-03-02) | feat | 4/10 | `src/store.ts` +2 | — |
```

- Name every task by its `label`, never by the id alone.
- **Complexity:** `N/10`, or `?` when it is `null`.
- **Touches:** the first path in backticks, then `+N` for the rest.
- **Overlaps with:** the labels from `overlapsWith`, or `—`. When tasks overlap, add one line under the table: "Run X and Y one after the other, not at the same time: they change the same files."

After the table, one block the user can copy, one line per ready task:

```text
skill-dispatcher TPL-03-02
skill-dispatcher BUG-04
```

Then, when `waiting` is not empty, a short list "Waiting": one line per task, its label and the reason in plain English (for example "waits for Save template (TPL-03-02)", "already has a branch or an open PR").

When `ready` is empty, say so in one line and show only the waiting list. When both are empty, say there is no ready task in the backlog and that `skill-planner` creates them.

## Rules

- Do not add tasks, change the order or rate the complexity yourself: show what the command prints.
