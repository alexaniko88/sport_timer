# Atomic tasks and assembly

Use this after the interview completeness review. The task format owns the required fields and sections; this reference explains how to choose the split.

## Choose complete building blocks

Start from the agreed feature and existing pieces. Identify only the missing blocks it needs, then the assembly that connects them. A block can be a widget, service, ViewModel with its state, or a database operation. One responsibility may span several files. Do not create speculative abstractions or split a trivial supporting type into a separate PR merely because it is another file.

Each task has a precise contract, relevant failures and boundaries, and tests that can pass after its prerequisites merge. Keep existing behavior usable and the app buildable after every PR. Do not split an operation's happy path from its required failures, a migration from compatibility with existing readers, or a state type from the behavior needed to handle its values.

Typical shapes:

- **Logic/data block:** one bounded capability with unit tests, using hand-written fakes where appropriate. Include its contract and implementation together when separating them adds no useful independence.
- **ViewModel/state block:** state transitions, async/disposal behavior and unit tests. No view spec or mockup merely because its files are in presentation.
- **Visual widget:** constructor, inputs, callbacks and visual states. Link to the approved design; plan component goldens in the existing snapshot harness when appearance needs verification. Add a behavioral widget test only for a specified interaction that unit tests and goldens cannot establish.
- **Assembly:** consume completed blocks and own the named dependency registrations, page ownership/disposal, routes and parent wiring. Test assembled behavior using the smallest relevant unit/golden or justified widget checks. Material new business logic indicates a missing block. Assembly can itself be split by independent wiring responsibilities, with an explicit owner for the final combined checks.
- **Bug/refactor:** a bounded cause fix plus regression checks, or a behavior-preserving step with green checks after each merge. Do not fragment a cohesive fix or mechanical change solely by file count.

A prerequisite may have only test callers until assembly. Name its consumer task and planned location before dispatch. Keep one-feature pieces in that feature. Shared UI still needs two actual users under `CLAUDE.md`; if consumers are not built yet, keep the piece feature-local and assign any later promotion and reuse to an explicit task.

## Fix the contracts and graph

Specify new APIs deliberately, rather than pretending they already exist. In each task's Contract, label symbols `existing`, `new here`, or `provided by <task-id>`. Include exact repository-relative locations, signatures/data shapes and relevant error, ownership and lifecycle rules. Existing names must be checked in the repo. Proposed symbols must follow existing patterns.

Define a shared agreement once in the parent story (epic for cross-story use). Tasks link to that agreement and list the exact subset they provide or consume. Standalone tasks carry their own contract. No downstream runner chooses between conflicting specifications; reconcile conflicts during planning. Contracts freeze for implementation. A necessary contract change returns to planning, not a runner's private redesign.

List real code dependencies in `depends-on`. Do not serialize independent pieces for convenience. Dependencies become runnable only when prerequisites are done on master, so avoid unnecessary merge chains. `ready` means specified, not immediately runnable. Exact `touches` paths expose shared-file collisions; overlap serializes execution but does not replace a semantic dependency. Give localization keys and golden outputs clear owners, including edits to a shared snapshot harness.

Resolve code/documentation questions during planning. If a fact requires an experiment outside runner boundaries, keep it in planning and record its evidence. A dispatcher prerequisite is allowed only for a useful code/test deliverable within its normal boundaries, with known acceptance checks. Tasks whose contracts depend on an unknown experiment result stay draft until a planner follow-up incorporates the result and passes their cold reads. Do not invent a research task type or send findings-only work to the three-stage code pipeline.

## Settle validation before readiness

Read the dispatcher overrides' Common and Tests sections. Specify literal test paths, the relevant cases, exact check commands, golden outputs, and any small task-specific fakes or harness changes. Reuse existing infrastructure; if genuinely new infrastructure is needed, plan it explicitly rather than making the tests runner discover and build it.

Unit tests cover logic by default. Goldens check relevant appearance, not callbacks or lifecycle. Each behavioral widget test needs a short reason stating what unit/golden checks cannot prove. Pure wiring can need a focused widget test; do not manufacture logic unit tests for it. Do not write redundant tests just to give every stage work.

Existing architecture checks and `tool/agent_check.dart --skip-build` remain mandatory; its regression snapshot run may be broader than the task's new tests. Do not remove those checks to achieve smaller tasks. Device integration tests are planned separately, not included in ordinary dispatcher tasks or their skills. No app launch, device session, browser validation or unplanned helper script may be required for acceptance. A known tooling or test-infrastructure gap prevents readiness.

## Validate the whole split

Keep a concise requirement-to-task-to-acceptance-check table in the story index (epic for shared requirements; standalone task for standalone work). Give requirements stable local references such as R1, without creating another task status system. Transfer every confirmed requirement and exclusion from the interview record; preserve the parent files as the authoritative specification after handoff.

Check both directions: no agreed requirement lacks implementation/verification ownership, and no task adds unagreed scope. A technical prerequisite traces to the requirement and consumer it supports. When several tasks share a requirement, distinguish their contributions and name who verifies the assembled result.

Compare related tasks together for matching producer/consumer contracts, complete wiring, hidden dependencies, conflicting `touches`, and safe merge order. Each task must still be understandable from its own file, parents, upstream contracts and repo. Use per-task cold reads to challenge that; do not replace them with a batch review that hides missing context in a sibling task.

When upstream requirements/contracts change, reopen affected pending tasks, update the authoritative agreements and coverage, and repeat their cold reads. Unknowns must be eliminated during planning. A runtime blocker is a fallback for an unforeseen problem, not the normal completion of a draft plan.
