---
id: PLD-05-02
status: draft
type: feat
complexity: medium
executor: orchestrator
depends-on: [PLD-05-01]
touches:
  - project-tasks/**
  - docs/tasks/**
  - .plan-dispatcher/config.toml
  - .agents/rules/project-tasks-format.md
  - .agents/skills/skill-orchestrator/SKILL.md
  - .agents/skills/skill-project-tasks/SKILL.md
  - .agents/skills/skill-project-tasks/references/templates.md
  - .agents/skills/skill-integration-tests/SKILL.md
  - .agents/references/plan-dispatcher-project.md
  - test/tool/fixtures/plan_dispatcher_check_cases.json
  - test/tool/test_backlog_integrity.py
  - .github/workflows/plan-dispatcher.yml
  - .agents/rules/git-commits.md
  - CLAUDE.md
skills: []
---

# Move the preserved backlog to docs/tasks

Story: [Sport Timer cutover](../index.md)

Epic: [PlanDispatcher](../../../index.md)

## Goal

Rename `project-tasks/` to `docs/tasks/` in one PR, keeping every file, ID, status and attachment, and point every live reader to the new root. This task archives itself at the new root, so no frozen engine run ever moves its own backlog.

## Context

- The whole tree moves, including this epic, `planning/` records, `done/` folders, `mockup.html` files and images (171 tracked files on 2026-11-08). `.DS_Store` files are untracked and are not moved.
- After [PLD-05-01](../01-switch-workflow-engine/index.md), the packaged planner and dispatcher read the root from `project.backlog` in `.plan-dispatcher/config.toml`; they need no edit and must not be edited (they are checksum-managed).
- Live files that name `project-tasks/` today: `CLAUDE.md`, `.agents/rules/project-tasks-format.md` (front matter `paths:` and text), `.agents/skills/skill-orchestrator/SKILL.md`, `.agents/skills/skill-project-tasks/SKILL.md` and `references/templates.md`, `.agents/skills/skill-integration-tests/SKILL.md`, `.agents/rules/git-commits.md` (the task-branch sentence PLD-01-01 adds, "a branch for a task under `project-tasks/`"), and possibly `.agents/references/plan-dispatcher-project.md` (PLD-05-01). `tool/agent_check.dart` has no `project-tasks/` rule; `test/tool/agent_check_test.dart:26` uses `project-tasks/x.md` only as a "no checks" example and stays as it is.
- One relative link is already broken before the move: `project-tasks/developer-tools/stories/01-purge-local-activity/02-add-developer-page/index.md` links `goldens/developer_tools.png`, a planned output of that task.
- Inside the backlog, the files that still name `project-tasks/` when this task runs are this task itself, `plan-dispatcher/contracts.md` (one sentence about the temporary pre-cutover source), the story 5 index (one bullet describing this move) and `experiments/stories/02-compare-local-vs-claude/01-run-comparison/index.md` (a path to `done/` folders). Earlier PLD tasks are archived in `done/` by then. No pending PLD task (PLD-05-03, PLD-06-01, PLD-06-02) has a `project-tasks/` entry in `touches` (checked on 2026-11-08); if one appears, rewrite it in step 5.
- Read [the epic contracts](../../../contracts.md) headings "Task model" and "Configuration schema 1".

## Contract

Consumed: `tasks.load_tasks` (PLD-01-02, contracts "Task model"), imported from `--source tool/plan_dispatcher/src` like the parity test, with a `SubprocessRunner` for the `ref` form. `tasks.readiness_errors` is used only by the `--check-ready` flag: many tasks are `draft` or in the legacy layout, and the default run checks the move and links, not readiness.

New here: `test/tool/test_backlog_integrity.py`, a stdlib `unittest` script run as `python3 test/tool/test_backlog_integrity.py (--source tool/plan_dispatcher/src | --installed) [--check-ready] [--compare-ref REF --old-root NAME --moved-task PATH]`. `--installed` loads the package from `.plan-dispatcher/venv` the same way as the parity test (contracts "Planned tests and invocation"). It reads `project.backlog` from `.plan-dispatcher/config.toml` with a regex (no TOML parser needed) and checks:

1. the `project.backlog` folder exists and `load_tasks(root, backlog)` returns at least one task; every task loads, IDs are unique, and every `depends-on` ID exists;
2. every relative Markdown link `](path)` in `<backlog>/**/*.md` (not `http:`, `https:`, `mailto:` or `#anchor`; the part after `#` is ignored) resolves to an existing file. Two exceptions: a link inside a `done/` folder, a `planning/` record or a `notes.md` whose target is outside the backlog root is historical evidence and is not checked (its target may have been retired later), and a broken link inside the backlog root from such a file is printed as a `warning:` line but does not fail; and the paths in `KNOWN_BROKEN = {"<backlog>/developer-tools/stories/01-purge-local-activity/02-add-developer-page/index.md": ["goldens/developer_tools.png"]}`, each with a one-line reason comment;
3. with `--compare-ref REF --old-root NAME --moved-task PATH`: `PATH` is the moved task's folder under the new root, before archiving (for this task `docs/tasks/plan-dispatcher/stories/05-sport-timer-cutover/02-move-task-backlog`). The file list `git ls-tree -r --name-only REF -- NAME`, with the prefix `NAME/` replaced by `<backlog>/`, equals `git ls-files --cached --others --exclude-standard <backlog>`, with these allowed differences only: files under `PATH` appear under its `done/` sibling (`<parent of PATH>/done/<folder>`) instead, and that `done/` folder may have one extra `notes.md`. Statuses at REF come from `load_tasks(root, NAME, ref=REF, runner)`; every task ID present at REF is present now with the same `status`, except the moved task (`done`). The old root name is passed as an argument so the script file itself never contains the old path.

4. with `--check-ready`: every task with `status: ready` and `executor: plan-dispatcher-v1` has an empty `readiness_errors(task)`; each failure is printed as `<id> <path>: <codes>` (used by PLD-05-03).

Exit 0 when all pass, 1 otherwise. The script is permanent (it keeps guarding links); `--compare-ref` is only used by this task.

## Behavior

Do these in order:

1. Precondition: `.plan-dispatcher/venv/bin/pd status --json` shows no entry in `data.runs` whose `state` is `active`, `running`, `interrupted`, `blocked` or `pending_publication` (contracts "CLI" and `run_state`). `done` and `released` runs are fine, because their folders stay listed forever. If any other run is listed, stop before changing anything and report it; do not release or adopt it. This is a manual precondition the orchestrator runs, not an automated test.
2. `git mv project-tasks docs/tasks` (create `docs/` if needed; it already exists).
3. Set `project.backlog = "docs/tasks"` in `.plan-dispatcher/config.toml`.
4. Links that leave the backlog root (they start with enough `../` to exit it, for example `../../.agents/...` from the epic) gain one extra `../`, because `docs/tasks` is one level deeper. Links inside the tree do not change. Every link in a live file (outside `done/`, `planning/**` and `notes.md`) whose target no longer exists, because PLD-05-01 or an earlier task deleted it (for example the old `skill-dispatcher/references/project-overrides.md`, `skill-planner/references/*`, `skill-dispatcher/roles/*`, `tool/dispatcher/*` or `docs/task-automation.md`), becomes plain backticked text naming the old path, so the link check passes without inventing a new target. Links inside `done/`, `planning/**` and `notes.md` get only the extra `../` and are otherwise left as they are.
5. Live text: in every file outside `done/` folders, `planning/` records and `notes.md` files, replace the path prefix `project-tasks/` with `docs/tasks/` (prose, `touches`, commands) where it is not preceded by `-`; `skill-project-tasks/` (the skill folder name) is never changed. Three exceptions: this task's own `index.md` keeps its text (it is archived in step 9, and its commands describe the move); the `contracts.md` sentence about "the temporary pre-cutover `project-tasks/` source" becomes "the former `project-tasks` root (moved by PLD-05-02)"; the story 5 index bullet for PLD-05-02 becomes "PLD-05-02 moved the former `project-tasks` root to `docs/tasks/` …". Bare `project-tasks` without a slash (for example the rule file name `project-tasks-format.md`) is not changed. Text inside `done/`, `planning/**` and `notes.md` is historical and is not changed, except for step 4 links. Managed skill files under `.agents/skills/skill-planner/` and `.agents/skills/skill-dispatcher/` are never edited; if one names `project-tasks/`, stop and report it as a package defect.
6. Update the live files listed in Context the same way. In `.agents/rules/project-tasks-format.md` the `paths:` glob becomes `docs/tasks/**`; the file name stays. In `.agents/rules/git-commits.md` the task-branch sentence names `docs/tasks/`.
7. In `test/tool/fixtures/plan_dispatcher_check_cases.json`, the documentation-only case input `project-tasks/x.md` becomes `docs/tasks/x.md`; its expected result stays "no checks". Neither the Dart validator nor the Sport Timer config has a rule for `docs/` or `project-tasks/` paths (checked on 2026-11-08), so both still plan no checks. `test/tool/agent_check_test.dart:26` has its own hand-written input and is not changed. Both the parity test and `fvm flutter test` must still pass.
8. In `.github/workflows/plan-dispatcher.yml`, add a step `python test/tool/test_backlog_integrity.py --source tool/plan_dispatcher/src` after the parity step, and add `docs/tasks/**` and `test/tool/test_backlog_integrity.py` to its `paths` filter, so the permanent link check runs in CI. PLD-06-02 switches this step to `--installed`.
9. Archive this task: `git mv docs/tasks/plan-dispatcher/stories/05-sport-timer-cutover/02-move-task-backlog docs/tasks/plan-dispatcher/stories/05-sport-timer-cutover/done/02-move-task-backlog`, set `status: done`, add one `../` to every relative link in its `index.md`, write `notes.md` with the evidence for each criterion, and change the story index link to `done/02-move-task-backlog/index.md`.

## Decisions

- One permanent stdlib test checks IDs, dependencies and links; the one-time file-list comparison is a flag of the same script. This avoids an ad hoc helper and keeps link checking after the move.
- Historical text keeps the old path; only links are repaired there.

## Out of scope

- Editing managed skill assets, changing any task's requirements, renumbering, or approving draft tasks.
- Fixing the pre-existing broken golden link.
- App code, goldens or ARB files.

## Files and tests

Changed: the whole moved tree, the live files in `touches`, and the new `test/tool/test_backlog_integrity.py`.

Literal commands, from the repository root:

- `.plan-dispatcher/venv/bin/pd status --json` (precondition, before step 2)
- `python3 test/tool/test_backlog_integrity.py --source tool/plan_dispatcher/src --compare-ref $(git merge-base HEAD origin/master) --old-root project-tasks --moved-task docs/tasks/plan-dispatcher/stories/05-sport-timer-cutover/02-move-task-backlog` (the merge base is the commit the move starts from, so tasks merged later are not counted; no `git add -A` is needed, because `git mv` stages the rename and the script lists untracked files itself)
- `python3 test/tool/test_backlog_integrity.py --source tool/plan_dispatcher/src`
- `python3 tool/plan_dispatcher/tests/run_tests.py`
- `python3 test/tool/test_plan_dispatcher_parity.py --source tool/plan_dispatcher/src`
- `git grep -n '^backlog = "docs/tasks"' .plan-dispatcher/config.toml` (prints exactly one line; `pd next` reads the remote base snapshot, which has no `docs/tasks/` until this PR merges, so the working-tree integrity run above is the reader check)
- `git grep -n -E "(^|[^-])project-tasks/" -- . ':(exclude,glob)docs/tasks/**/done/**' ':(exclude,glob)docs/tasks/planning/**' ':(exclude,glob)**/notes.md' ':(exclude)test/tool/agent_check_test.dart'` (must print nothing; this task is under `done/` by then)
- `fvm flutter test`
- `fvm dart tool/agent_check.dart --skip-build`

No app launch, device test, golden or ARB change.

## Acceptance

- [ ] When the move is done, then every file and task ID from the merge base with `origin/master` exists under `docs/tasks/` with the same status, and every checked relative link resolves except the listed known one. Check: the `--compare-ref` command in Files and tests.
- [ ] When the dispatcher reads tasks after the move, then it uses `docs/tasks/` and no live file names `project-tasks/`. Check: the plain `test_backlog_integrity.py` run loads at least one task from `docs/tasks/`, the `backlog` `git grep` prints one line, and the `project-tasks/` `git grep` scan prints nothing.
- [ ] When this task is completed, then it is archived at `docs/tasks/plan-dispatcher/stories/05-sport-timer-cutover/done/02-move-task-backlog/` with `status: done` and the story index links there. Check: the `--compare-ref` run (it expects exactly that location), the link check and the new CI step in `plan-dispatcher.yml`.
- [ ] When `pd status` lists a run in state `active`, `running`, `interrupted`, `blocked` or `pending_publication` before the move, then the orchestrator stops before step 2 and nothing is changed. Check: the precondition output recorded in `notes.md`.
