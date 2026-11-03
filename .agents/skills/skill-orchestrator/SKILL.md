---
name: skill-orchestrator
description: >
  End-to-end workflow for a change in the Sport Timer app, from a request the user writes in their own
  words: feature branch, plan, implementation, tests, review, hand-off and optional PR.
  Clear plans proceed without approval. The user approves completed implementation with passing tests; review suggestions are discussed when present, then one PR approval covers commit, push and opening the PR. There are no tickets. Use when the user says "orchestrate", "let's build",
  "work on this", "handle this", or describes a bug, feature, improvement or refactor to be done
  end-to-end in this repo. Not for read-only investigation (use the
  agent-bug-investigator agent directly) or for PR review comments.
argument-hint: "<what you want, in your own words>"
model: claude-opus-5-5
effort: medium
---

# Orchestrator

## Local tasks

When the request names a local task under `project-tasks/`, read the task file and its applicable parent indexes before planning: story/epic indexes for story tasks, or `bugs/index.md` / `improvements/index.md` for standalone bug/improvement tasks. Use that task as the request; no external ticket lookup is needed. Check dependencies and completion evidence in the actual checkout and branch before treating earlier outputs as reusable. Surface blockers rather than silently implementing prerequisite tasks or treating provisional scope as approved.

Do not maintain traffic-light statuses, readiness counts, or repeated progress summaries in task files or parent indexes. Report implementation steps and validation evidence in conversation. Do not start another task automatically.

After review passes and any chosen review suggestions are addressed, archive the completed local task immediately, without asking, using [Project tasks — Archiving completed work](../skill-project-tasks/SKILL.md#archiving-completed-work). Record acceptance and validation evidence and branch context; move the task, and eligible parent story and epic, update links and validate them. Leave these changes uncommitted until the user authorizes a commit or opening the PR. Archive only this task's own file; previously archived tasks may move with their completed parent. Do not start another task solely for cleanup.

You are the conductor. Read-heavy work (investigate, plan, estimate, review) goes to read-only subagents (where the tool has them) so their file dumps stay out of the main chat. Code edits and tests go to `agent-implementer`, which runs on the cheaper model.

## Tool adapter

This skill runs the same way on Claude, Codex and Antigravity. Agent roles are defined once in `.agents/skills/skill-orchestrator/roles/<name>.md`, with `model`, `effort` and `access` in its frontmatter. Claude and Antigravity need no agent files; Codex has thin TOML files that only carry the model. The Claude-only keys in this skill's own frontmatter (`model`, `effort`, `argument-hint`) are ignored by the other tools.

| | Claude | Codex | Antigravity |
| --- | --- | --- | --- |
| Start the skill | `/skill-orchestrator` | `$skill-orchestrator` or `/skills` | Name the skill in plain words |
| Dispatch a role | Agent tool as a general-purpose agent, with `model` and `effort` ALWAYS set from the role file's frontmatter. Never pass a role name (`agent-pr-review`, `agent-bug-investigator`, `agent-ticket-planner`, `agent-ticket-estimator`, `agent-plan-reader`, `agent-implementer`, `agent-flutter-a11y-agent`) as `subagent_type`: those names also exist as generic global agents written for another codebase, so always use a general-purpose agent. The brief starts with "Read `.agents/skills/skill-orchestrator/roles/<name>.md` and follow it", then the plan and the overrides | Spawn the agent with the same name; its TOML only carries model and effort | No subagents: read the role file and run the stage in the main thread, with the same checkpoints and the same report |
| Conductor model | Opus | `gpt-6.1-terra`, chosen on purpose in `.codex/config.toml` | Its own |
| Agent model and effort | Role file frontmatter | `.codex/agents/<name>.toml` (must equal the role file) | Role file frontmatter |
| Ask the user | Short numbered question in chat, using the question dialog (when the tool has one) | Short numbered question in chat | Short numbered question in chat |

Opus is `gpt-6.1-sol` and Sonnet is `gpt-6.1-terra`. The role file frontmatter holds the model and effort of every role, so every step must use one of the seven roles and never override them. A role with `access: read-only` must never edit files, whatever the tool or the brief says. Run parallel agents only where the tool has them and supports it; otherwise run them one after the other.

There are no tickets. The user's own message is the request. Never look for a ticket, a Linear link or a ticket ID.

**Approval cadence:** present the plan (Stage 1), then proceed without asking for plan approval unless an important requirement or decision is unclear and cannot be resolved from the request or code. Ask for clarification only on that uncertainty. Ask for approval of all implementation and tests together after the code is applied and required tests pass (end of Stage 3), then complete review and archive the task before the PR decision. Run review only after approval of the completed implementation and tests. If review leaves suggestions for the user, present them and wait for their choice; a clean review proceeds directly to archival and hand-off without a separate review approval. Then ask whether to open a PR (Stage 6). Complete each stage without asking between files, edits, tests or required review fixes. Reuse explicit approval already given in the session, including after a resume; one approval to open the PR authorizes the commit, push and PR creation; never ask separately for those actions. This is the user's chosen cadence, replacing the general one-step-per-turn validation workflow. Carry it in every agent brief.

## Project context

`CLAUDE.md` is already loaded: read it for commands, architecture and pinned dependencies, and do not repeat it in briefs. Every agent brief must carry the **project overrides** below, because the shared global rules in `~/.claude/rules/` and `~/.claude/profiles/` were written for another codebase and some of them are wrong here. `.agents/rules/dart-style.md` and `CLAUDE.md` are complete on their own. If the machine also has a global `~/.claude/rules/flutter/dart-core.md`, it adds to them; where they differ, the repo files win.

- **Layered architecture:** code is feature-first: `lib/features/<name>/{domain,data,presentation}` (only the layers a feature needs), shared UI in `lib/shared/presentation/`, pure helpers in `lib/core/`, composition in `lib/di/di.dart`, `main.dart` and `navigation.dart`. Domain imports only `dart:*`, `core/` and other domain files; presentation never imports `data/` or platform packages; data never imports presentation; contracts return app types, never platform types. Helpers on a single type are extensions, one per file, in an `extensions/` folder of their layer. Put every new file in the right layer, add use cases only for real logic. Follow `CLAUDE.md` ("Project layout", "Architecture (MVVM and layers)", "Boundary check"). The plan must name the layer of each new or moved file.
- **Extensions, not helper functions:** a helper that works on one type (first argument is the thing it works on, or it maps one type to another) must be an extension in the `extensions/` folder of its layer (`core/extensions/`, `shared/presentation/extensions/`, `features/<name>/<layer>/extensions/`), one extension per file, named after the type it extends. Never add a top-level helper function when an extension fits. See `CLAUDE.md` ("Extensions") and `.agents/rules/dart-style.md`. The plan names each extension and its file; the implementation brief repeats this rule.
- **Styling:** the app has one shared look, described in `CLAUDE.md` ("Styling and theme"). Bordered tiles use `AppSurface`; radius and border width come from `AppRadius` and `AppBorderWidth`; button and dialog shapes come from `SportTheme`; text roles come from `AppTextThemeExtension` and `AppTextStyles`; colors from the theme, alpha from `AppAlpha` or `TimerAlpha`. Never hand-build a tile with its own border, a raw radius, border width, alpha or color, or a repeated `copyWith(fontWeight: ...)`. The plan names any new shared token, widget or text role and the 2 or more places that use it. The goldens are the visual reference; do not run an emulator or simulator to check a style.
- **State management:** MVVM with `ValueNotifier` state. Follow `CLAUDE.md` ("Architecture (MVVM)" and "State management"). No Bloc, no state management package, no `freezed`, no code generation. `go_router` stays.
- **Strings:** the app uses `gen-l10n` (`l10n.yaml`, `lib/l10n/`). Every user-facing string (text, tooltips, semantic labels, snackbars) comes from `context.l10n`, and dates and numbers follow the locale. Add each new key to both `app_en.arb` and `app_es.arb` (with a `description` in the English one, ICU plural messages for counts) and run `fvm flutter gen-l10n`. Never hardcode English text and never add `FIXME-ALEX` blocks: the global rule that does so is for another codebase.
- **Project rule files:** `.agents/rules/dart-style.md` (Dart style, wins over the shared Dart rules) and `.agents/rules/git-commits.md` (branch names, commit messages, PR titles) apply to every tool, not only Claude. Every agent that reads, writes or reviews Dart reads the first; the conductor follows the second for the branch in Stage 0 and for the commit and PR title in Stage 6.
- **No `docs/CodeStyleGuide.md`** exists. The generic Dart points that matter here are kept in `.agents/rules/dart-style.md` (switch and pattern matching, null safety, trailing commas, format and analyze on touched files by literal path).
- **Tests:** unit tests use hand-written fakes (no mocking package unless the plan adds one). Not `patrol_finders`. Test paths mirror `lib/`: `test/features/<name>/<layer>/<file>_test.dart`. `test/architecture/layer_boundaries_test.dart` enforces the layer rules; fix the code instead of loosening it, and add a named exception there only with a written reason. UI snapshot goldens live in `test/snapshots/ui_snapshots_test.dart` (`test/snapshots/goldens/*.png` and `test/snapshots/README.md`) and use `alchemist` platform goldens on macOS. Integration tests (`integration_test/`, Android only) follow `.agents/skills/skill-integration-tests/SKILL.md`; read it when a task writes, changes or runs them, and give it to the agents that do the work. `fvm flutter test` does not run them.
- **Dependencies:** `pubspec.yaml` versions stay pinned exactly, with no `^`. Do not bump a package unasked. The `basic_flutter_helper` package is gone: put pure shared helpers in `lib/core/` and shared UI in `lib/shared/presentation/`.
- **Commands:** always `fvm flutter` and `fvm dart`, never bare `flutter` or `dart`.
- **Personal repo (`alexaniko88`):** nothing from any employer in code, comments, commit messages or generated files. No `/Users/<name>/...` paths, no company names or emails.
- **Git:** follow `.agents/rules/git-commits.md` for commit messages. Subagents never stage, commit, push or create branches. The conductor creates the feature branch from `master` in Stage 0 without a separate approval, and stages and commits after the Stage 5 checks when the user requests a commit or approves opening the PR. Approval to open the PR also authorizes the commit and push. Otherwise, never push without separate explicit approval.

Briefs: ask each agent for a short report (about 300 words, findings first, no file dumps). Run independent agents in parallel in one message, where the tool has subagents. Model and effort of each role come from its role file frontmatter (and `.codex/agents/<name>.toml` for Codex), so do not override them; on Claude, start the brief with "Read `.agents/skills/skill-orchestrator/roles/<name>.md` and follow it". Use only the seven roles in `roles/` (`agent-bug-investigator`, `agent-ticket-planner`, `agent-ticket-estimator`, `agent-plan-reader`, `agent-pr-review`, `agent-implementer`, `agent-flutter-a11y-agent`). Do not use `agent-terminal-app-solution-impl` or `agent-test`: both are built to ask before every edit and to read test rules written for another codebase.

## Stage 0: Create the feature branch

Before planning or implementation for a new request, create a new branch named `<prefix>/<short-summary>` from `master` in the current checkout. Never create a Git worktree. The prefix is `feat` for new behavior, `fix` for a bug, or `improve` for a change to something that already works. Never use `chore`, `docs` or any other prefix. Use a brief lowercase, hyphen-separated summary, usually 2-5 words, such as `feat/workout-templates`, `fix/timer-pause` or `improve/template-tiles`. This step is authorized by starting the orchestration; do not ask for separate branch approval.

Run `git status -sb` first. If there are uncommitted changes, report them and do not carry them into the new branch unless they belong to the request. Then run `git switch master`, `git pull --ff-only` and `git switch -c <prefix>/<short-summary>`. Start from another base only when the user says so, for example when the task depends on a branch that is not merged yet. Do not overwrite an existing branch; choose a short unique suffix when needed. When resuming the same orchestration, reuse its existing branch.

Run all investigation, edits, tests, review and approved commits on that branch. Give every subagent the repo path and verify the branch before editing or committing. Report the feature branch and the starting commit in conversation.

## Scope changes during an orchestration

Use the original request and the plan presented in conversation as the scope boundary. If the user asks for a new feature outside that scope, explicitly say that it is outside the current plan and suggest a separate orchestration with its own branch (`feat/`, `fix/` or `improve/`) and plan. Keep the new feature out of the current implementation unless the user explicitly chooses to expand the current plan; then update the plan in conversation and proceed within that explicitly requested scope. Ask only if an important requirement or decision remains unclear. Necessary fixes and clarifications that fulfill the original plan are not separate features.

## Stage 1: Plan

1. **Understand the request.** If something blocks you (missing repro steps, unclear behaviour), ask at most 3 short questions, each with a suggested answer, and wait. If it is clear enough, go on without asking.
   For UI-related work, inspect the relevant images in `test/snapshots/goldens/` and `test/snapshots/README.md` before planning; give the relevant references to planning and implementation agents. Treat snapshots as a captured baseline, verify the current checkout, and follow the task’s agreed design rather than assuming a snapshot is the intended result. Include snapshot and flow-index updates in the plan when the visible UI or navigation changes. Pure logic work does not need this visual inspection.
2. **Investigate or plan**, read-only, with the project overrides in the brief:
   - Bug, regression or crash: `agent-bug-investigator`.
   - Feature, improvement, refactor or build setup: `agent-ticket-planner`.
   - Accessibility: `agent-flutter-a11y-agent`, plus one of the above when real logic is involved.
   - Skip the agent when the request is small and the fix is obvious after you read the code yourself.
3. **Estimate (optional):** run `agent-ticket-estimator` only for risky areas: timer countdown logic, audio playback, Firebase auth, the Android or iOS build setup, or a dependency bump.
   **Cold read (optional):** for the same risky areas as the estimate, and for any plan with 4 or more steps or a new screen, run `agent-plan-reader` once on the drafted plan. Give it only the plan text from the Steps, Approach and Tests parts: never the user's request, the investigator's report or any earlier conversation, because a reader that knows them cannot see what the plan leaves out. On Antigravity, which has no subagents, run it in the main thread only if the plan can be reread without leaning on the request; otherwise skip it and say so. Compare its 3-line summary with the request. Fix the plan for each real guess or unclear step, and settle the rest as decisions in step 4. Do one round only, and skip it for small or obvious changes.
4. **Settle open decisions yourself.** For each Open Decision pick the recommended option and list it in the plan as "decided, change it if you disagree". Ask the user only when a decision is expensive to undo and you cannot judge it from the code. Use the `grilling` skill only when the user asks for it (`/grill-me`).
5. **Present one plan, in plain English:**
   - **Request:** what is wanted and what "done" looks like, in 2-3 lines.
   - **Approach:** the fix or design, grounded in how the code is built today.
   - **Decisions made:** each with the alternative you rejected.
   - **Steps:** a short numbered list, one file or concern each.
   - **Tests:** which logic gets tests and which kind, or why none.
   - **Risks:** anything that could break, and the estimate if you ran one.

   **Proceed without asking for plan approval when the request and approach are clear.** Pause only to clarify an important uncertainty that cannot be resolved from the request or code. If the user changes the plan, update it and continue within their requested scope; do not add a plan approval checkpoint.

## Stage 2: Implement

Dispatch one `agent-implementer`. Put in the brief: the plan, the decisions, the step list, the project overrides, and these rules:

- Do all implementation steps in order, without waiting for approval between them. The user authorized the task; a clear plan needs no separate approval. Leave writing tests to Stage 3 and return to the conductor when implementation and its checks are complete.
- Scope is exactly the plan: no bonus refactors, no unrelated cleanup, no extra tests or docs. Mention an unrelated issue in one line at the end.
- Comments: one or two short plain sentences explaining why, only where the code is not obvious. Match the density of the surrounding code.
- Run `fvm dart format` and `fvm flutter analyze` on the touched files by literal path, and fix what they report.
- **Stop only on a design surprise** that breaks the plan (a wrong assumption, a conflict between steps). Return 2 short options with a recommendation and the work done so far. Do not guess.
- Final report: files touched, what changed and why in a few bullets, the analyze result, and every `TODO` or `FIXME` added.

When the agent reports a surprise, decide it yourself if the answer is clear from the code and tell the user in one line afterwards. Ask the user only when the choice changes the plan in a way they would care about.

After all implementation steps are applied and format/analyze checks pass, continue directly to Stage 3. Do not ask for implementation approval before tests. If no new tests are needed, explain why and still run the full suite before the approval checkpoint. Do not seek validation of individual steps.

## Stage 3: Tests and implementation approval 🛑

For changed logic, dispatch `agent-implementer`, or a fresh agent of the same role, to write tests for the changed logic only, never for untouched surrounding code. For pure UI or text changes, explain if no new tests are needed; still run the full suite below.

- Use the test rules in the project overrides. Read one existing test of the same kind first if there is one, and copy its structure.
- If a test needs infrastructure that does not exist yet (a first fake or test helper), build the smallest version the plan's tests need and say so in the report. Do not add anything else.
- Run focused tests by file path while working, then run the entire suite with `fvm flutter test` after implementation and snapshot updates, before requesting approval. Fix stale test expectations caused by the change and rerun the suite. If a failure shows a real bug in the code, stop and report it instead of patching production code silently. Report unrelated or environment failures clearly; do not claim the suite passed.
- When a change alters a captured UI screen, state, theme or route transition (or adds a new screen or meaningful state), update `test/snapshots/ui_snapshots_test.dart` if needed, run `fvm flutter test --update-goldens test/snapshots/ui_snapshots_test.dart` on macOS to refresh `test/snapshots/goldens/*.png`, and update `test/snapshots/README.md`.
- When the task adds or changes an integration test, or changes code that an existing integration flow covers, also run the integration suite with the repository run script (see `skill-integration-tests`) on Android. If no Android target is available, say so in the approval checkpoint and do not claim it passed.

After all planned tests are written and the full suite passes, present the completed implementation, changed files, test coverage and check results together. Ask once for approval of this completed code and tests, then wait before starting Stage 4. Do not ask separately for tests or before writing or running each test. When no new tests are needed, explain why at the same checkpoint.

## Stage 4: Review

- Dispatch `agent-pr-review` on the diff against `master` (`git diff master` for uncommitted work), with the project overrides in the brief so it does not flag Bloc or the missing style guide, and so it checks the layer rules (files in the right layer, no platform types in domain contracts, no use-case pass-throughs). It flags any new user-facing string that is not a `context.l10n` key in both ARB files as a General finding. It flags any new top-level helper function that should be an extension, or an extension outside an `extensions/` folder, as a General finding. It also flags as General any hand-built bordered tile, raw radius, border width, alpha or color literal, per-button shape, or repeated text style that the Styling override replaces with a shared piece, unless it is one of the documented exceptions in `CLAUDE.md`. For UI changes, optionally `agent-flutter-a11y-agent` in parallel. When the diff has no `lib/` files, tell `agent-pr-review` in the brief to review every changed file (docs, tooling and tests included).
- **Fix Critical and General findings** with the Stage 2 agent, without asking, then re-run the Stage 3 tests and `flutter analyze`. Do at most 2 review-and-fix rounds. If Critical or General findings remain after the second round, stop and show them to the user; do not report review as passed. Minor findings are not fixed unless trivial; list them in the summary. These fixes and their test updates stay within this stage and do not reopen the combined implementation-and-tests approval checkpoint.
- After a change that applies a rule across the app (a style sweep, a rename), run your own search for the pattern (`grep`) and check the matches by hand. Do not rely only on a subagent's list.
- Suggest the built-in `/code-review` for a second pass only when the change is large or risky. Do not run it unasked.

Once review and checks pass, report the verdict, fixes applied and remaining suggestions. If there are no remaining suggestions, archive the completed task and proceed directly to Stage 5 without asking for review approval. If suggestions remain, present each with a recommended action and wait for the user's choice. Apply selected in-scope suggestions and validate them within this stage without asking for each edit, then archive the completed task and proceed to the hand-off. Never treat a blocked review as successful.

## Stage 5: Hand-off 🛑

Run the checks that apply and show the result:

- `fvm flutter analyze` reports no issues, and the full test suite passes (this includes `test/architecture/layer_boundaries_test.dart`). If the change adds or moves files, check that `CLAUDE.md` still describes the real layout. Report the latest full-suite result; rerun it if subsequent changes could affect the result.
- If any captured UI screen, state, theme or route changed, `fvm flutter test test/snapshots/ui_snapshots_test.dart` passes and `test/snapshots/README.md` is up to date.
- If `android/`, `ios/` or `pubspec.yaml` changed: `fvm flutter build apk --debug` (and `fvm flutter build ios --debug --no-codesign` when `ios/` changed) succeeds.
- No local absolute path in the diff (`git diff | grep -n "/Users/"` returns nothing), and no company name or work email address when you read it.
- List every `TODO` or `FIXME` the diff adds, with `file:line`.

Then summarize the completed change, checks, review and archived task. Prepare the commit and PR details for review. Do not ask separately for commit approval: proceed to the single PR question in Stage 6 unless the user explicitly requested only a commit. An explicit commit-only request authorizes committing without separate message approval, but does not authorize a push.

## Stage 6: Offer to open the PR 🛑

Once implementation and review are complete, required checks pass, and the completed local task has been archived, prepare a short PR title and description covering the final change and validation. Show the source and target branches (`master` unless specified otherwise), then ask: "Do you agree with opening the PR?" Explain that approval covers committing the intended changes, pushing the branch and opening the PR. Reuse an explicit request already given for this PR; do not ask again. Do not offer a ready-for-review PR while required checks fail or blocking review findings remain.

If the user agrees, check the repo-local noreply email, stage only intended files, commit the implementation and archive (together or separately as appropriate), push the feature branch and create the PR. Check for an existing open PR for the same source and target first and update it instead of creating a duplicate. Report the commit message and hash, files and PR link. If the user declines, leave the work local. Never merge without a separate user request.
