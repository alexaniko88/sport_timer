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

## Architecture

### Parts and who talks to whom

```text
                    user (Spanish chat)
                     |              |
              skill-planner    skill-dispatcher        <- instructions only, run inside the AI tool
                     |              |
   writes tasks -----+              +--> fvm dart tool/dispatcher.dart next | models | launch | status
   (PR, reviewed, merged)                         |
        |                                         v
        v                               tool/dispatcher/*  (Dart, unit tested)
  origin/master: project-tasks/                   |
        ^                                         +--> git, gh          (all writes to git and GitHub)
        |                                         +--> claude | codex | agy   (one headless run per stage, sandboxed)
        +---------- read by `next` and `launch` --+
```

- The two skills only hold instructions and talk to the user. They never touch git beyond what their text says.
- `tool/dispatcher.dart` is a thin command line. Every rule lives in `tool/dispatcher/` and is tested.
- The AI tools never write to git and never open the PR. The script does, after the stages end.

### Layers of the script

| Layer | Files in `tool/dispatcher/` | Job |
| --- | --- | --- |
| Command line | `../dispatcher.dart` | Parses `next`, `models`, `launch`, `status`. Reads remote branches and open PRs, reads live runs from state files, prints JSON, sets the exit code. |
| Tasks | `task.dart`, `task_loader.dart`, `task_selector.dart`, `extensions/front_matter_text.dart`, `markdown_sections.dart`, `touch_paths.dart` | Parse `index.md` into a `Task`; load all tasks from disk or from `origin/master` (`git ls-tree` and `git show`, so a task only on another branch is never offered); decide what can start (`blockReason`, `candidates`, `next`); the overlap rule. |
| Models | `role_models.dart`, `model_catalog.dart` | The fixed model and effort per tool and role; the co-author text (`attribution`); the `models` command parses `codex debug models` and `agy models` and warns about stale fixed models. |
| One stage | `tool_command.dart`, `stage_runner.dart`, `stage_report.dart`, `review_gate.dart` | Build the exact command line per tool and role; start the process with a timeout (45 min); read the final answer (Claude: JSON `result`; Codex: `-o` file; Antigravity: stdout); collect Claude's `permission_denials`; parse the `## Commit / Summary / Evidence / Open notes / Blocked` report; parse the reviewer's JSON findings and decide pass, fix or blocked. |
| The clone | `run_workspace.dart`, `command_runner.dart` | Temporary clone in `<system temp>/sport-timer-runs/<ID>/repo`, task branch, repo-local noreply git identity, `.runner/` excluded from git, `state.json` (stage, pid) for `status`, cleanup. |
| Git and GitHub | `git_publisher.dart`, `pr_description.dart`, `task_archiver.dart` | Commit with format and co-author checks, private data scan, push that refuses `master`/`main`, `gh pr create`, PR text with before/after golden links, move the task to `done/` and fix links. |
| Orchestration | `launch_pipeline.dart` | The state machine of one run (see "`launch` pipeline" above). Returns a `RunResult` (`pullRequest`, `blocked`, `failed`). |

Injection points for tests: `RunCommand` (every shell command) and `RunProcess` (every AI tool process). The pipeline test replaces both.

### Data that moves between the parts

| From | To | What |
| --- | --- | --- |
| Planner | `project-tasks/<...>/NN-slug/` | `index.md`, optional `mockup.html`, `notes.md`; opened as a PR on `feat/plan-<topic>`. |
| `next` | Dispatcher skill | JSON: `next` (id, title, path, type, complexity, dependsOn, touches, skills, branch), `alsoReady`, `waiting` (id to reason). |
| Dispatcher skill | `launch` | `<ID> --tool=... [--implementer --tests --reviewer --allow]`. |
| `launch` | Stage | A fixed prompt: read `roles/<role>.md`, the task is `<path>`, plus an extra instruction (review the diff, or the findings to fix). |
| Stage | `launch` | Final message with the report sections (reviewer: a fenced `json` block of findings). |
| `launch` | Dispatcher skill | One line `RESULT {taskId, outcome, prUrl, message, tail, keptWorkspace}`; exit 0 PR, 2 blocked, 1 failed. |
| Run | `<temp>/sport-timer-runs/<ID>/state.json` | `taskId, tool, stage, pid, updated`; `status` and `next` read it and check the pid with `kill -0`. |

### The command line of each stage (`tool_command.dart`)

| | Claude | Codex | Antigravity |
| --- | --- | --- | --- |
| Program | `claude -p` | `codex exec` | `agy` |
| Model and effort | `--model <alias> --effort <level>` | `-m <id> -c model_reasoning_effort="<level>"` | `--model <id>` (the level is part of the id) |
| User config off | `--setting-sources project` | `--ignore-user-config` | not available; `--sandbox` only |
| No session kept | `--no-session-persistence` | `--ephemeral` | not available |
| Implementer and tests | `--permission-mode acceptEdits` | `-s workspace-write` | `--mode accept-edits` |
| Reviewer (read-only) | `--permission-mode plan` | `-s read-only` | `--mode plan` |
| Allowed shell | `--allowedTools` read-only git and file commands, plus `Bash(fvm:*)` for implementer and tests, plus `--allow` | sandbox decides | sandbox decides |
| Unknown permission | `--permission-prompts none`: denied and listed in `permission_denials` | denied by the sandbox | denied by the sandbox |
| Final answer | JSON `result` on stdout | `-o <file>` | stdout |
| Timeout | the script kills the process after 45 minutes | same | `--print-timeout` plus the script |

### Outcomes and what is left behind

| Situation | Commit | Push | PR | Clone |
| --- | --- | --- | --- | --- |
| Everything passes | one per stage, plus `docs: close task <id>` | task branch | opened | deleted |
| A stage reports `## Blocked`, a stage fails or times out, a permission is denied, the checks still fail after one fix, the review still has critical or general findings after 2 rounds | `wip: <id> stopped`, reason appended to `notes.md` under `## Blocked` | task branch | none | deleted |
| Private data found in the added lines (normal or `wip` push) | made locally | **none** | none | **kept**, path in `RESULT.keptWorkspace` |
| Push or `gh pr create` fails | made locally | maybe | none | **kept** |
| Wrong git email, or a run for that id already exists | none | none | none | none (nothing was created, or it is cleaned) |

### Invariants the code enforces

Each one has a test in `test/tool/dispatcher/`. A reviewer should try to break them.

1. Nothing is pushed to `master` or `main` (`GitPublisher.push`).
2. A commit subject is `<type>: <description>`, lowercase, no final period, at most 100 characters (`CommitMessage.problem`; `wip` is also allowed).
3. Every commit has `Co-Authored-By: <tool> <model>` and no email (`LaunchPipeline._commit`).
4. The git identity of the clone must end with `@users.noreply.github.com`, or nothing starts (`RunWorkspace.prepare`).
5. The added lines are scanned before any push for a local home path, a private key, a GitHub token, a `sk-` key and a company email (`DiffScanner`). A hit blocks the push and keeps the clone.
6. A review without a readable findings block never counts as a pass (`ReviewGate.parse` returns null, the run fails).
7. The reviewer is read-only on all three tools (`ToolCommand.build`, guarded by `ai_setup_test.dart`).
8. Two tasks whose `touches` overlap never run together, and an empty `touches` overlaps everything (`TaskSelector`, `TouchPaths.overlaps`).
9. A task starts only when it is `ready`, all its dependencies are under `done/` on `origin/master`, and it has no branch, open PR or live run (`TaskSelector.blockReason`).
10. The clone is deleted on every ending except a leak or a failed push (`RunWorkspace.cleanup`, `LaunchPipeline._keep`).
11. After a move to `done/`, every relative link in the task and in other task files is rewritten (`TaskArchiver`).
12. The PR description has no attribution line (`PrDescription`).

### Where each rule is written

| Rule | Written in | Enforced by |
| --- | --- | --- |
| Task format, ready checklist, overlap | `.agents/rules/project-tasks-format.md` | `task_selector.dart` and the cold read |
| Commit and branch names, co-author | `.agents/rules/git-commits.md` | `CommitMessage`, `LaunchPipeline._commit` |
| Dart style | `.agents/rules/dart-style.md` | Runner roles read it; `fvm dart tool/agent_check.dart` checks format and analyze |
| What each runner does and reports | `skill-dispatcher/roles/*.md`, `references/project-overrides.md` | `StageReport`, `ReviewGate` parse the reports |
| What the planner asks and writes | `skill-planner/SKILL.md`, `roles/cold-reader.md`, `references/*.md` | `ai_setup_test.dart` (files exist, models named, read-only roles) |
| Standing authorization to push and open PRs | `skill-dispatcher/SKILL.md`, `CLAUDE.md` | The script's own limits (invariants 1 to 5) |

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

## Decision log (the grill)

Rebuilt from the planning conversation, in order, so a reviewer can see what was asked, what the maintainer decided and what it changed. It is a summary, not a transcript. The conversation was in Spanish; the original request, in short: rethink `skill-project-tasks`, a planner that grills and writes concrete tasks, and a dispatcher that runs several tasks and ends with open PRs.

| # | Topic | What was decided (maintainer's words, in short) | Effect in the design |
| --- | --- | --- | --- |
| 1 | Language | Talk in Spanish, one question at a time; the skills, rules and docs stay in English. | The planner interviews one question at a time with a recommended answer. All files are English. |
| 2 | Old or new skill | "Nueva": a new skill, not a rewrite. The old ones stay until the new ones are proven; the maintainer deletes them later. | `skill-planner` and `skill-dispatcher` were added next to `skill-project-tasks` and `skill-orchestrator`. The old ones only read the new format. |
| 3 | Hierarchy | The task is the measurable unit. A task is inside a story, a story inside an epic. | Epic, story, task folders. Only tasks are archived; epics and stories never move. |
| 4 | Who decides what | The planner only plans. The orchestrator (later: dispatcher) goes its own way and decides which task to take. | No state written by the planner. State is deduced from `done/`, branches and PRs. |
| 5 | Best practices | Look at current good practice for this kind of system. | Cold read, deduced state, fixed sections, a ready checklist. |
| 6 | Acceptance criteria | They come out of the grill. The maintainer does not write them, the planner proposes and the maintainer confirms. | Planner step 7; the `When..., then.... Check:...` form so each one can be checked. |
| 7 | UI tasks | First look at what exists. The maintainer gives no design. The planner must show an example visually, and the answer is "ok" or "no". | `references/ui-questions.md` (look first, ask second) and `references/mockup.md`. |
| 8 | Mockup | An HTML mockup, kept inside the task folder, plus golden snapshots after the work. | `mockup.html` next to `index.md`; goldens stay the record of the real app. |
| 9 | Task as folder | Tasks become folders; the migration of the old ones is separate work. | Format v2 and a one-off migration of 67 tasks (PR #65). All active ones became `draft`. |
| 10 | Several AI tools | Launch with Codex, Antigravity or Claude; ask the tool each time. Everything lives in this repo, nothing from `my-dev-env`. | `--tool=` option, one table of models, no outside script. |
| 11 | PR content | PR descriptions with visuals. | Before and after golden images in the PR (`PrDescription`). |
| 12 | Co-author | Add `Co-Authored-By` with the tool and model, no email. Apply the rule now. | `git-commits.md` changed (PR #64); the script writes the trailer; no attribution line in PR bodies. |
| 13 | Runner behavior | "Runners": one task at a time per runner, a loop: pick, ask the tool, launch, "another task?". Up to 3 at once. | The loop in `skill-dispatcher/SKILL.md`; `status` and `next` count live runs. |
| 14 | Names | The dispatcher skill is called `skill-dispatcher`. Its own model is the newest Sonnet. | Frontmatter model `claude-sonnet-5-5`. |
| 15 | PR count | Fewer PRs: three stacked ones. | #65 format and migration, #66 dispatcher, #67 planner (plus #64 for the co-author rule). |
| 16 | Archiving | Never archive epics or stories. | `TaskArchiver` moves tasks only. |
| 17 | Ask Opus | Ask the model question to Opus 5.5 in a subagent. | Planner model table; planner models are Opus 5.5, GPT-6.1 Sol, Gemini 4 Argon, medium. |
| 18 | Commit first, then grill the run | Commit what exists, then grill the process: implementer, another model reviewing, peer review like `skill-orchestrator`. | Three stages: implementer, tests, reviewer, each its own run. |
| 19 | Models per role | Predefine all of it: implementer and tests intermediate, reviewer more powerful (Opus 5.5, Sol 6.1, Argon high). Medium effort everywhere except Argon high. | `role_models.dart` table; `models` warns when it is stale. |
| 20 | Script drives the runner | "ok" to a script conducting the runner. | `launch` is a script pipeline, not a prompt. |
| 21 | Questions from runners | Runners cannot ask live, so every question and every sandbox block must be redirected to the dispatcher, or runs will be blocked. | Headless live routing is not possible, so: deny, stop, report through the dispatcher, relaunch (`--allow` for Claude). |
| 22 | Try it | "Vale, probamos así, a ver qué tal." | Measured with the real CLIs: all three edit and test in their sandbox; none can write to `.git`. |
| 23 | Git ownership | (Consequence of 22) the script does every git and GitHub write. | `GitPublisher`, the commit checks and the diff scan. |
| 24 | Authorization | Commit, push and open the PR for the planned PRs "all at once"; for dispatcher runners, commit, push their own task branch and open the PR without asking. Never `master`, never merge. | Standing authorization text in the skill and `CLAUDE.md`; invariant 1. |
| 25 | Privacy | Never the company email, never a local path with the username, in a personal repo. | Noreply email check; `DiffScanner`; nothing pushed on a leak. |
| 26 | Clean machine | Nothing should stay on the disk after a run. | Temporary clone deleted on every ending except a leak or failed push. |
| 27 | Scope of testing | "The big tests, later. Finish the implementation." | The "Not verified yet" list. |
| 28 | This document | Write a Markdown file in the project that lets the maintainer launch a review later. | This file. |

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

### Where to look, by file

| Area | Files | Test |
| --- | --- | --- |
| Format and parsing | `.agents/rules/project-tasks-format.md`, `task.dart`, `extensions/front_matter_text.dart`, `markdown_sections.dart` | `test/tool/dispatcher/extensions/`, `task_selector_test.dart` |
| Selection and overlap | `task_selector.dart`, `extensions/touch_paths.dart`, `task_loader.dart` | `task_selector_test.dart` |
| Models | `role_models.dart`, `model_catalog.dart` | `model_catalog_test.dart`, `ai_setup_test.dart` |
| One stage | `tool_command.dart`, `stage_runner.dart`, `stage_report.dart`, `review_gate.dart` | `stage_test.dart` |
| Git and PR | `git_publisher.dart`, `pr_description.dart`, `task_archiver.dart`, `run_workspace.dart` | `git_publisher_test.dart`, `launch_pipeline_test.dart` |
| Whole run | `launch_pipeline.dart`, `../dispatcher.dart` | `launch_pipeline_test.dart` (real git, temporary bare repo, fake tool and fake `gh`) |
| Skills and roles | `skill-planner/**`, `skill-dispatcher/**`, `CLAUDE.md` | `ai_setup_test.dart` |

### Things a reviewer should question on purpose

These are places where the design chose something that is easy to doubt. They are not known bugs.

- **Cautious overlap.** An empty `touches` blocks every other running task, and a glob counts as its folder. This is safe but can serialize work that could run together.
- **Branch names decide "running".** `busyIdsFromBranches` matches the prefix `<type>/<id>-`. A branch made by hand with that prefix hides the task from `next`.
- **Denial detection is Claude only.** For Codex and Antigravity, a blocked permission shows up only if the runner writes `## Blocked`, otherwise as a generic failed stage with the output tail.
- **Antigravity answer.** The final message is the whole stdout, so extra text before the report sections could confuse `StageReport.parse` (it reads sections by heading, which should tolerate it).
- **Reviewer rounds.** Two reviews at most. A third problem is never fixed automatically; it becomes a `wip:` branch.
- **One fix attempt for the checks.** `agent_check.dart --skip-build` runs in the clone; the debug builds are skipped on purpose, so a change in `android/`, `ios/` or `pubspec.yaml` is not built by the run.
- **Scan patterns.** `DiffScanner` knows five patterns. It does not know other secret formats. Branch protection and the maintainer's review are the next barriers.
- **Wide `--allow`.** `--allow="Bash(<program>:*)"` gives a whole program to a Claude run. The dispatcher skill must ask before using it.
- **Time.** A stage times out after 45 minutes; a whole run has no global limit.
- **The planner depends on the user.** The cold read catches missing detail but not a wrong decision the maintainer approved. The mockup "ok" is the guard for views.

### Commands to reproduce

```bash
fvm flutter test test/tool/dispatcher test/architecture/ai_setup_test.dart   # unit and guard tests
fvm dart tool/agent_check.dart --skip-build                                    # format, analyze, mirrored tests
fvm dart tool/dispatcher.dart next                                             # nothing until a task is ready
fvm dart tool/dispatcher.dart models                                           # stale model warnings
fvm dart tool/dispatcher.dart status                                           # live runs
git log --oneline 1079fb5^..HEAD                                               # the commits of this work
```

### Suggested review prompts

Full review:

"Review the task automation system described in `docs/task-automation.md`. Read the files it names, run `fvm flutter test test/tool/dispatcher test/architecture/ai_setup_test.dart`, and report findings as Critical, General and Minor with file and line. Start with the 'Not verified yet' list, then try to break each invariant under 'Invariants the code enforces'."

Focused reviews, one per area (each can run on its own):

- "Read `tool/dispatcher/launch_pipeline.dart` and `git_publisher.dart`. Find any path where something is pushed to `master`, a leak is pushed, or a clone stays on disk by accident."
- "Read `tool/dispatcher/tool_command.dart` and the three runner roles. Check that the reviewer cannot write on any tool, and that user settings cannot change a run."
- "Read `skill-planner/SKILL.md` and its references. Check that a runner would never need to ask a question about a task that passed the cold read, and that the instructions agree with `.agents/rules/project-tasks-format.md`."
- "Compare this document with the code. List every claim that is no longer true."
