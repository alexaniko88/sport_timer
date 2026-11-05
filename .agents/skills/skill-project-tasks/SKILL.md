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

## Starting a new invocation

Before creating or changing backlog files, check `git status -sb` and read `.agents/rules/git-commits.md` for branch naming. For each new invocation, switch to `master`, update it with `git pull --ff-only`, then create a new, uniquely named branch from the updated `master`. Use `improve/` for improvements, `fix/` for bugs, and `feat/` for new capabilities or their planning. Continue an existing invocation on its branch rather than creating another branch for follow-up messages.

Preserve uncommitted work: do not carry unrelated changes onto the new branch or overwrite, discard, or stash them without authorization. If the checkout cannot be switched safely, or the pull fails, stop and explain the blocker; do not silently use a stale or different base. Respect an explicit user instruction to use another base.

## Hierarchy and layout

- **Epic:** the broader capability or goal.
- **Story:** a useful user outcome within that epic.
- **Task / ticket:** a bounded, independently orchestratable piece of that story, written as a folder. These are two names for the same level.
- **Implementation steps:** small file-level or concern-level changes planned later during orchestration; do not confuse them with backlog tickets.

The layout, task ids, task front matter and sections, the ready checklist and the done rules are in [.agents/rules/project-tasks-format.md](../../rules/project-tasks-format.md). Follow that file and do not copy it here. Epics and stories are never archived; only tasks move into `done/`. Keep existing identifiers and paths stable when extending a backlog; avoid renumbering existing work just to insert a dependency.

### Standalone bugs and improvements

`bugs/` and `improvements/` are reserved categories, not epics. Each has an `index.md` explaining its purpose and linking to its tasks. Tasks are folders directly in the category folder; do not require an epic or story for a standalone report. Number tasks independently within each category using the next unused number, preserving existing paths. Use identifiers such as `BUG-01` and `IMP-01` to avoid confusion with story tasks.

- Use `project-tasks/bugs/` only for broken existing behavior. Capture expected/actual behavior, reproduction steps and environment when known, impact, and testable fix criteria. Keep suspected causes separate from facts. Record a useful report even if reproduction or diagnosis is incomplete; do not invent a root cause. Unresolved diagnosis can be recorded as the next planning step rather than implying a fix is approved.
- Use `project-tasks/improvements/` for improvements to working behavior. Capture the current limitation, desired change, benefit, scope/exclusions, decisions, and testable criteria. Broader new capabilities still use epics/stories. Preserve an explicit user classification, or clarify only if routing materially changes scope.
- Link a related epic/story where helpful without duplicating an existing task. Add each standalone task to its category index with the same progress/evidence rules as story tasks.

## 1. Understand and discuss

Read only the repository instructions, existing backlog, and code needed to establish facts. Investigate technical facts yourself; ask the user about product choices. Verify current dependency capabilities in official documentation when a storage or library recommendation depends on them.

Before creating any task, search all of `project-tasks/`, including standalone categories and archived `done/` folders, for the same or overlapping work. Search for related terms as well as the proposed title, then read possible matches and their parent context to compare scope and status. If the work already exists, point the user to it and update or extend it when appropriate instead of creating a duplicate. For a completed match, check its completion evidence and current behavior to distinguish a duplicate from a regression or further work; link a new follow-up to the completed task when appropriate. If the distinction remains unclear or completed work may need to be reopened, discuss it with the user before creating another task. Repeat this check for each task in a proposed split.

Also look for a suitable existing epic and story for each new task without waiting for the user to name them. Match their outcomes and acceptance criteria, not just their titles or technical area. Prefer the most relevant existing hierarchy when the task belongs to its outcome (for example, a UI refactor belonging to a UI refactor epic and story); use a standalone category when no existing hierarchy fits and the request is a standalone bug or improvement. If multiple parents fit equally well, ask the user which to use. Update the parent summaries and links to reflect the new work. Preserve completed tasks and their evidence. Never overwrite an existing destination; resolve any collision before moving.

Read the relevant task, its linked dependencies and parent context, and check the current checkout before treating an output as available.

For a new idea with unresolved behavior, discuss before writing the backlog:

- Ask a short numbered round of independent questions, each with a recommended answer and a concrete example where helpful.
- Wait for answers before asking questions that depend on them. Apply the available grilling skill when the user requests it; otherwise use ordinary focused discussion without requiring that skill to exist.
- Settle the user outcome, what counts toward it, exclusions, important edge cases, ownership/persistence where relevant, and what belongs in the first version versus later stories.
- Treat future ideas as provisional. Do not turn them into approved requirements or implementation commitments.
- Separate observed facts, user decisions, recommendations, and unanswered questions.

Once the behavior is clear, present the epic/story split and remaining decisions for agreement before creating a new backlog. Reuse agreement already given; do not repeat confirmation when the user has approved the split or directly requested a concrete reorganization. For an already clear ticket request, create it without imposing an interview.

## 2. Split the agreed scope

Choose stories around useful outcomes, and tasks around cohesive deliverables that can be planned, implemented, and checked independently. A task can span several files; its orchestrator will split implementation into smaller steps. Do not create an arbitrary number of tickets or one ticket per file.

When assigning a new story or task number, check both active and archived siblings and use the next unused number, keeping existing identifiers stable.

Record dependencies explicitly. Keep necessary setup inside the relevant story unless it is large enough to warrant a separate outcome and the user agrees. If a technical choice is unresolved, make investigation/decision a prerequisite task rather than inventing the answer.

Include relevant tests and verification in implementation tickets. Add a separate integration-verification task only when it checks behavior across tickets; do not defer basic correctness to a later testing ticket.

## 3. Write or update the files

Read [references/templates.md](references/templates.md) when generating the backlog. Adapt its fields to the request; omit empty boilerplate.

- The epic index explains the goal, agreed behavior, scope boundaries, major decisions, current constraints, and story order, with links to every story index.
- Each story index explains the user outcome, scope, acceptance criteria, dependencies, unresolved decisions, and ordered links to its tasks.
- Each story task links to its parent story and epic; each standalone task links to its category index. Every task follows the task format in the rule file: front matter, ordered sections and checkable acceptance criteria. Include relevant validation and code entry points when known. Do not invent exact filenames or APIs as verified facts.
- Set `status: draft` or `status: ready` in the front matter, using the rule's ready checklist. Epic and story indexes carry no status. Approval of the backlog does not approve application code changes.
- Make the task usable as input to the repository's applicable orchestration workflow. Do not copy global coding, git, or model/agent policies into every ticket or override that workflow from this skill.
- For UI-related tasks, inspect and link the relevant `test/snapshots/goldens/` images and `test/snapshots/README.md` as current visual and navigation context. Describe important coverage gaps or placeholder states, retain agreed and provisional design decisions, and check the implementation checkout when work starts. Include applicable snapshot and index maintenance in validation. Pure logic tasks do not need visual references.
- Use relative Markdown links between backlog files. Use repository-relative paths in prose and avoid local usernames, account secrets, or machine-specific absolute paths.
- Keep shared decisions in the epic/story and link to them instead of repeating long requirements in every task. Each task still needs enough context to identify its own deliverable.
- Set `status` from the ready checklist, not from the existence of planning files. Ready means ready for implementation under the rule's checklist. Preserve provisional scope as `draft`. Do not move a task to `done/` without acceptance and validation evidence, and do not assume a completed branch is available in another checkout.

When reorganizing, preserve the existing requirements and provisional status, move rather than duplicate files, update affected inbound/outbound links, and remove obsolete paths only as part of the requested move. Do not replace unrelated content.

## Archiving completed work

Only tasks are archived; epics and stories never move (see the rule file). Archive immediately after successful review and resolution of selected suggestions, before asking whether to open the PR. Verify that the task is Done with acceptance and validation evidence recorded.

- Move the task folder into `done/` under its current parent (the story, `bugs/` or `improvements/`), keeping its folder name, and set `status: done` in its `index.md`. For example, `stories/01-template-set-and-tiles/01-move-templates-to-feature/` becomes `stories/01-template-set-and-tiles/done/01-move-templates-to-feature/`.
- Do the move on the same feature branch and include it in the authorized commit or a separate `docs:` commit before the initial PR push. Approval to open the PR covers committing and pushing it. If an open PR already exists, include the move in the next approved branch update.
- Record acceptance evidence and branch context in the task's `notes.md`, plus the PR link when it is already available. If PR creation fails, keep the moved folder and note the pending PR step so the work can resume. If the PR is later closed without merging, move the task back and restore its previous `status`.
- Create `done/` only when needed, move rather than copy, and never overwrite an existing destination.
- Update all affected inbound and outbound relative links (task parent links, `depends-on`, story and epic indexes, references from other epics), and search for stale paths before committing and pushing.

Do not start another task just to archive finished work, and do not create a separate archival PR. A task under `done/` has one extra directory level.

## 4. Validate and hand off

Verify the requested layout, numbering, parent/child links, and every relative Markdown file target affected by the changes. Check that task scopes cover the story's acceptance criteria and that dependencies have no accidental cycles. Search for stale paths after moves.

Report the epic index, story/task counts, provisional items, and any unresolved decisions concisely. When the backlog is ready and nothing else is needed, show the full proposed commit message and exact files to commit, then put this single approval question in its own bold paragraph:

**Are you done with this task? If yes, I’ll commit these files, push the branch, and open a PR.**

An affirmative answer with no further changes authorizes all three actions; do not ask again for each one. If the user requests changes, make and validate them, update the proposed message and file list as needed, and ask again. Silence is not approval.

Before committing, verify the intended files and repo-local email, and scan the staged diff for private information as required by repository instructions. Follow the commit and PR naming rules in `.agents/rules/git-commits.md`. Stage only the approved files, then commit, push, and open the PR; report the PR link. If any step fails, report the failure and preserve the work for resumption. Feature code changes, orchestration, and external ticket creation remain outside this planning workflow.
