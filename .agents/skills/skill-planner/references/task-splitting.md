# Simple tasks and assembly

Use this when you split the agreed work. The task format owns the fields and sections; this reference explains how to choose the split.

## The runner's job

A runner gets one task and does only this: write the code, add the tests, run the config's `check` commands and open the PR. It cannot ask anything. So every task must be simple and short to read:

- One responsibility, its code and its tests, one PR, one short run. Aim for 2 to 5 tasks per story.
- It needs no script, no Python, no new tool, no app or device launch, and no command outside the config's `check` list. Its only checks are the allowed `Check` kinds in the format rule.

This is the one place for these limits on the planner side; the runner side is in [runner-rules.md](../../skill-dispatcher/references/runner-rules.md).
- It says exactly what to do. If you are unsure, the runner will be too: settle it now.

## Choose the pieces

Start from the agreed feature and what already exists. Plan only the missing pieces, then the task that wires them together. A piece can be a component, a service, a state or logic unit with its state, or a database operation. One responsibility may span several files.

Do not split for its own sake:

- Keep a contract with its implementation, an operation's happy path with its failures, a migration with compatibility for existing readers, and a state type with the behavior that handles its values.
- Do not give a trivial supporting type its own task, and do not add speculative abstractions.
- Keep the app buildable and existing behavior working after every PR.

Typical shapes:

- **Logic or data:** one capability with unit tests and hand-written fakes where needed.
- **State:** state transitions, async and disposal behavior, unit tests. No view spec or mockup.
- **Visual component:** constructor, inputs, callbacks and visual states, linked to the approved design. When `goldens_dir` is set, plan snapshot images in the project's snapshot test named in the planner notes. Add a behavioral component test only for an interaction unit tests and snapshots cannot check, and say why.
- **Assembly:** wires finished pieces: dependency registration, page ownership and disposal, routes and parent wiring. New business logic here means a missing piece.
- **Bug or refactor:** the fix plus its regression test, or one behavior-preserving step with green checks. Do not cut a cohesive fix into parts.

A piece used only by tests until assembly names its consumer task and planned location. Keep one-feature pieces in that feature; shared UI needs two real users under the project rules.

## Fix the contracts and order

- Fill each task's `## Contract` as the format rule says. Check existing names in the repo; new names follow existing patterns.
- Write a shared agreement once in the story (or the epic, across stories) and link to it. Never let a runner choose between conflicting specs. A contract change goes back to planning.
- `depends-on` lists real code dependencies only. Do not chain independent tasks for convenience. `touches` follows the Overlap rules in the format rule; overlap serializes runs but is not a dependency. Give localization keys, snapshot images and shared test harness edits a clear owner.
- Answer code and documentation questions during planning. Tasks that depend on an unknown result stay `draft`. Never send a findings-only task to the dispatcher.

## Tests and checks

Read the Common and Tests sections of [runner-rules.md](../../skill-dispatcher/references/runner-rules.md), then the Common, Tests and Planning sections of the stack rules (`.agents/rules/stacks/<name>/rules.md`, one per name in the config's `stacks` list; skip this when the list is missing or empty), then the Common and Tests sections of `.agents/planner-dispatcher/project-overrides.md`. Name the exact test files, the cases and any small fake or harness change. Reuse existing test infrastructure; if new infrastructure is really needed, plan it as its own task.

Unit tests cover logic. When `goldens_dir` is unset, skip snapshots; otherwise snapshot images check appearance, not callbacks. A task that adds or changes a snapshot image needs the per-file snapshot update command named in the planner notes' `## Checks` or the project overrides; when neither names it, the task stays `draft` and you tell the user. Do not write tests that add nothing. The config's `check` commands always run. When the project rules or planner notes mention integration tests, plan them outside dispatcher tasks and never use them as a check. A known gap in tooling or test infrastructure keeps the task `draft`.

## Check the whole split

The story's `## Requirements` list each agreed behavior once (R1, R2…) with the tasks that deliver it. Copy every confirmed requirement and exclusion from the planning record; the backlog files are the specification after handoff.

Check both ways: every requirement has a task with an acceptance criterion that checks it, and no task adds scope nobody agreed. Compare related tasks for matching contracts, complete wiring, hidden dependencies, clashing `touches` and a safe merge order. Each task must still be clear from its own file, its parents and its upstream contracts.

When a requirement or contract changes, reopen the affected pending tasks, update the agreements and the table, and cold-read them again.
