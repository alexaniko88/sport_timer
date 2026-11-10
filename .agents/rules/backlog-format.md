---
paths:
  - "docs/backlog/**"
---

# Backlog format

Single source for how the backlog is laid out and how a task is written. Skills and roles link to this file and never copy it.

The backlog lives in `<tasks_dir>/`, where `<tasks_dir>` is the `tasks_dir` value of `planner_dispatcher.yaml` (default `docs/backlog`). It is a path relative to the project root. The `paths:` above only matches the default, so with another `tasks_dir` this rule does not load by itself; the skills and roles read it explicitly anyway.

## Layout

```text
<tasks_dir>/
├── planning/
│   └── <topic>/
│       └── planning.md
├── bugs/
│   ├── index.md
│   ├── task-01-<slug>/
│   └── done/
├── improvements/
│   ├── index.md
│   ├── task-01-<slug>/
│   └── done/
├── epic-<slug>/
│   ├── index.md
│   └── stories/
│       ├── story-01-<slug>/
│       │   ├── index.md
│       │   ├── task-01-<slug>/
│       │   └── done/
│       │       └── task-02-<slug>/
│       └── done/
│           └── story-02-<slug>/
└── done/
    └── epic-<slug>/
```

- Every folder name says what it is: `epic-<slug>`, `story-NN-<slug>` and `task-NN-<slug>`, in lowercase kebab-case. `NN` is a two-digit number that gives the order. Keep a number once it is used, also in `done/`; never renumber.
- **A task is a folder** with `index.md`. It can also hold `mockup.html` (UI tasks) and `notes.md`.
- **Ids match folders.** The numbers in a task id are the `NN` of its story and task folders: `task-02-<slug>` in `story-03-<slug>` of the epic with `abbr: TPL` is `TPL-03-02`, and `bugs/task-04-<slug>` is `BUG-04`.
- **Finished work moves to `done/`.** A finished task moves into the `done/` folder of its parent (story, `bugs/` or `improvements/`). When the last open task of a story is done, the story moves into `stories/done/`; when the last open story of an epic is done, the epic moves into `<tasks_dir>/done/`. The runner's PR does this when it closes the last task. `<dart> run planner_dispatcher:backlog close-finished` catches what two runs finishing at once left open. If a planning PR and a runner PR both moved the same folder and conflict, keep the base branch's version and run `close-finished` again.
- **New work reopens closed work.** Before adding a task to a closed story or epic, run `<dart> run planner_dispatcher:backlog reopen <path>`; it moves the story, and its epic when closed, back out of `done/` and fixes the links. Done tasks stay in `done/`.
- **People read tasks by name.** Refer to a task as its title followed by its id, for example `Save template (TPL-03-02)`, never by the id alone.
- Standalone bugs and improvements have no epic or story. Use them for a broken behavior (`bugs/`) or a change to something that already works (`improvements/`).
- Indexes link to their children and carry no status, counts or progress. State is deduced (see below).
- A story may own one approved `mockup.html` shared by its visual tasks. Tasks link to the relevant states instead of copying the design. A standalone visual task owns its mockup itself.

## Planning record

`<tasks_dir>/planning/<topic>/planning.md` holds one planning effort, including efforts that span stories. It is not a task: give it no task front matter or `index.md`, and never list it as a dispatcher dependency. This location lets interviewing begin before the user agrees to a backlog structure. Reuse its path when resuming the same effort.

It holds the request, evidence, decisions and open questions; its working format is in [the planner's question reference](../skills/skill-planner/references/questions.md). A mockup lives beside it until the split is agreed.

During the interview it is the working source of truth. It may be committed on the planning branch, so a paused effort can resume in a later session. Never link to it from backlog files. Do not track implementation progress in it.

**At handoff, delete it.** Once every task of the effort is `ready`, transfer the current requirements, decisions and exclusions into the epic/story/task files and verify nothing was lost. Then delete the record, its `planning/<topic>/` folder, and anything else that only served the planning (drafts, scratch files, links to them), in the same planning PR. Runners need only their task, parents and repository. While a task of the effort is still `draft`, keep the record so its open questions are not lost, and delete it in the session that makes the last task `ready`. A follow-up planning effort starts a new record.

## IDs

- Every epic `index.md` starts with a front matter line `abbr: <ABBR>` (for example `TPL`).
- Task id: `<ABBR>-<story>-<task>`, for example `TPL-03-02`. Standalone tasks: `BUG-01`, `IMP-02`.
- An id is unique, never reused and never changed. `depends-on` uses ids.

## Task `index.md`

Front matter:

```yaml
---
id: TPL-03-02
status: draft          # draft | ready; in done/ it is done
type: feat             # feat | fix | improve; sets the branch prefix
complexity: 4          # 1 (simplest) to 10 (hardest); see below
depends-on: [TPL-03-01]
touches:               # paths or globs the task changes
  - src/store.ts
  - test/snapshots/home.png
skills: []             # optional; project skills the roles read, e.g. [skill-charts]
---
```

`complexity` says how hard the task is for a runner, from 1 (follows an existing pattern) to 10 (the hardest work a single task can hold). `skill-dispatcher-check` shows it, and on Antigravity it picks Gemini 3.8 Flash (up to 4) or Gemini 4 Argon for the implementer and tests. An older task with `low`, `medium` or `high` reads as 3, 6 or 9 until it is refined.

After the front matter, the title and the story and epic link lines, these sections, in this order. Leave out a section marked "only when" that does not apply. Keep the task short and concrete: a runner implements it without asking anything, using only code, tests and the config's `check` commands.

1. `## Goal`: what the task delivers, in one or two sentences, with the requirement ids it serves.
2. `## Context`: the code entry points and snapshot images that matter, and where new code goes.
3. `## Contract` (only when the task provides or uses something from another task): each symbol or path marked `existing`, `new here` or `provided by <task-id>`, with its signature, inputs, outputs, failures and ownership. Link shared agreements in the parent instead of copying them. An unwired piece names its consumer task. New names are proposals fixed by this plan, not claims about existing code.
4. `## View spec` (visual tasks only): the component or screen states, themes, strings, accessibility and navigation. An isolated component covers its own states and callbacks; assembly covers wiring and the full screen.
5. `## Mockup` (visual tasks only): link to the approved `mockup.html` and the states this task implements.
6. `## Decisions` (only when there are choices a runner might otherwise reverse).
7. `## Out of scope`
8. `## Files and tests`: only what `touches` and the `Check`s do not say: which files are new, each test file with its kind, and any planned fake or harness change. Explain a behavioral component test, or why no test is planned, only when that is the case.
9. `## Acceptance`: the task's behavior, one checkbox per behavior or edge case, on one line each: `- [ ] When <situation>, then <result>. Check: <check>.` Start with `Given <state>,` only when the starting state is not obvious. There is no separate behavior section: this list is the specification, the tests to write and the definition of done.

A `Check` is one of these, and nothing else:

- A test file and the test case, for example ``Check: `test/timer_list.test.ts` "delete removes the timer".``
- A snapshot image, only when `goldens_dir` is set.
- A command from the config's `check` list, written exactly as it appears there.

New and refined plans use these sections. Existing tasks keep their ids; before dispatching a task in an older layout, refine it rather than asking a runner to invent the missing parts.

## Shared agreements and requirements

The story lists its requirements once, as R1, R2…, each with the task ids that deliver it, and holds contracts its tasks share. The epic holds cross-story agreements. This is a scope map, not progress tracking.

`notes.md` is written by the worker: decisions it took, the evidence for each criterion, the PR link, and, when blocked, the exact question under `## Blocked`.

## When a task is `ready`

All of these are true:

- No open decision is left, and the task reads clearly to an agent that has not seen the planning conversation (cold read passed).
- Every criterion has a `Check` of an allowed kind.
- A visual component/assembly task has its view spec, and a linked mockup the user approved when the change needed one (a new screen, sheet, dialog or layout). State-only tasks omit both.
- `complexity` (a number from 1 to 10), `depends-on` and `touches` are filled in. `depends-on` ids exist.
- Its contract, consumer/assembly ownership and exact validation plan are settled, consistent with its dependencies and executable within runner boundaries. No required test infrastructure or technical decision is left for a runner to discover.
- The whole split has complete requirement coverage and compatible contracts. Each PR preserves a buildable, usable app with its completed prerequisites.

Anything else stays `draft`. Resolve unknowns in planning. A code/test prerequisite may unblock a draft, but findings-only investigations do not go to the implementation dispatcher. `ready` tasks may depend on unmerged fixed-contract tasks; they cannot be picked until those prerequisites are done. If an upstream contract changes, return affected pending tasks to `draft` and reconcile/cold-read them before restoring readiness.

## State is deduced

Nothing writes a progress status. From the repo:

| What exists | State |
| --- | --- |
| Task folder is under a `done/` folder on the base branch (its own, its story's or its epic's) | done |
| Open PR from the task branch | in review |
| Task branch on the remote, no PR | in progress, or blocked (a `wip:` commit and `## Blocked` in `notes.md`) |
| `status: ready`, every `depends-on` done, no overlap with a running task | can be picked |

The task branch is `<type>/<id-lowercase>-<slug>`, where `<slug>` is the folder name without `task-NN-`, for example `feat/tpl-03-02-save-template` for `task-02-save-template`. The worker moves its own task folder to `done/` (with `status: done`) in its PR, so merging the PR means the task is done.

## Overlap

Two tasks overlap when their `touches` overlap. They never run at the same time.

- `touches` lists exact paths: code, tests and, when `goldens_dir` is set, snapshot images. Use a narrow glob only when necessary.
- List specific snapshot images, never the whole `goldens_dir`.
- Prefer exact code/test paths to feature-wide globs. If several tasks edit the snapshot harness, list that file in each; overlap is intentional serialization, not a semantic dependency.
- When a task adds strings, list the localization folder the project rules name. It counts as a path like any other, so two tasks that add strings overlap.
- Do not list generated index files the planner notes name, or the backlog indexes. A merge conflict there is small and the user resolves it.

## Writing rules

- Relative Markdown links between task files. Repository-relative paths in prose. No local usernames, absolute paths or secrets.
- Do not copy global coding, git or model policies into a task. The worker follows the repo rules.
- Do not invent file names or APIs as verified facts. Check the code first.
