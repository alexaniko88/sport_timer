# Backlog templates

These show the shape only; the sections and their rules are in [.agents/rules/backlog-format.md](../../../rules/backlog-format.md). Replace every placeholder. Fill every front matter field, but leave out a section that does not apply rather than writing an empty heading. Write short: bullets, no background story, and nothing a parent already says.

## Epic index

Path: `<tasks_dir>/epic-<slug>/index.md`

```markdown
---
abbr: <ABBR>
---

# EPIC: <Capability>

## Goal

<One or two lines: who benefits and what changes.>

## Boundaries

- In: <what this epic covers.>
- Out: <first-version exclusions and future scope.>

## Shared contracts

<Only when stories share symbols, data or rules. Mark planned new symbols as new.>

## Stories

1. [<Outcome>](stories/story-01-<slug>/index.md)
2. [<Outcome>](stories/story-02-<slug>/index.md)
```

## Story index

Path: `<tasks_dir>/epic-<slug>/stories/story-01-<slug>/index.md`

```markdown
# STORY 1: <Outcome>

Epic: [<Capability>](../../index.md)

<One line: who gets what.>

## Scope

- In: <included behavior.>
- Out: <meaningful exclusions.>

## Requirements

- R1: <observable behavior agreed with the user> — <task ids>.
- R2: <...> — <task ids>.

## Tasks

1. [<Deliverable>](task-01-<slug>/index.md)
2. [<Deliverable>](task-02-<slug>/index.md)

## Shared contracts

<Only when two or more tasks share something: symbols, paths, signatures, data and failure rules, with planned new symbols marked as new. Name the task that wires the pieces together.>

## Open decisions

<Only while a task of this story is `draft`: what must be confirmed before it can be `ready`.>
```

## Task

Path: `<tasks_dir>/epic-<slug>/stories/story-01-<slug>/task-01-<slug>/index.md`

```markdown
---
id: <ABBR>-01-01
status: draft
type: feat
complexity: 3
depends-on: []
touches:
  - <path or glob the task changes>
skills: []
---

# <Deliverable>

Story: [<Outcome>](../index.md)

Epic: [<Capability>](../../../index.md)

## Goal

<What this task delivers, in one or two sentences. Name the requirement ids it serves.>

## Context

- <Verified code entry points and snapshot images that matter, and where new code goes under the project rules.>

## Contract

<Only when the task provides or uses something from another task.>

- <Symbol and location> — <existing | new here | provided by <task id>>: <signature, inputs, outputs, failures, ownership>.

## Decisions

<Only choices a runner might otherwise reverse.>

- <Decision.>

## Out of scope

- <Relevant exclusions.>

## Files and tests

- New: <each file this task creates; changed files are in `touches`.>
- Tests: <each test file, with its kind (unit, snapshot, component).>
- <Any planned fake or harness edit.>

## Acceptance

- [ ] When <situation>, then <result>. Check: `<test file>` "<test case>".
- [ ] Given <state, only when not obvious>, when <situation>, then <result>. Check: <allowed check>.
```

For a visual component or assembly task, add `## View spec` and `## Mockup` after `## Contract` (or after `## Context` when there is no contract). Link the parent's approved mockup when shared. Pure logic and state-only tasks omit both.

## Standalone bug or improvement task

Paths: `<tasks_dir>/bugs/task-01-<slug>/index.md` or `<tasks_dir>/improvements/task-01-<slug>/index.md`.

Use the task template above with these changes:

- Front matter `id` is `BUG-01` or `IMP-01`; `type` is `fix` for a bug and `improve` for an improvement.
- Replace the story and epic links with a link to the parent category `index.md` (`Bugs` or `Improvements`). Related epic or story links are optional.
- For a bug, `## Context` holds expected and actual behavior, reproduction steps and the confirmed cause with its evidence.
- For an improvement, `## Context` holds the current behavior or limitation, the desired change and the benefit.

Each category `index.md` explains what belongs in that folder and lists its tasks. Keep it explicitly empty until real reports or proposals exist; example filenames are not tasks to create.
