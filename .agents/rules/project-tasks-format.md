---
paths:
  - "project-tasks/**"
---

# Project tasks format

Single source for how `project-tasks/` is laid out and how a task is written. Skills and roles link to this file and never copy it.

## Layout

```text
project-tasks/
├── planning/
│   └── <topic>/
│       └── planning.md
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
- A story may own one approved `mockup.html` shared by its visual tasks. Tasks link to the relevant states instead of copying the design. A standalone visual task owns its mockup itself.

## Interview record

`project-tasks/planning/<topic>/planning.md` holds one planning effort, including efforts that span stories. It is not a task: give it no task front matter or `index.md`, and never list it as a dispatcher dependency. This location lets interviewing begin before the user agrees to a backlog structure. Reuse its path when resuming the same effort.

It holds the original request, evidence, coverage, decisions, open questions and interview review results; its working format is in [the planner's question reference](../skills/skill-planner/references/questions.md).

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
complexity: low        # low | medium | high; picks the suggested model
depends-on: [TPL-03-01]
touches:               # paths or globs the task changes
  - lib/features/templates/data/local_template_store.dart
  - test/snapshots/goldens/templates_custom.png
skills: []             # optional; project skills the roles read, e.g. [skill-fl-chart]
---
```

Sections, in this order. Leave out the ones marked "visual tasks only" when there is no view.

1. `# <Title>`
2. `## Goal`: what is achieved, in 2 or 3 sentences.
3. `## Context`: links to the story and epic, and the code and goldens that matter.
4. `## Contract`: exact symbols/paths provided and consumed, marked `existing`, `new here` or `provided by <task-id>`. Specify inputs, outputs, signatures, failure semantics and relevant lifecycle/ownership. Link shared agreements in the parent rather than duplicating them. Name consumer task ids for an unwired block, and the task owning final assembly. New planned names are explicitly proposals fixed by this plan, not claims about existing code.
5. `## Behavior`: exact behavior and edge cases within this task's responsibility.
6. `## View spec` (visual tasks only): the applicable widget/screen states, themes, strings, accessibility and navigation. A ViewModel/state-only task omits it. An isolated widget covers its own states and callbacks; assembly covers wiring and the full screen behavior.
7. `## Mockup` (visual tasks only): link to the approved task or parent `mockup.html` and the states this task implements.
8. `## Decisions`: what the user decided while planning, each with its reason.
9. `## Out of scope`
10. `## Files and tests`: exact created/changed paths, tests and cases, runnable commands, required fakes/harness changes and golden outputs. State why a behavioral widget test is necessary, or why no new test is useful. Follow the dispatcher overrides' test/tool boundaries; do not copy their policies into every task. Include applicable existing regression/architecture checks, not only new tests.
11. `## Acceptance`: one checkbox per criterion, written as `When <situation>, then <result>.` followed by `Check: <test, golden or command>`. Every criterion must be checkable.

New and refined plans use these sections. Existing tasks keep their ids and layout; before dispatching a task that lacks these guarantees, refine it rather than asking a runner to invent the missing contract or checks.

## Shared agreements and coverage

The parent story holds contracts shared by its tasks and a requirement-to-task-to-check table. Use the epic for cross-story agreements. State each requirement once with a stable local reference, its contributing task ids and the owning acceptance checks. Name the task that verifies the combined result. This is scope/verification mapping, not implementation progress. Standalone tasks carry their own mapping when needed.

`notes.md` is written by the worker: decisions it took, the evidence for each criterion, the PR link, and, when blocked, the exact question under `## Blocked`.

## When a task is `ready`

All of these are true:

- No open decision is left, and the task reads clearly to an agent that has not seen the planning conversation (cold read passed).
- Every criterion has a `Check`.
- A visual widget/assembly task has its view spec and a linked mockup the user approved. ViewModel/state-only tasks omit them.
- `complexity`, `depends-on` and `touches` are filled in. `depends-on` ids exist.
- Its contract, consumer/assembly ownership and exact validation plan are settled, consistent with its dependencies and executable within runner boundaries. No required test infrastructure or technical decision is left for a runner to discover.
- The whole split has complete requirement coverage and compatible contracts. Each PR preserves a buildable, usable app with its completed prerequisites.

Anything else stays `draft`. Resolve unknowns in planning. A code/test prerequisite may unblock a draft, but findings-only investigations do not go to the implementation dispatcher. `ready` tasks may depend on unmerged fixed-contract tasks; they cannot be picked until those prerequisites are done. If an upstream contract changes, return affected pending tasks to `draft` and reconcile/cold-read them before restoring readiness.

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
- Prefer exact code/test paths to feature-wide globs. If several tasks edit the snapshot harness, list that file in each; overlap is intentional serialization, not a semantic dependency.
- `lib/l10n/**` counts as a path like any other. Two tasks that add strings overlap.
- Do not list `test/snapshots/README.md` or the `project-tasks/` indexes. A merge conflict there is small and the user resolves it.

## Writing rules

- Relative Markdown links between task files. Repository-relative paths in prose. No local usernames, absolute paths or secrets.
- Do not copy global coding, git or model policies into a task. The worker follows the repo rules.
- Do not invent file names or APIs as verified facts. Check the code first.
