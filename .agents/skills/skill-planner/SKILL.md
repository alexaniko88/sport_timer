---
name: skill-planner
description: >
  Plans a feature, improvement, bug or refactor into tasks under the backlog folder (`tasks_dir`, default docs/backlog) that are so concrete a runner
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

Turn the user's idea into simple tasks that a runner can implement without asking anyone. Every question left open in a task becomes a blocked run later, and every extra line costs the runner time, so tasks are complete and short.

Project facts come only from these files: `planner_dispatcher.yaml` (the commands and settings), the files in its `rules` list, `.agents/planner-dispatcher/planner-notes.md` (branches, pull requests, UI sources, project skills, checks and coverage checks), and, for what runners may do, the Common and Tests sections of `.agents/skills/skill-dispatcher/references/runner-rules.md`, then the Common, Tests and Planning sections of `.agents/rules/stacks/<name>/rules.md` for each name in the config's `stacks` list (skip this when the list is missing or empty), then the Common and Tests sections of `.agents/planner-dispatcher/project-overrides.md`. Read them before you plan. `<dart>` below is the config's `dart` value and `<tasks_dir>` is its `tasks_dir` value (default `docs/backlog`).

The layout, ids, task fields and sections, the acceptance format, `touches`, the ready checklist and the planning record's lifecycle are in `.agents/rules/backlog-format.md`. Follow that file and do not copy it into tasks. How to split the work and what a runner can do are in [references/task-splitting.md](references/task-splitting.md). Running the tasks is `skill-dispatcher`'s job, not yours.

## Talking to the user

These rules apply to every step below and own the question format; the references only link here.

- **Tasks by name.** Refer to a task as its title followed by its id, for example `Save template (TPL-03-02)`, never by the id alone. The same goes for stories and epics: their title, not their folder or number.
- **Work quietly.** Do not narrate reads, searches, writes or checks. Messages are questions, blockers, the mockup, the split in step 6, the criteria in step 9 or the final summary in step 10.
- **One question per message.** Never show two questions at once, not even as a numbered list. With a question dialog, put exactly one question in each call. Wait for the answer before the next.
- **Atomic questions.** Ask for one decision. Keep the question short, clear and in plain words, so the user understands it on the first read: one line when you can, plus at most one short line of context. Split independent decisions; alternatives for the same decision stay together. Never hide several decisions inside one yes/no question.
- **At most three options.** Offer up to three answers to choose from. Three is the goal; offer fewer only when there are fewer real alternatives. Each option is a few words, with at most one short line of explanation.
- **Always recommend.** Every question has one recommended answer, listed first and marked "(Recommended)", with its reason in one line. Base it on repository evidence, an agreed constraint or official documentation when there is any. For an open product preference, recommend the option that best fits the request and the app as it is today, and say it is your preference. Let "yes" accept the recommendation. A recommendation becomes a decision when the user accepts it, or when you record it as an assumption and the user confirms it in step 6.
- **Always allow a typed answer.** Besides the options, the user can always answer in their own words when none of them fits. This choice does not count toward the three. With a question dialog, use the tool's own "Other" choice and never remove it; if the tool has none, add a last choice "Something else (I will type it)". If the dialog cannot take typed text, or the answer is open (a name, a number, a description), ask as plain chat text: list up to three numbered suggestions, the recommended one first, and say the user can also type their own answer.
- **Checkpoints.** When you reach the question budget of step 2, first record the remaining low-impact gaps as assumptions. Then state the settled decisions and the remaining high-impact topics in a few lines, and ask one question: go on with those topics, or split now and leave them open (their tasks stay `draft`). A checkpoint accepts nothing by itself.

## Before you start

- **Model.** The planner needs a strong model: Opus 5.5 (Claude), GPT-6.1 Sol (Codex) or Gemini 4 Argon (Antigravity), at medium effort. When you know you run on another one, say so in one line in your first message and go on.
- **Language.** Talk with the user in the language they use. Every file you write is in plain, simple English.
- **Sync the base branch.** Run `<dart> run planner_dispatcher:sync` first. It switches to the configured `base_branch`, pulls it and deletes only the local branches GitHub shows as merged into it with the same last commit. Do not ask; report its result in one line with the final summary. If it fails (for example uncommitted changes), stop and explain.
- **Branch.** Check `git status -sb` and read the planner notes' `## Branches and pull requests`. Then, from the updated base branch, run `git switch -c feat/plan-<short-topic>` (use another prefix only when the planner notes give one). Do not carry unrelated uncommitted work onto the branch and never discard or stash it. If the checkout cannot be switched safely or the pull fails, stop and explain. Continue an existing planning branch for follow-up messages.

## 1. Understand

Find the facts yourself; ask the user only for decisions.

- Read the project files above, the format rule and the code the idea touches. When the Implementation or Tests section of `project-overrides.md` still holds only its template text, tell the user in one line that runners will rely on your guess of where code and tests go, and suggest filling it in. For UI, read what the planner notes' `## UI sources` names and, when `goldens_dir` is set, the matching images there. Check a library's official documentation when a choice depends on what it can do.
- Run `<dart> run planner_dispatcher:backlog close-finished` so finished stories and epics are in `done/`; its moves go into the planning commit.
- Search all of `<tasks_dir>/`, including `done/` folders, for the same or overlapping work (search related terms, not only the title). If it exists, extend it, and name it in your next question when the user needs to know. For a finished task, decide whether the new work is a duplicate, a regression or a follow-up, and link it. If that is unclear, ask.
- Find the epic and story each new task belongs to by outcome and requirements, not by title. Use `bugs/` or `improvements/` for a standalone report. When the parent is closed, run `<dart> run planner_dispatcher:backlog reopen <path>` before you add to it; never move backlog folders by hand. Ask the user only if two parents fit equally well. When you extend a story, bring its pending tasks that still use an older layout (for example a `## Behavior` section) to the current format.

## 2. Pick the depth

| Work | What you do | Question budget |
| --- | --- | --- |
| Feature or improvement with a view | Everything below: interview, view questions, mockup (only for a new screen or layout), criteria, cold read | About 12 |
| Feature or improvement with no view | Interview, criteria, cold read | About 8 |
| Bug | Diagnose first: read the code, reproduce when you can, and confirm the cause with evidence. The task carries the cause, the evidence and the decided fix. It is not `ready` until the cause is confirmed. A mockup only if the view changes | About 3 |
| Refactor, tests or tooling | A short interview about scope and boundaries, criteria, and a light cold read | About 5 |

The budget is the number of questions before a checkpoint (see "Checkpoints"). Never bundle questions to stay under it.

## 3. Interview

Read [references/questions.md](references/questions.md) before interviewing. It defines the planning record, which gaps to look for, which ones deserve a question, and when to stop.

Ask only high-impact decisions: scope, visible behavior, data that is kept or lost, and how success is checked. For a low-impact decision, record your recommended answer as an assumption; the user confirms all assumptions at once in step 6. Routine implementation details follow verified repository patterns. Future ideas stay outside the current scope.

## 4. View questions (tasks with a view)

When the first line of the planner notes' `## UI sources` is `No UI`, skip steps 4 and 5. Otherwise read [references/ui-questions.md](references/ui-questions.md). Look at what exists first and fit the design to the app as it is today. The user does not give you a design: you propose from the existing screens, and ask only what you cannot see.

## 5. Mockup (tasks with a view)

Build a mockup only for a new screen, a new sheet or dialog, or a new layout of an existing screen. A smaller change to an existing screen (a field, a text, a state) needs no mockup: its view spec and the current snapshot images or screens are enough. When a mockup is needed, read [references/mockup.md](references/mockup.md), build it and revise it until the user approves it. A state-only task has no view and needs no mockup.

## 6. Split into tasks

Read [references/task-splitting.md](references/task-splitting.md) and plan the split. Then show it in one message: the epic, stories and tasks (one line each, by name), and below them under "Assumptions" every low-impact decision you took without asking (one line each, with its D reference). Ask one yes or no question ("Are this split and these assumptions right?"). A rejected assumption becomes a normal question; reuse agreement already given.

## 7. Write the files

Read [references/templates.md](references/templates.md) and write the backlog files. Keep every file short and concrete: bullets, no background story, and no section that does not apply.

- Write each task's `## Acceptance` as the format rule says. The criteria are the task's behavior: the main result, each edge and error case from the interview, and empty or partial states. Every criterion has a `Check` of an allowed kind; if you cannot say how it is checked, it is not a criterion yet.
- Size `complexity` from 1 to 10 by reasoning and risk: **1 to 3** follows an established contract or pattern; **4 to 6** adds bounded logic or several interacting states; **7 to 10** involves hard lifecycle, concurrency, migration or architecture decisions already settled in the plan. File count alone never makes a task harder; split multiple responsibilities instead. Turn an older `low`, `medium` or `high` into a number when you refine the task.
- `skills` lists project skills a runner must read, chosen from the planner notes' `## Project skills`.
- Verify every existing code name and path in the repo. Mark planned new symbols as new; never present them as existing APIs.
- Move the current requirements, decisions and exclusions from the planning record into the backlog files. Runners never see the record.
- Name folders and ids as the format rule says. A new epic gets an `abbr` that no other epic uses. Number stories and tasks with the next unused number, counting the `done/` folders too.

## 8. Cold read

Run one fresh agent per story, not per task. A standalone bug or improvement gets its own run. Skip known-blocked drafts until their decisions are settled. A task can be fully specified before its prerequisites merge; the dispatcher waits for them.

1. Dispatch the `cold-reader` role with a read-only run and only the paths: `Read .agents/skills/skill-planner/roles/cold-reader.md and follow it. The story is <story index path>; check the tasks <task paths>.` (for a standalone task: `The task is <path>.`). Never give it the conversation, your notes or the planning record. Start the runs for all stories at once, in one message.
   - **Claude:** the Agent tool as a general-purpose agent, with `model: sonnet`.
   - **Codex:** `codex exec --ignore-user-config -s read-only -m gpt-6.1-terra -c 'model_reasoning_effort="medium"' "<brief>"`.
   - **Antigravity:** `agy --sandbox --mode plan --model gemini-4-argon-medium -p="<brief>"`.
2. For each question it returns, either fix the task or, if it is a decision, ask the user.
3. One round is the default. Run a second round only for a task whose fix added a user decision or changed its contract, and give it only those tasks. Never run a third.

If a requirement or upstream contract changes later, mark the affected pending tasks `draft`, update them, and cold-read them again. Never treat a changed implementation as silent approval of a changed contract.

## 9. Confirm the criteria

Show the final acceptance criteria of every task in one message, grouped by task name, and ask one yes or no question ("Are these criteria right?"). These are the criteria as written after the cold read, so the user approves what runners will get. When the user changes a criterion, update the task; cold-read it again only when the change adds behavior.

Then set `status: ready` on each task that meets the [ready checklist](../../rules/backlog-format.md#when-a-task-is-ready) of the format rule. Leave the others `draft` and say exactly what is open.

## 10. Validate and hand off

- Check unique ids, numbering, paths, relative links, valid dependency ids and no cycles.
- Run the whole-split checks in [references/task-splitting.md](references/task-splitting.md). The cold reader judges tasks one by one; how the tasks fit together is your check.
- Check that every point of the original request in the planning record maps to a requirement or a stated exclusion in the backlog files.
- When every task of the effort is `ready`, delete the planning record as the [planning record](../../rules/backlog-format.md#planning-record) rule says, and include the deletion in the commit.
- Report the counts, which tasks are `ready` and which are `draft` and why, and any decision still open. Keep it short.
- **Publish.** Opening this skill authorizes the commit, the push of the planning branch and the PR. The user already approved the content in step 9.
  - With `publish: auto` in `planner_dispatcher.yaml` (the default), commit, push and open the PR without asking.
  - With `publish: ask`, show the full commit message and the exact files first and ask once, in its own bold paragraph: **Are you done with this plan? If yes, I will commit these files, push the branch, and open a PR.** A yes authorizes all three; if the user asks for changes, make them and ask again. Silence is not approval.
- Stage only the files of this plan. Commit messages follow the config's `rules` and the attribution rule in the planner notes; planning commits use the type the planner notes name.
- Before the push, run `<dart> run planner_dispatcher:dispatcher guard` on the planning branch. It checks the branch is not the base branch, the git email, the commit subjects and the diff for private data. If it lists a problem, fix it (amend the commit) and run it again; never push while it fails. Then push the branch and open the PR, with the title the planner notes give. Never push to `base_branch`, never merge and never force-push. Report the PR link.
- Tell the user the tasks become visible to `skill-dispatcher` only after this PR is merged.

## Never

- Write application code, create Linear or GitHub tickets, or run a task.
- Set a status other than `draft` or `ready`, or keep progress in an index.
- Copy global coding, git or model policies into a task.
