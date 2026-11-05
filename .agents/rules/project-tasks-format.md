---
paths:
  - "project-tasks/**"
---

# Project tasks format

Single source for how `project-tasks/` is laid out and how a task is written. Skills and roles link to this file and never copy it.

## Layout

```text
project-tasks/
├── bugs/
│   ├── index.md
│   └── 01-<slug>/
├── improvements/
│   ├── index.md
│   └── 01-<slug>/
└── <epic-slug>/
    ├── index.md
    └── stories/
        └── 01-<story-slug>/
            ├── index.md
            ├── 01-<task-slug>/
            └── done/
                └── 02-<task-slug>/
```

- Lowercase kebab-case paths. Stories and tasks have a two-digit prefix that gives their order. Epics have none. Keep a number once it is used; never renumber.
- **A task is a folder** with `index.md`. It can also hold `mockup.html` (UI tasks) and `notes.md`.
- **Only tasks are archived.** A finished task moves into the `done/` folder of its parent (story, `bugs/` or `improvements/`). Epics and stories never move, so new work can always be added to them.
- Standalone bugs and improvements have no epic or story. Use them for a broken behavior (`bugs/`) or a change to something that already works (`improvements/`).
- Indexes link to their children and carry no status, counts or progress. State is deduced (see below).

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
complexity: low        # low | medium | high; picks the suggested model
depends-on: [TPL-03-01]
touches:               # paths or globs the task changes
  - lib/features/templates/**
  - test/snapshots/goldens/templates_custom.png
---
```

Sections, in this order. Leave out the ones marked "UI only" when there is no view.

1. `# <Title>`
2. `## Goal`: what is achieved, in 2 or 3 sentences.
3. `## Context`: links to the story and epic, and the code and goldens that matter.
4. `## Behavior`: exact behavior and edge cases.
5. `## View spec` (UI only): layout, every state (empty, loading, error, partial data, long text), dark and light theme, English and Spanish strings, shared widgets reused, tap targets and accessibility, navigation in and out.
6. `## Mockup` (UI only): link to `mockup.html`. It is a reference the user approved.
7. `## Decisions`: what the user decided while planning, each with its reason.
8. `## Out of scope`
9. `## Files and tests`: what is created or changed, and which tests are written.
10. `## Acceptance`: one checkbox per criterion, written as `When <situation>, then <result>.` followed by `Check: <test, golden or command>`. Every criterion must be checkable.

`notes.md` is written by the worker: decisions it took, the evidence for each criterion, the PR link, and, when blocked, the exact question under `## Blocked`.

## When a task is `ready`

All of these are true:

- No open decision is left, and the task reads clearly to an agent that has not seen the planning conversation (cold read passed).
- Every criterion has a `Check`.
- A UI task has its view spec and a mockup the user approved.
- `complexity`, `depends-on` and `touches` are filled in. `depends-on` ids exist.

Anything else stays `draft`. Tasks that cannot be decided yet get a prerequisite task.

## State is deduced

Nothing writes a progress status. From the repo:

| What exists | State |
| --- | --- |
| Task folder is under `done/` on `master` | done |
| Open PR from the task branch | in review |
| Task branch on the remote, no PR | in progress, or blocked (a `wip:` commit and `## Blocked` in `notes.md`) |
| `status: ready`, every `depends-on` done, no overlap with a running task | can be picked |

The task branch is `<type>/<id-lowercase>-<slug>`, for example `feat/tpl-03-02-save-template`. The worker moves its own task folder to `done/` (with `status: done`) in its PR, so merging the PR means the task is done.

## Overlap

Two tasks overlap when their `touches` overlap. They never run at the same time.

- List specific golden files, never `test/snapshots/**`.
- `lib/l10n/**` counts as a path like any other. Two tasks that add strings overlap.
- Do not list `test/snapshots/README.md` or the `project-tasks/` indexes. A merge conflict there is small and the user resolves it.

## Writing rules

- Relative Markdown links between task files. Repository-relative paths in prose. No local usernames, absolute paths or secrets.
- Do not copy global coding, git or model policies into a task. The worker follows the repo rules.
- Do not invent file names or APIs as verified facts. Check the code first.
