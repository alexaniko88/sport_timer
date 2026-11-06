---
name: skill-planner
description: >
  Plans a feature, improvement, bug or refactor into tasks under project-tasks/ that are so concrete a runner
  can implement each one without asking anything. Interviews the user one question at a time, asks the view
  questions for UI work, builds an HTML mockup the user approves, proposes the acceptance criteria, and checks
  every task with a fresh agent that has not seen the conversation. Use when the user says "plan", "create
  tasks", "break this into tasks", "write the tasks for", or wants a backlog ready for skill-dispatcher. This is
  planning only: it writes no app code and creates no Linear or GitHub tickets.
argument-hint: "<what you want planned, in your own words>"
model: claude-opus-5-5
effort: medium
---

# Planner

Turn the user's idea into tasks that a runner can implement without asking anyone. This is where the time goes: every question left open in a task becomes a blocked run later. The runners follow `.agents/skills/skill-dispatcher/` and read only what is in the repo, so a task must carry everything it needs.

The layout, ids, task fields and sections, the ready checklist and the done rules are in `.agents/rules/project-tasks-format.md`. Follow that file and do not copy it into tasks. Running the tasks is `skill-dispatcher`'s job, not yours.

## Talking to the user

These rules apply to every step below.

- **Only questions.** Work quietly. Do not tell the user what you read, search, write or check, and do not show plans, findings or progress. A message to the user is a question, a blocker that stops you, or the final summary in step 10. Nothing else.
- **One question per message.** Never show two questions at once, not even as a numbered list. With a question dialog, put exactly one question in each call. Wait for the answer before the next.
- **Atomic questions.** Each question asks about one thing only, in short plain words. Split a question that has "and", "or" or several parts into separate questions. Give only the context needed to answer it, in one or two short lines, and your recommended answer, worded so that "yes" accepts it.
- **Final summary.** When everything is settled, show the summary from step 10. That is the only long message.

## Before you start

- **Check your model.** A skill's `model` only lasts one turn and this is a long conversation, so check which model you are running on. The planner needs a strong one:

  | Tool | Planner model |
  | --- | --- |
  | Claude | Opus 5.5, medium effort |
  | Codex | GPT-6.1 Sol, medium effort |
  | Antigravity | Gemini 4 Argon, medium effort |

  If you run on another model, say so in one line and ask the user to switch (`/model` in Claude Code) before you start. Go on only if they say to.
- **Language.** Talk with the user in the language they use. Every file you write is in plain, simple English.
- **Sync master.** Run `fvm dart tool/sync_master.dart` first. It switches to `master`, pulls it and deletes merged local branches (rules in `.agents/skills/skill-dispatcher/SKILL.md`). Do not ask; report its result in one line with the final summary. If it fails (for example uncommitted changes), stop and explain.
- **Branch.** Check `git status -sb` and read `.agents/rules/git-commits.md`. Then, from the updated `master`, run `git switch -c feat/plan-<short-topic>`. Do not carry unrelated uncommitted work onto the branch and never discard or stash it. If the checkout cannot be switched safely or the pull fails, stop and explain. Continue an existing planning branch for follow-up messages.

## 1. Understand

Find the facts yourself; ask the user only for decisions.

- Read `CLAUDE.md`, the format rule and the code the idea touches. For UI, read the matching images in `test/snapshots/goldens/` and `test/snapshots/README.md`; they show how the app looks today. Check a library's official documentation when a choice depends on what it can do.
- Search all of `project-tasks/`, including `done/` folders, for the same or overlapping work (search related terms, not only the title). If it exists, extend it, and name it in your next question when the user needs to know. For a finished task, decide whether the new work is a duplicate, a regression or a follow-up, and link it. If that is unclear, ask.
- Find the epic and story each new task belongs to by outcome and acceptance criteria, not by title. Epics and stories never move, so add to them freely. Use `bugs/` or `improvements/` for a standalone report. Ask the user only if two parents fit equally well.

## 2. Pick the depth

| Work | What you do |
| --- | --- |
| Feature or improvement with a view | Everything below: interview, view questions, mockup, criteria, cold read |
| Feature or improvement with no view | Interview, criteria, cold read |
| Bug | Diagnose first: read the code, reproduce when you can, and confirm the cause with evidence. The task carries the cause, the evidence and the decided fix. It is not `ready` until the cause is confirmed. A mockup only if the view changes |
| Refactor, tests or tooling | A short interview about scope and boundaries, criteria, and a light cold read |

## 3. Interview

Ask **one atomic question at a time**, as described in "Talking to the user". Put a concrete example in a question when it helps.

- Settle: the user outcome, what counts toward it, what is excluded, edge cases, error cases, where data lives and for how long, and what is in the first version versus later.
- Keep asking until nothing is left open. "Good enough" is not the goal; a task that makes a runner guess is not done.
- Treat future ideas as provisional: write them as "later" in the story, never as tasks to implement now.
- Keep facts, user decisions, your recommendations and open questions apart. Never present a recommendation as a decision.

## 4. View questions (tasks with a view)

Read [references/ui-questions.md](references/ui-questions.md). Look at what exists first and fit the design to the app as it is today. The user does not give you a design: you propose from the existing screens, and ask only what you cannot see.

## 5. Mockup (tasks with a view)

Read [references/mockup.md](references/mockup.md). Build `mockup.html` in the task folder and show it to the user: publish it as a private Artifact when you have the Artifact tool, otherwise open the local file. The user answers "ok" or "no". On "no", change it and show it again. A task with a view is not `ready` until the user has approved the mockup.

## 6. Split into tasks

- A task is one PR and one runner run. Split it when it touches more than about 8 files or two separate concerns. One task can span several files.
- Choose stories around useful outcomes and tasks around cohesive deliverables. Keep necessary setup inside its story. Do not make one task per file.
- An unresolved technical choice becomes a prerequisite task (a decision or an investigation). Never invent the answer.
- Tests belong inside the task that changes the code. Add a separate verification task only when it checks behavior across tasks.
- State dependencies with `depends-on`. Check there is no cycle.
- For a new backlog, show the epic, story and task split and get the user's agreement before you write it. Reuse agreement already given.

## 7. Acceptance criteria

You propose the criteria from the interview and the user confirms them. Do not ask the user to write them. Show the list with one yes or no question ("Are these criteria right?") and nothing else in that message.

- One line each: `- [ ] When <situation>, then <result>. Check: <test, golden or command>.`
- Cover the main result, each edge case and error case from the interview, and empty or partial states.
- Every criterion must be checkable by a test, a golden image or a command a runner can run. If you cannot say how it is checked, it is not a criterion yet.

## 8. Write the files

Read [references/templates.md](references/templates.md) and write the task folders.

- Fill every field of the front matter. `complexity` picks the suggested effort: **low** is one concern in an existing pattern with a few files; **medium** is new logic, or a view with several states; **high** is a new architecture, timer, audio, auth or build setup, or six or more files.
- `touches` lists paths or globs. Name the exact golden files, and list `lib/l10n/**` when strings are added. Do not list `test/snapshots/README.md` or the indexes.
- `skills` lists project skills a runner must read, for example `skill-fl-chart` for a chart or `skill-integration-tests` for an integration test.
- Fill `## Decisions` with what the user decided and why, and `## Out of scope` with what the task does not do. `## Files and tests` says what is created or changed and which tests are written.
- Name only code you checked in the repo. Never invent file names or APIs. Use relative Markdown links and repository-relative paths; no local usernames, absolute paths or secrets.
- Keep shared decisions in the epic or story and link to them. Each task still needs enough context to stand alone, because a runner sees only the task, its parents and the repo.
- A new epic gets an `abbr` that no other epic uses. Number stories and tasks with the next unused number. Do not mix the old and new layouts.

## 9. Cold read

For each task, run a fresh agent that has never seen this conversation. It reads only the task and the repo and lists what it would have to ask. That is the check that the task needs nobody.

1. Dispatch the `cold-reader` role with a read-only run. Give it only the task path: `Read .agents/skills/skill-planner/roles/cold-reader.md and follow it. The task is <path>.` Never give it the conversation, your notes or the interview.
   - **Claude:** the Agent tool as a general-purpose agent, with `model: sonnet`.
   - **Codex:** `codex exec --ignore-user-config -s read-only -m gpt-6.1-terra -c 'model_reasoning_effort="medium"' "<brief>"`.
   - **Antigravity:** `agy --sandbox --mode plan --model gemini-4-argon-medium -p="<brief>"`.
2. For each question it returns, either fix the task or, if it is a decision, ask the user. Then run it again on the changed task.
3. Do at most three rounds. A bug, refactor or tooling task gets one light pass.
4. Set `status: ready` only when the cold reader has no question left (and, for a view, the mockup is approved). Otherwise leave the task `draft` and say exactly what is open.

## 10. Validate and hand off

- Check the ids are unique, the numbering and the paths follow the rule, every relative link resolves, each `depends-on` id exists and there is no cycle, and the tasks together cover the story's acceptance criteria.
- Report the counts, which tasks are `ready` and which are `draft` and why, and any decision still open. Keep it short.
- When nothing else is needed, show the full commit message and the exact files, then ask this once, in its own bold paragraph:

  **Are you done with this task? If yes, I will commit these files, push the branch, and open a PR.**

- An affirmative answer with no further change authorizes the commit, the push and the PR. Do not ask again for each. If the user asks for changes, make them, show the message and files again and ask again. Silence is not approval.
- Before the commit: check the repo-local noreply email (`git config user.email`), stage only the approved files, and scan the staged diff for local paths, secrets and keys. Commit messages follow `.agents/rules/git-commits.md`, including the `Co-Authored-By: <tool> <model>` line. The PR title starts with `feat:` for a `feat/` branch. Report the PR link.
- Tell the user the tasks become visible to `skill-dispatcher` only after this PR is merged.

## Never

- Write application code, create Linear or GitHub tickets, or run a task.
- Set a status other than `draft` or `ready`, or keep progress in an index.
- Copy global coding, git or model policies into a task.
