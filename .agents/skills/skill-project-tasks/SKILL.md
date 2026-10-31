---
name: skill-project-tasks
description: >-
  Discuss a feature, bug, or improvement and create or refine a local Markdown backlog
  of epics, stories, and tasks under project-tasks/, including standalone bug reports
  and improvement tasks. Use when the user asks
  to break an idea into stories and tickets, create project task files, or organize
  an existing local backlog for later orchestration. This is planning, not feature
  implementation or creating tickets in Linear or GitHub.
---

# Project tasks

Turn the user's idea into an agreed, readable backlog that another session can use without the original conversation. Work with the current repository and preserve decisions already made in the session.

## Hierarchy and layout

- **Epic:** the broader capability or goal.
- **Story:** a useful user outcome within that epic.
- **Task / ticket:** a bounded, independently orchestratable piece of that story. These are two names for the same level, not separate folders.
- **Implementation steps:** small file-level or concern-level changes planned later during orchestration; do not confuse them with backlog tickets.

Use this structure unless the user explicitly requests a different one:

```text
project-tasks/
├── status.md
├── bugs/
│   ├── index.md
│   └── 01-<bug-slug>.md
├── improvements/
│   ├── index.md
│   └── 01-<improvement-slug>.md
└── <epic-slug>/
    ├── index.md
    └── stories/
        ├── 01-<story-slug>/
        │   ├── index.md
        │   ├── 01-<task-slug>.md
        │   └── 02-<task-slug>.md
        └── 02-<story-slug>/
            ├── index.md
            └── 01-<task-slug>.md
```

Use lowercase kebab-case for these documentation paths, including in Flutter projects. Epics are unnumbered; stories and tasks use two-digit sequence prefixes, reflecting the intended order. Tasks live directly inside their story folder. Every epic and story has an `index.md` overview. Keep existing identifiers and filenames stable when extending a backlog; avoid renumbering existing work just to insert a dependency.

### Standalone bugs and improvements

`bugs/` and `improvements/` are reserved categories, not epics. Each has an `index.md` explaining its purpose and linking to its tasks and the shared tracker. Tasks live directly in the category folder; do not require an epic or story for a standalone report. Number tasks independently within each category using the next unused number, preserving existing paths. Use identifiers such as `BUG-01` and `IMP-01` to avoid confusion with story tasks.

- Use `project-tasks/bugs/` only for broken existing behavior. Capture expected/actual behavior, reproduction steps and environment when known, impact, and testable fix criteria. Keep suspected causes separate from facts. Record a useful report even if reproduction or diagnosis is incomplete; do not invent a root cause. Unresolved diagnosis can be recorded as the next planning step rather than implying a fix is approved.
- Use `project-tasks/improvements/` for improvements to working behavior. Capture the current limitation, desired change, benefit, scope/exclusions, decisions, and testable criteria. Broader new capabilities still use epics/stories. Preserve an explicit user classification, or clarify only if routing materially changes scope.
- Link a related epic/story where helpful without duplicating an existing task. Add each standalone task to its category index and `project-tasks/status.md` with the same progress/evidence rules as story tasks.

## 1. Understand and discuss

Read only the repository instructions, existing backlog, and code needed to establish facts. Investigate technical facts yourself; ask the user about product choices. Verify current dependency capabilities in official documentation when a storage or library recommendation depends on them.

Read `project-tasks/status.md` when present to distinguish planned capabilities from completed, reusable work. Check recorded evidence and the current checkout before treating an output as available.

For a new idea with unresolved behavior, discuss before writing the backlog:

- Ask a short numbered round of independent questions, each with a recommended answer and a concrete example where helpful.
- Wait for answers before asking questions that depend on them. Apply the available grilling skill when the user requests it; otherwise use ordinary focused discussion without requiring that skill to exist.
- Settle the user outcome, what counts toward it, exclusions, important edge cases, ownership/persistence where relevant, and what belongs in the first version versus later stories.
- Treat future ideas as provisional. Do not turn them into approved requirements or implementation commitments.
- Separate observed facts, user decisions, recommendations, and unanswered questions.

Once the behavior is clear, present the epic/story split and remaining decisions for agreement before creating a new backlog. Reuse agreement already given; do not repeat confirmation when the user has approved the split or directly requested a concrete reorganization. For an already clear ticket request, create it without imposing an interview.

## 2. Split the agreed scope

Choose stories around useful outcomes, and tasks around cohesive deliverables that can be planned, implemented, and checked independently. A task can span several files; its orchestrator will split implementation into smaller steps. Do not create an arbitrary number of tickets or one ticket per file.

Record dependencies explicitly. Keep necessary setup inside the relevant story unless it is large enough to warrant a separate outcome and the user agrees. If a technical choice is unresolved, make investigation/decision a prerequisite task rather than inventing the answer.

Include relevant tests and verification in implementation tickets. Add a separate integration-verification task only when it checks behavior across tickets; do not defer basic correctness to a later testing ticket.

## 3. Write or update the files

Read [references/templates.md](references/templates.md) when generating the backlog. Adapt its fields to the request; omit empty boilerplate.

- The epic index explains the goal, agreed behavior, scope boundaries, major decisions, current constraints, and story order, with links to every story index.
- Each story index explains the user outcome, scope, acceptance criteria, dependencies, unresolved decisions, and ordered links to its tasks.
- Each story task links to its parent story and epic; each standalone task links to its category index and shared tracker. All tasks include status, goal, scope/exclusions, dependencies, and observable acceptance criteria. Include relevant validation and code entry points when known. Do not invent exact filenames or APIs as verified facts.
- State whether a task is ready for planning, blocked by a decision/dependency, or provisional. Approval of the backlog does not approve application code changes.
- Make the task usable as input to the repository's applicable orchestration workflow. Do not copy global coding, git, or model/agent policies into every ticket or override that workflow from this skill.
- Use relative Markdown links between backlog files. Use repository-relative paths in prose and avoid local usernames, account secrets, or machine-specific absolute paths.
- Keep shared decisions in the epic/story and link to them instead of repeating long requirements in every task. Each task still needs enough context to identify its own deliverable.
- Maintain one root `project-tasks/status.md` covering all epics and standalone bug/improvement tasks. Link every task, its execution status (Ready, In progress, Blocked, Done, or Provisional), prerequisites/blockers, and intended output. Include an overview, next eligible task, active-work handoff, and completed outputs with evidence and code/decision location. Link the tracker from epic and category indexes.
- Initialize status from actual progress, not the existence of planning files. Ready means ready for planning, not approved implementation. Preserve provisional scope. Do not mark work Done without acceptance/validation evidence or assume a completed branch is available in another checkout.
- Update the tracker when creating, moving, splitting, or removing tasks. Keep repeated task/story statuses consistent, and preserve completion history.

When reorganizing, preserve the existing requirements and provisional status, move rather than duplicate files, update affected inbound/outbound links, and remove obsolete paths only as part of the requested move. Do not replace unrelated content.

## 4. Validate and hand off

Verify the requested layout, numbering, parent/child links, and every relative Markdown file target affected by the changes. Check that task scopes cover the story's acceptance criteria and that dependencies have no accidental cycles. Search for stale paths after moves.

Report the epic index, story/task counts, provisional items, and any unresolved decisions concisely. Stop at the planning deliverable. Feature code changes, orchestration, external ticket creation, commits, and pushes need their own user request or existing authorization.
