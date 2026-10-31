# Backlog templates

Use these as starting points. Replace example names and all placeholders with the agreed scope. Omit irrelevant fields rather than leaving empty headings. Requirements should describe observable behavior; a list of implementation actions alone is not acceptance criteria.

## Epic index

Path: `project-tasks/<epic-slug>/index.md`

```markdown
# EPIC: <Capability>

Status: <Agreed scope / Draft>.

Progress and reusable outputs: [Project task status](../status.md).

## Goal

<Who benefits, what changes, and why.>

## Agreed behavior and boundaries

- <Behavior agreed with the user.>
- <First-version exclusions and future scope.>

## Decisions and current constraints

<Relevant architecture/storage choices, observed app behavior, and unresolved decisions. Distinguish choices from recommendations.>

## Stories

1. [<Outcome>](stories/01-<story-slug>/index.md) — <scope and status>.
2. [<Outcome>](stories/02-<story-slug>/index.md) — <scope and status>.

## Delivery order

<Dependencies, what can proceed independently, and the first usable release.>
```

## Story index

Path: `project-tasks/<epic-slug>/stories/01-<story-slug>/index.md`

```markdown
# STORY 1: <Outcome>

Epic: [<Capability>](../../index.md)

Status: <Ready for planning / Depends on ... / Provisional>.

## User outcome

As <user>, I want <behavior> so that <benefit>.

## Scope

<Included behavior and meaningful exclusions.>

## Acceptance criteria

- <Observable successful result.>
- <Relevant interruption/error/boundary behavior.>

## Tasks

1. [<Deliverable>](01-<task-slug>.md).
2. [<Deliverable>](02-<task-slug>.md).

## Dependencies and open decisions

<Links to prerequisites and decisions that still need discussion. A provisional story must say what requires confirmation before implementation.>
```

## Task ticket

Path: `project-tasks/<epic-slug>/stories/01-<story-slug>/01-<task-slug>.md`

```markdown
# TASK 1.1: <Deliverable>

Story: [<Outcome>](index.md)

Epic: [<Capability>](../../index.md)

Status: <Ready for planning / Blocked by ... / Provisional>.

## Goal

<Concrete result this ticket delivers.>

## Scope

- <Included work.>
- <Relevant exclusions.>

## Dependencies

<Relative links to actual prerequisites; say none if independent.>

## Acceptance criteria

- <Result someone can verify without knowing the implementation.>
- <Relevant error handling or data integrity condition.>

## Validation

<Focused checks that prove the criteria, following the repository's test conventions. For a research ticket, the deliverable may instead be a documented, approved decision.>

## Implementation context

<Verified repository-relative code entry points or constraints, if useful. Read parent indexes before starting and follow the applicable orchestration workflow.>
```

## Root progress tracker

Path: `project-tasks/status.md`. Maintain one tracker across all epics and standalone bug/improvement tasks, not one per story or category.

Include a status legend (Ready, In progress, Blocked, Done, Provisional), an overview and next eligible task, a linked task table with prerequisites and intended outputs, an active-work handoff, and completed outputs with completion dates, validation evidence, limitations, and branch/commit or decision locations. Planned outputs are not available capabilities. Check the actual checkout before reusing completed work. Keep this file updated when the backlog changes; the implementation workflow updates it as work progresses.

## Standalone bug or improvement task

Paths: `project-tasks/bugs/01-<bug-slug>.md` or `project-tasks/improvements/01-<improvement-slug>.md`.

Use the task template above with these changes:

- Title: `# BUG-01: <Problem>` or `# IMP-01: <Improvement>`.
- Replace required story/epic links with `[Bugs](index.md)` or `[Improvements](index.md)`, and `[Project task status](../status.md)`. Related epic/story links are optional.
- For bugs, add expected/actual behavior, reproduction steps, environment, and impact when known; state unknowns and distinguish suspected causes from confirmed diagnosis.
- For improvements, add current behavior/limitation, desired change, benefit, and open decisions.
- Keep dependencies, scope/exclusions, observable acceptance criteria, and validation. A report can be ready for diagnosis while its eventual fix still requires approval.

Each category `index.md` explains what belongs in that folder, links to `../status.md`, and lists its tasks. Keep it explicitly empty until real reports or proposals exist; example filenames are not tasks to create.
