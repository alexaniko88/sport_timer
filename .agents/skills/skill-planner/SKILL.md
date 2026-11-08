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

- **Work quietly.** Do not narrate reads, searches, writes or checks. Messages are questions, blockers, or the final summary in step 10. A question may include the short decision checkpoint below, the proposed split in step 6, or the criteria in step 7. Show the mockup when step 5 requires it.
- **One question per message.** Never show two questions at once, not even as a numbered list. With a question dialog, put exactly one question in each call. Wait for the answer before the next.
- **Atomic questions.** Ask for one decision in short, plain words, with at most two short lines of context. Split independent decisions; alternatives for the same decision can stay together. Never hide several decisions inside one yes/no question.
- **Recommendations.** Recommend only when repository evidence, an agreed constraint or official documentation supports it; give the reason in one line. Let "yes" accept that recommendation. Present genuinely open product preferences neutrally. A proposal is not a decision until the user accepts it.
- **Checkpoints.** At a natural boundary or when the interview becomes long, briefly state the settled decisions and remaining topics, then ask one question about continuing. No fixed question limit. A pause preserves open questions; it does not accept defaults or complete the interview.
- **Always allow a typed answer.** The user must be able to answer in their own words when none of your options fits. With a question dialog, keep a last choice such as "Something else (I will type it)", and never remove the tool's own "Other" choice. If the dialog cannot take typed text, or the answer is open (a name, a number, a description), ask as plain chat text instead of a dialog.
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

Read [references/questions.md](references/questions.md) before interviewing. It defines the saved record, coverage checks, question filter, reconciliation and stopping rule. Keep one simple decision per question; do not reduce question count by bundling decisions.

Research first, activate only relevant coverage, and record each answer immediately. Resolve contradictions and blocking decisions first. Routine implementation details follow verified repository patterns; unconfirmed product assumptions remain open. Future ideas stay provisional and outside the current scope.

## 4. View questions (tasks with a view)

Read [references/ui-questions.md](references/ui-questions.md). Look at what exists first and fit the design to the app as it is today. The user does not give you a design: you propose from the existing screens, and ask only what you cannot see.

## 5. Mockup (tasks with a view)

Read [references/mockup.md](references/mockup.md). Build the mockup beside the planning record before the task split exists. Show it to the user: publish it as a private Artifact when available, otherwise open the local file. Revise until approved. After the split, keep one approved reference in its owning story (or standalone task) and link visual tasks to it. A ViewModel/state-only task has no view and needs no mockup.

## 5a. Interview completeness review

Before splitting, run one fresh read-only agent using [roles/interview-reviewer.md](roles/interview-reviewer.md). Give it only the role path and the `planning.md` path, not the conversation or the planner's conclusions. Use the same provider/model selection as the cold reader in step 9, with this brief: `Read .agents/skills/skill-planner/roles/interview-reviewer.md and follow it. The planning record is <path>.`

The reviewer checks the whole request for omissions before they can disappear between tasks. Investigate factual findings yourself; ask only unresolved user decisions through the question filter. Record the findings and their resolution. If scope or behavior changes later, reopen the affected coverage and review outcome; rerun the independent check when the change invalidates it. An unresolved material finding keeps affected work `draft`. This review does not replace the per-task cold read.

## 6. Split into tasks

Read [references/task-splitting.md](references/task-splitting.md). Plan small building blocks first, then explicit feature assembly tasks. Each task is one complete responsibility plus its relevant tests, one PR and one runner run; it need not expose a user-visible feature. File count is a sizing signal, not a split rule.

- Define contracts, consumers, wiring ownership, exact affected paths and checks before dispatch. Keep each block's failures and boundary behavior with that block.
- Resolve investigations during planning. Unknown-dependent tasks stay `draft`; no findings-only investigation goes to the implementation dispatcher.
- Keep implementation tests with their block. Plan device integration tests independently, outside this dispatcher's tasks. Read the runner boundaries in [project-overrides.md](../skill-dispatcher/references/project-overrides.md) when choosing checks; do not add app launches or custom helper tooling as acceptance checks.
- For a new backlog, show the epic, story and task split and get the user's agreement before you write it. Reuse agreement already given.

## 7. Acceptance criteria

You propose the criteria from the interview and the user confirms them. Do not ask the user to write them. Show the list with one yes or no question ("Are these criteria right?") and nothing else in that message.

- One line each: `- [ ] When <situation>, then <result>. Check: <test, golden or command>.`
- Cover the main result, each edge case and error case from the interview, and empty or partial states. Make every proposed product behavior visible in this review; never bury an unconfirmed assumption in the criteria as though it were agreed.
- Every criterion must be checkable by a test, a golden image or a command a runner can run. If you cannot say how it is checked, it is not a criterion yet.

## 8. Write the files

Read [references/templates.md](references/templates.md) and write the task folders.

- Fill every field of the front matter. Size `complexity` by reasoning and risk: **low** follows an established contract/pattern; **medium** introduces bounded logic or several interacting states; **high** involves difficult lifecycle, concurrency, migration or architecture decisions already settled in the plan. A small timer change is not automatically high; file count alone never makes it high. Split multiple responsibilities instead of labeling an oversized task high.
- `touches` prefers exact paths, including tests and golden files. Use a narrow glob only when necessary, and `lib/l10n/**` when strings are added. Shared snapshot harness edits count as overlap. Do not list `test/snapshots/README.md` or the indexes.
- `skills` lists project skills a runner must read, for example `skill-fl-chart`. Do not add the integration-test skill to ordinary implementation tasks.
- Fill `## Decisions` with what the user decided and why, and `## Out of scope` with what the task does not do. `## Files and tests` says what is created or changed and which tests are written.
- Verify every existing code name/path in the repo. Explicitly mark planned new symbols and locations in the Contract; never present them as existing APIs. Use relative Markdown links and repository-relative paths; no local usernames, absolute paths or secrets.
- Transfer the current requirements and decisions from the planning record into the files below, following its lifecycle in the format rule. Runners must not need the interview record.
- Keep shared decisions in the epic or story and link to them. Each task still needs enough context to stand alone, because a runner sees only the task, its parents and the repo.
- A new epic gets an `abbr` that no other epic uses. Number stories and tasks with the next unused number. Do not mix the old and new layouts.

## 9. Cold read

For each fully specified task being considered for `ready`, run a fresh agent that has never seen this conversation. It reads the task, its parents, dependency contracts and repo, and lists what it would have to ask. Skip known-blocked drafts until their decisions are settled. A task can be fully specified before its fixed-contract prerequisites merge; the dispatcher waits for those merges.

1. Dispatch the `cold-reader` role with a read-only run. Give it only the task path: `Read .agents/skills/skill-planner/roles/cold-reader.md and follow it. The task is <path>.` Never give it the conversation, your notes or the interview.
   - **Claude:** the Agent tool as a general-purpose agent, with `model: sonnet`.
   - **Codex:** `codex exec --ignore-user-config -s read-only -m gpt-6.1-terra -c 'model_reasoning_effort="medium"' "<brief>"`.
   - **Antigravity:** `agy --sandbox --mode plan --model gemini-4-argon-medium -p="<brief>"`.
2. For each question it returns, either fix the task or, if it is a decision, ask the user. Then run it again on the changed task.
3. Do at most three rounds. A bug, refactor or tooling task gets one light pass.
4. Set `status: ready` only when the cold reader has no question left (and, for a view, the mockup is approved). Otherwise leave the task `draft` and say exactly what is open.

If a requirement or upstream contract changes, mark affected pending tasks `draft`, reconcile their contracts, coverage, paths and checks, and cold-read them again before restoring `ready`. Resolve a completed experiment in the same way. Never treat a changed implementation as silent approval of a changed contract.

## 10. Validate and hand off

- Check unique ids, numbering, paths, relative links, valid dependency ids and no cycles. Follow the whole-plan checks in [references/task-splitting.md](references/task-splitting.md): requirements have owners and checks, contracts fit, every piece has a consumer, wiring is owned, and the delivery order preserves a working app. Compare related tasks together; passing individual cold reads alone does not prove the pieces fit.
- When every task of the effort is `ready`, delete the planning record and everything else that only served the planning, as the [interview record](../../rules/project-tasks-format.md#interview-record) rule says, and include the deletion in the commit. Check that no file still links to them.
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
