# Task automation: what was built and how to review it

This file explains the planner and dispatcher system added in November 2026, so someone (or an AI reviewer) can review all of it later without the original conversation. It is a record, not a rule: the rules live in `.agents/rules/` and the skills.

## Goal

Plan work once, very concretely, into tasks under `project-tasks/`. Then run those tasks with almost no questions: several runners work at the same time, each on one task, each ending as an open PR that the maintainer only has to review.

Two skills, one shared task format, one script:

```text
skill-planner  ->  project-tasks/ (ready tasks, merged to master)  ->  skill-dispatcher  ->  runners  ->  PRs
 interview, view questions,                                             asks the tool,         implementer,
 mockup, criteria, cold read                                            calls the script       tests, review
```

## What was added, by PR

| PR | Commit on master | What |
| --- | --- | --- |
| #64 | `1079fb5` | Commits made by an AI tool end with `Co-Authored-By: <tool> <model>` (no email). Changes `.agents/rules/git-commits.md`. |
| #65 | `56777e9` | One task format in `project-tasks/`: `.agents/rules/project-tasks-format.md`. All 67 existing tasks migrated to folders. The two old skills read the new format. |
| #66 | `b223b40` | `tool/dispatcher.dart` and `tool/dispatcher/`, `skill-dispatcher` with the runner roles, tests and guards. |
| this PR | see `git log` | `skill-planner` with the cold-reader role, the view-question and mockup guides, the `skills:` task field, and this file. |

To see exactly what each PR changed: `git show --stat <commit>` for the first three, and the PR diff for the last.

## The task format (PR #65)

Source of truth: `.agents/rules/project-tasks-format.md`. In short:

- A task is a folder `NN-slug/` with `index.md`, and optionally `mockup.html` and `notes.md`.
- Front matter: `id`, `status` (`draft` or `ready`), `type` (`feat`, `fix`, `improve`), `complexity`, `depends-on`, `touches`, `skills`.
- Fixed sections, and acceptance criteria as `- [ ] When <situation>, then <result>. Check: <test, golden or command>.`
- Only tasks are archived (into `done/`). Epics and stories never move, and indexes carry no status.
- **State is deduced, never written:** a task under `done/` on `master` is done; an open PR or a remote branch means it is running; `ready` with finished dependencies and no overlap with a running task means it can start.
- The migration set every old active task to `draft`: they have no `touches` or `complexity`, and nobody has run the cold read on them. The planner has to refine them before the dispatcher can pick them.

## The planner (this PR)

`.agents/skills/skill-planner/`. A multi-turn interview, so it checks its own model at the start, because a skill's `model` only lasts one turn: Opus 5.5 on Claude, GPT-6.1 Sol on Codex, Gemini 4 Argon on Antigravity, all with medium effort.

1. Reads the code, goldens and existing tasks first, and searches for duplicates.
2. Chooses how deep to go by type of work (feature with a view, without, bug, refactor).
3. Interviews the user one question at a time, each with a recommended answer.
4. For a view: asks the questions in `references/ui-questions.md`, then builds `mockup.html` (`references/mockup.md`) that the user approves with "ok" or "no".
5. Proposes the acceptance criteria; the user confirms them.
6. Writes the task folders and runs the **cold read**: a fresh read-only agent that never saw the conversation lists what it would have to ask. A task becomes `ready` only when it has no question.
7. Commits the planning branch, pushes it and opens the PR after one approval. Tasks are visible to the dispatcher only after that PR is merged.

## The dispatcher (PR #66)

`.agents/skills/skill-dispatcher/SKILL.md` talks to the user; `tool/dispatcher.dart` does the mechanical work.

Script commands (`fvm dart tool/dispatcher.dart ...`):

- `next [--skip=ID,ID]`: the first task that can start, read from `origin/master`, with the reason each other ready task waits.
- `models`: the newest model of each family for Codex and Antigravity, and a warning when a fixed model is missing or old.
- `launch <ID> --tool=claude|codex|antigravity [--implementer= --tests= --reviewer= --allow=]`: runs one task to a PR.
- `status`: runs in progress.

`launch` pipeline, in a temporary clone of `master` (`tool/dispatcher/launch_pipeline.dart`):

1. Clone, create the task branch `<type>/<id>-<slug>`, `pub get`.
2. **Implementer** stage, commit.
3. **Tests** stage, commit.
4. Project checks (`tool/agent_check.dart`); one fix attempt by the implementer.
5. **Reviewer** stage, read-only. Critical and general findings are fixed once and reviewed again (2 rounds at most). Minor findings go to the PR as notes.
6. Close the task: mark it done, write `notes.md`, move it to `done/`, fix the links. Commit.
7. Scan the diff for private data, push the branch, open the PR with the summary, the acceptance evidence and before/after golden images.
8. Delete the clone.

If a stage asks a question, fails, is denied a permission, or the review does not pass, the work is pushed as a `wip:` commit with the reason in the task's `notes.md`, no PR is opened, and the clone is deleted. If private data is found, nothing is pushed and the clone is kept.

Fixed models per stage (`tool/dispatcher/role_models.dart`): implementer and tests use Sonnet 5.5 / GPT-6.1 Terra / Gemini 4 Argon (medium); the reviewer uses Opus 5.5 / GPT-6.1 Sol (medium) and Gemini 4 Argon (high). Claude uses the `sonnet` and `opus` aliases, which always mean the newest model.

## Design decisions and why

| Decision | Reason |
| --- | --- |
| The script, not the AI tool, writes to git and opens the PR. | Measured: Claude, Codex and Antigravity can edit and run Flutter tests in their sandbox, but none can write to `.git` there (Codex protects it on purpose). It also puts the rules in code with tests: commit format, co-author line, no push to `master`, private data scan. |
| A temporary clone per task, not a `git worktree`. | A worktree keeps its commits and refs in the main `.git`, and a worker could change the main repo's hooks. A clone is self-contained and is deleted at the end. |
| Each stage is a separate run with its own model. | Matches the old orchestrator (implementer, tests, review each with a model), works the same in all three tools, and the reviewer never reviews its own work. |
| A fixed model table, not a question at launch. | Less to answer; `models` warns when it goes stale. |
| State is deduced from folders, branches and PRs. | Nothing to keep up to date, and parallel PRs never conflict on a status field. |
| Epics and stories are never archived. | New work can always be added to them. |
| The mockup is an HTML file in the task folder. | The user can click through every state and both themes before any code exists; the runner gets a reference it can read offline; the goldens remain the record of the real app. |
| A cold read before `ready`. | The only reliable way to know a task needs nobody: an agent with no context lists what it would have to guess. |
| Standing authorization to commit, push the task branch and open the PR. | The point is that the user only reviews PRs. The script limits it: never `master`, never merge, never another branch. |
| Denied permissions stop the run and come back through the dispatcher. | A headless process cannot ask the user; a run blocked on an invisible prompt is worse than "stop, tell, relaunch". |

## Tests

- `test/tool/dispatcher/`: 56 tests. The pipeline test runs a whole task against a temporary bare repo with a fake AI tool and a fake `gh`, using real git. It covers a clean PR, a stage that asks a question, review findings that stay, private data, a denied permission and a wrong git email.
- `test/architecture/ai_setup_test.dart`: guards that every runner role has a file, the reviewer and cold reader are read-only, the skills name their fixed models, and every file they mention exists.
- `fvm dart tool/agent_check.dart --skip-build` passes.

## Not verified yet

Be honest when reviewing: these were not proven end to end.

- **A real run with each CLI.** Only the reviewer role was tried for real, with Claude (it returned the findings block in about 25 seconds). The Codex and Antigravity reviewer, and every implementer and tests stage, have not run for real.
- **The GitHub steps of `launch`** (clone from GitHub, `git push`, `gh pr create`) have only run against a local bare repo and a fake `gh`.
- **Codex network** inside its sandbox. The script does the network steps itself, so this should not matter, but it was not measured.
- **Reading the final answer** of Antigravity (it is the printed output) may pick up extra text.
- **Denied permissions** are detected from Claude's JSON only. For Codex and Antigravity a blocked run depends on the report's `## Blocked` section. `--allow` works for Claude only.
- **Relaunching a `wip:` branch** (the shallow fetch and checkout) has no real-repo test.
- **No tasks are `ready` yet.** All migrated tasks are `draft`, so `next` returns nothing until the planner produces some.

## Known limits and follow-ups

- Protect `master` on GitHub (branch protection). The script uses the user's own token and must not be the only barrier.
- `skill-project-tasks` and `skill-orchestrator` are still there for free-form requests and for comparison. Delete `skill-project-tasks` once the planner has proven itself, and drop the local-tasks section of `skill-orchestrator`.
- The final PR notification is the dispatcher session itself. No desktop or Slack notification.
- The migrated tasks need `touches`, `complexity` and a cold read before they can run.

## How to review it

Give a reviewer this file and the commits above, and ask for findings as Critical, General and Minor, with `file:line`.

1. **Rules enforced in code** (`tool/dispatcher/git_publisher.dart`, `launch_pipeline.dart`): can anything push to `master`, skip the private data scan, use a non-noreply email, or leave a clone on disk?
2. **Safety of the stages** (`tool_command.dart`): do all three tools run in a sandbox with user settings off, and is the reviewer read-only?
3. **Task selection** (`task_selector.dart`, `extensions/touch_paths.dart`): can two overlapping tasks run together, or a task start before its dependencies are in `done/`?
4. **Archiving** (`task_archiver.dart`): are all links fixed after a move, including the story index?
5. **The skills and roles:** are the instructions complete, consistent with the code and with `.agents/rules/`, and free of anything that depends on a file outside the repo?
6. **Not verified list above:** which of these should be proven before the first real use?

Suggested prompt: "Review the task automation system described in `docs/task-automation.md`. Read the files it names, run `fvm flutter test test/tool/dispatcher test/architecture/ai_setup_test.dart`, and report findings as Critical, General and Minor with file and line. Start with the 'Not verified yet' list."
