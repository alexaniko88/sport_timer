---
name: skill-orchestrator
description: >
  End-to-end workflow for a change in the Sport Timer app, from a request the user writes in their own
  words: feature branch and worktree, plan, implementation, tests, review, hand-off and optional PR.
  The user approves the plan, the commit and whether to open a PR. There are no tickets. Use when the user says "orchestrate", "let's build",
  "work on this", "handle this", or describes a bug, feature, improvement or refactor to be done
  end-to-end in this repo. Not for read-only investigation (use the
  agent-bug-investigator agent directly) or for PR review comments.
argument-hint: "<what you want, in your own words>"
model: claude-opus-5-5
effort: medium
---

# Orchestrator

## Local task progress

When the request names a local task under `project-tasks/`, read `project-tasks/status.md`, the task file, and its applicable parent indexes before planning: story/epic indexes for story tasks, or `bugs/index.md` / `improvements/index.md` for standalone bug/improvement tasks. Use that task as the request; no external ticket lookup is needed. Check dependencies and completion evidence in the actual checkout/worktree before treating earlier outputs as reusable. Surface blockers rather than silently implementing prerequisite tasks or treating provisional scope as approved.

Maintain `project-tasks/status.md` throughout this orchestration. Mark the selected task In progress when actual work starts. At pauses or handoff, record its branch/worktree context, plan location, completed and remaining steps, validation results, and blockers using portable paths. Mark Done only when its acceptance criteria, required checks, and required user validation are satisfied; record completion evidence and reusable outputs, then reevaluate dependent task readiness and update the overview. Done does not imply committed, merged, or available in another checkout. Keep repeated task/story statuses consistent and do not start another ticket automatically. For requests without a local task, do not invent a backlog entry.

You are the conductor. Read-heavy work (investigate, plan, estimate, review) goes to read-only subagents so their file dumps stay out of the main chat. Code edits and tests go to a Sonnet subagent, so the conductor and the investigation and planning agents run on Opus and the editing runs on the cheaper model.

This skill runs on Claude and on Codex. The models match: Opus is `gpt-6.1-sol` and Sonnet is `gpt-6.1-terra`. On Claude, the named agents are Markdown files in `~/.claude/agents/` and the conductor model comes from the frontmatter above. On Codex, the same agent names are TOML files in `.codex/agents/`, and the conductor model comes from `.codex/config.toml`. Codex has no per-call `model` option, so every step must use a named agent.

There are no tickets. The user's own message is the request. Never look for a ticket, a Linear link or a ticket ID.

**Ask for approval of the plan (Stage 1), the commit (Stage 5), and then whether to open a PR (Stage 6). Everything between plan approval and the commit hand-off runs without asking.** Do not ask for confirmation of the request, of each step, of tests, or of review fixes. Reuse explicit approval already given in the session rather than asking again.

## Project context

`CLAUDE.md` is already loaded: read it for commands, architecture and pinned dependencies, and do not repeat it in briefs. Every agent brief must carry the **project overrides** below, because the shared global rules in `~/.claude/rules/` and `~/.claude/profiles/` were written for another codebase and some of them are wrong here.

- **State management:** MVVM with `ValueNotifier` state. Follow `CLAUDE.md` ("Architecture (MVVM)" and "State management"). No Bloc, no state management package, no `freezed`, no code generation. `go_router` stays.
- **Strings:** the app has no localization. Hardcode user-facing English text in the widget. No `FIXME-ALEX` blocks, ARB files or `Localized` keys.
- **No `docs/CodeStyleGuide.md`** exists. The Dart style rules in `~/.claude/rules/flutter/dart-core.md` still apply (switch and pattern matching, null safety, trailing commas, format and analyze on touched files only, by literal path).
- **Tests:** unit tests use hand-written fakes (no mocking package unless the plan adds one). Not `mocktail`, `alchemist` or `patrol_finders`. Test paths mirror `lib/`: `test/features/<name>/<file>_test.dart`.
- **Dependencies:** `pubspec.yaml` versions stay pinned exactly, with no `^`. Do not bump a package unasked. The `basic_flutter_helper` package is gone: put shared helpers in `lib/core/`.
- **Commands:** always `fvm flutter` and `fvm dart`, never bare `flutter` or `dart`.
- **Personal repo (`alexaniko88`):** nothing from any employer in code, comments, commit messages or generated files. No `/Users/<name>/...` paths, no company names or emails.
- **Git:** subagents never stage, commit, push or create branches or worktrees. The conductor creates the feature branch and worktree in Stage 0 without a separate approval, and stages and commits only after the Stage 5 approval. Approval to open the PR in Stage 6 also authorizes pushing its feature branch. Otherwise, never push without separate explicit approval.

Briefs: ask each agent for a short report (about 300 words, findings first, no file dumps). Run independent agents in parallel in one message. Model and effort of the named agents come from their own file (frontmatter on Claude, TOML on Codex), so do not override them. Do not use `agent-terminal-app-solution-impl` or `agent-test`: both are built to ask before every edit and to read test rules written for another codebase.

## Stage 0: Create the feature branch and worktree

Before planning or implementation for a new request, create a dedicated Git worktree with a new branch named `feat/<short-feature-summary>`. Use a brief lowercase, hyphen-separated summary, usually 2–5 words, such as `feat/workout-templates` or `feat/timer-pause-fix`. This step is authorized by starting the orchestration; do not ask for separate branch or worktree approval, except when environment permissions require it.

Check the current branch, working tree and `git worktree list` first. Use the current `HEAD` as the starting point unless the user specifies another base. Preserve existing changes; do not reset, discard, stash or copy them into the new worktree automatically. If the feature depends on uncommitted changes, report that dependency before proceeding.

Use the repo's established worktree location, or default to `<repo-root>/.worktrees/<short-feature-summary>` and ensure `.worktrees/` is ignored locally before creation. For example, run `git worktree add -b feat/workout-templates <worktree-path> HEAD`. Do not overwrite an existing branch or directory; choose a short unique suffix when needed. When resuming the same orchestration, reuse its existing branch and worktree.

Run all feature investigation, edits, dependency setup, tests, review and approved commits from that worktree. Give every subagent its explicit working directory and verify the branch before editing or committing. Leave the original checkout on its existing branch. Report the feature branch, worktree path and starting commit, and record them with the approved plan. Keep the worktree for hand-off; remove it only when the user requests cleanup, preserving any uncommitted work.

## Scope changes during an orchestration

Use the original request and, once approved, the saved plan as the scope boundary. If the user asks for a new feature outside that scope, explicitly say that it is outside the current plan and suggest a separate orchestration with its own `feat/...` branch, worktree and plan. Keep the new feature out of the current implementation unless the user explicitly chooses to expand the current plan; then update the plan and obtain approval for the expanded scope before implementing it. Necessary fixes and clarifications that fulfill the original plan are not separate features.

## Stage 0: Create the feature branch and worktree

Before planning or implementation for a new request, create a dedicated Git worktree with a new branch named `feat/<short-feature-summary>`. Use a brief lowercase, hyphen-separated summary, usually 2–5 words, such as `feat/workout-templates` or `feat/timer-pause-fix`. This step is authorized by starting the orchestration; do not ask for separate branch or worktree approval, except when environment permissions require it.

Check the current branch, working tree and `git worktree list` first. Use the current `HEAD` as the starting point unless the user specifies another base. Preserve existing changes; do not reset, discard, stash or copy them into the new worktree automatically. If the feature depends on uncommitted changes, report that dependency before proceeding.

Use the repo's established worktree location, or default to `<repo-root>/.worktrees/<short-feature-summary>` and ensure `.worktrees/` is ignored locally before creation. For example, run `git worktree add -b feat/workout-templates <worktree-path> HEAD`. Do not overwrite an existing branch or directory; choose a short unique suffix when needed. When resuming the same orchestration, reuse its existing branch and worktree.

Run all feature investigation, edits, dependency setup, tests, review and approved commits from that worktree. Give every subagent its explicit working directory and verify the branch before editing or committing. Leave the original checkout on its existing branch. Report the feature branch, worktree path and starting commit, and record them with the approved plan. Keep the worktree for hand-off; remove it only when the user requests cleanup, preserving any uncommitted work.

## Scope changes during an orchestration

Use the original request and, once approved, the saved plan as the scope boundary. If the user asks for a new feature outside that scope, explicitly say that it is outside the current plan and suggest a separate orchestration with its own `feat/...` branch, worktree and plan. Keep the new feature out of the current implementation unless the user explicitly chooses to expand the current plan; then update the plan and obtain approval for the expanded scope before implementing it. Necessary fixes and clarifications that fulfill the original plan are not separate features.

## Stage 1: Plan 🛑

1. **Understand the request.** If something blocks you (missing repro steps, unclear behaviour), ask at most 3 short questions, each with a suggested answer, and wait. If it is clear enough, go on without asking.
2. **Investigate or plan**, read-only, with the project overrides in the brief:
   - Bug, regression or crash: `agent-bug-investigator`.
   - Feature, improvement, refactor or build setup: `agent-ticket-planner`.
   - Accessibility: `agent-flutter-a11y-agent`, plus one of the above when real logic is involved.
   - Skip the agent when the request is small and the fix is obvious after you read the code yourself.
3. **Estimate (optional):** run `agent-ticket-estimator` only for risky areas: timer countdown logic, audio playback, Firebase auth, the Android or iOS build setup, or a dependency bump.
4. **Settle open decisions yourself.** For each Open Decision pick the recommended option and list it in the plan as "decided, change it if you disagree". Ask the user only when a decision is expensive to undo and you cannot judge it from the code. Use the `grilling` skill only when the user asks for it (`/grill-me`).
5. **Present one plan, in plain English:**
   - **Request:** what is wanted and what "done" looks like, in 2-3 lines.
   - **Approach:** the fix or design, grounded in how the code is built today.
   - **Decisions made:** each with the alternative you rejected.
   - **Steps:** a short numbered list, one file or concern each.
   - **Tests:** which logic gets tests and which kind, or why none.
   - **Risks:** anything that could break, and the estimate if you ran one.

   Then stop. **Do not touch code until the user approves the plan.** If they change it, update the plan and continue without asking again unless the change is large.

After approval, write the plan and the step list to a project memory file `project_<short-slug>.md` (pointer line in `MEMORY.md`, per the memory rules), and tick steps off as they finish. On a new session, look for that file first and continue from the next open step.

## Stage 2: Implement

Dispatch one agent: on Claude a general-purpose agent with `model: sonnet`, on Codex `agent-implementer`. Put in the brief: the approved plan, the decisions, the step list, the project overrides, and these rules:

- Do all the steps in order, without waiting for approval between them. The user approved the plan already.
- Scope is exactly the plan: no bonus refactors, no unrelated cleanup, no extra tests or docs. Mention an unrelated issue in one line at the end.
- Comments: one or two short plain sentences explaining why, only where the code is not obvious. Match the density of the surrounding code.
- Run `fvm dart format and `fvm flutter analyze` on the touched files by literal path, and fix what they report.
- **Stop only on a design surprise** that breaks the approved plan (a wrong assumption, a conflict between steps). Return 2 short options with a recommendation and the work done so far. Do not guess.
- Final report: files touched, what changed and why in a few bullets, the analyze result, and every `TODO` or `FIXME` added.

When the agent reports a surprise, decide it yourself if the answer is clear from the code and tell the user in one line afterwards. Ask the user only when the choice changes the approved plan in a way they would care about.

## Stage 3: Tests

Skip this stage for pure UI or text changes with no logic. Otherwise dispatch the Stage 2 kind of agent (Claude: general-purpose with `model: sonnet`, Codex: `agent-implementer`), or continue the Stage 2 agent, to write tests for the changed logic only, never for untouched surrounding code. The project has almost no tests: only the old counter smoke test, which fails and is out of scope unless the user says so.

- Use the test rules in the project overrides. Read one existing test of the same kind first if there is one, and copy its structure.
- If a test needs infrastructure that does not exist yet (a first fake or test helper), build the smallest version the plan's tests need and say so in the report. Do not add anything else.
- Run only the tests it wrote or touched, by file path: `fvm flutter test <path>`. Fix failures that come from the test. If a failure shows a real bug in the code, stop and report it instead of patching production code silently.

## Stage 4: Review

- Dispatch `agent-pr-review` on the diff against `master` (`git diff master` for uncommitted work), with the project overrides in the brief so it does not flag Bloc, hardcoded strings or the missing style guide. For UI changes, optionally `agent-flutter-a11y-agent` in parallel.
- **Fix Critical and General findings** with the Stage 2 agent, without asking, then re-run the Stage 3 tests and `flutter analyze`. Do at most 2 review-and-fix rounds. If Critical findings remain after the second round, stop and show them to the user. Minor findings are not fixed unless trivial; list them in the summary.
- After a change that applies a rule across the app (a style sweep, a rename), run your own search for the pattern (`grep`) and check the matches by hand. Do not rely only on a subagent's list.
- Suggest the built-in `/code-review` for a second pass only when the change is large or risky. Do not run it unasked.

## Stage 5: Hand-off 🛑

Run the checks that apply and show the result:

- `fvm flutter analyze` reports no issues, and the new or touched tests pass.
- If `android/`, `ios/` or `pubspec.yaml` changed: `fvm flutter build apk --debug` (and `fvm flutter build ios --debug --no-codesign` when `ios/` changed) succeeds.
- No local absolute path in the diff (`git diff | grep -n "/Users/"` returns nothing), and no company name or work email address when you read it.
- List every `TODO` or `FIXME` the diff adds, with `file:line`.

Then give a short summary of what was done and which decisions changed on the way. Draft the commit: a message in the format of `.claude/rules/git-commits.md` (`<type>: <description>`, such as `feat: add workout templates page`), the `Co-Authored-By` trailer, and the exact list of files. Show it and wait for approval. After approval, check that `git config user.email` is the repo-local noreply address, then commit and proceed to Stage 6. Commit approval alone does not authorize a push.

## Stage 6: Offer to open the PR 🛑

Once implementation and review are complete, required checks pass, and the approved commit exists, prepare a short PR title and description covering the final change, validation results and any remaining limitations. Show the source branch, target branch (`master` unless the user specifies another), title and description, then ask: "Would you like me to push this branch and open the PR?" Wait for the answer unless the user has already explicitly requested this PR in the current orchestration. Do not offer a ready-for-review PR while required checks fail or blocking review findings remain.

If the user agrees, push the feature branch with its upstream and create the PR against the stated target. Check for an existing open PR for the same source and target first; reuse it rather than creating a duplicate. Return the PR link. If the user declines, leave the commit and worktree available locally. Do not merge the PR or remove the worktree without a separate user request.
