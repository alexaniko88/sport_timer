# Backlog templates

Use these as starting points. Replace example names and all placeholders with the agreed scope. Omit irrelevant fields rather than leaving empty headings. Requirements should describe observable behavior; a list of implementation actions alone is not acceptance criteria. The layout, ids, task fields and the ready checklist are defined in [.agents/rules/project-tasks-format.md](../../../rules/project-tasks-format.md); these templates only show the shape.

## Epic index

Path: `project-tasks/<epic-slug>/index.md`

```markdown
---
abbr: <ABBR>
---

# EPIC: <Capability>

## Goal

<Who benefits, what changes, and why.>

## Agreed behavior and boundaries

- <Behavior agreed with the user.>
- <First-version exclusions and future scope.>

## Decisions and current constraints

<Relevant architecture/storage choices, observed app behavior, and unresolved decisions. Distinguish choices from recommendations.>

## Stories

1. [<Outcome>](stories/01-<story-slug>/index.md) — <scope>.
2. [<Outcome>](stories/02-<story-slug>/index.md) — <scope>.

## Delivery order

<Dependencies, what can proceed independently, and the first usable release.>
```

## Story index

Path: `project-tasks/<epic-slug>/stories/01-<story-slug>/index.md`

```markdown
# STORY 1: <Outcome>

Epic: [<Capability>](../../index.md)

## User outcome

As <user>, I want <behavior> so that <benefit>.

## Scope

<Included behavior and meaningful exclusions.>

## Acceptance criteria

- <Observable successful result.>
- <Relevant interruption/error/boundary behavior.>

## Tasks

1. [<Deliverable>](01-<task-slug>/index.md).
2. [<Deliverable>](02-<task-slug>/index.md).

## Dependencies and open decisions

<Links to prerequisites and decisions that still need discussion. A story with a decision still open says what requires confirmation before its tasks can be `ready`.>

## Shared contracts

<Agreed symbols, paths, signatures, data and failure/lifecycle rules shared by tasks. Clearly label planned new symbols. Link cross-story agreements in the epic instead of copying them. Name the assembly owner.>

## Requirement coverage

| Requirement | Contributing tasks | Acceptance checks and assembled verification owner |
| --- | --- | --- |
| R1: <agreed behavior> | <task ids> | <task acceptance references and exact check> |
```

## Task

Path: `project-tasks/<epic-slug>/stories/01-<story-slug>/01-<task-slug>/index.md`

```markdown
---
id: <ABBR>-01-01
status: draft
type: feat
complexity: low
depends-on: []
touches:
  - <path or glob the task changes>
skills: []
---

# <Deliverable>

Story: [<Outcome>](../index.md)

Epic: [<Capability>](../../../index.md)

## Goal

<Concrete result this task delivers, in 2 or 3 sentences.>

## Context

<Relative links to the story, epic, related code and goldens. Verified repository-relative code entry points. Name the feature and layer (`domain`, `data`, `presentation`, `shared`) that new code belongs in, following `CLAUDE.md`. A helper on one type is an extension in that layer's `extensions/` folder.>

## Contract

<Exact provided/consumed symbols and locations, marked existing, new here or provided by a dependency task id. Link shared agreements in the parent. Specify inputs, outputs, failures and relevant ownership/disposal. Name the consumer and assembly task ids for an unwired piece; for assembly, name the pieces and wiring this task owns.>

## Behavior

<Exact behavior and edge cases.>

## Decisions

- <What the user decided, and why.>

## Out of scope

- <Relevant exclusions.>

## Files and tests

<Exact files, tests/cases, golden outputs, literal check commands, and any planned fakes or harness edits. Explain a behavioral widget test's necessity or why no new test adds value. Include applicable existing checks. Reuse the dispatcher overrides' boundaries instead of copying them here.>

## Acceptance

- [ ] When <situation>, then <result>. Check: <test, golden or command>.
```

For a visual widget or assembly task, add `## View spec` (after `## Behavior`) and `## Mockup` (after it), as listed in the rule file. Link the parent's approved design when shared. Pure logic and ViewModel/state-only tasks omit both.

## Standalone bug or improvement task

Paths: `project-tasks/bugs/01-<bug-slug>/index.md` or `project-tasks/improvements/01-<improvement-slug>/index.md`.

Use the task template above with these changes:

- Front matter `id` is `BUG-01` or `IMP-01`; `type` is `fix` for a bug and `improve` for an improvement.
- Replace the story and epic links with `[Bugs](../index.md)` or `[Improvements](../index.md)`. Related epic or story links are optional.
- For bugs, add expected and actual behavior, reproduction steps, environment and impact when known, in `## Context`. State unknowns and distinguish suspected causes from a confirmed diagnosis. A bug is not `ready` until its cause is confirmed.
- For improvements, add the current behavior or limitation, the desired change and the benefit, in `## Context`.

Each category `index.md` explains what belongs in that folder and lists its tasks. Keep it explicitly empty until real reports or proposals exist; example filenames are not tasks to create.
