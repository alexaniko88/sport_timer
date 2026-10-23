---
name: skill-orchestrator
description: >
  End-to-end workflow for a change in the Sport Timer app, from a request the user writes in their own
  words: plan, implementation, tests, review and hand-off. The user approves one plan up front and one
  commit at the end. There are no tickets. Use when the user says "orchestrate", "let's build",
  "work on this", "handle this", or describes a bug, feature, improvement or refactor to be done
  end-to-end in this repo. Not for read-only investigation (use the
  agent-bug-investigator agent directly) or for PR review comments.
argument-hint: "<what you want, in your own words>"
model: claude-opus-5-5
effort: high
---

# Orchestrator

You are the conductor. Read-heavy work (investigate, plan, estimate, review) goes to read-only subagents so their file dumps stay out of the main chat. Code edits and tests go to a Sonnet subagent, so the conductor and the investigation and planning agents run on Opus and the editing runs on the cheaper model.

There are no tickets. The user's own message is the request. Never look for a ticket, a Linear link or a ticket ID.

**The user stops you twice: to approve the plan (Stage 1) and to approve the commit (Stage 5). Everything in between runs without asking.** Do not ask for confirmation of the request, of each step, of tests, or of review fixes.

## Project context

`CLAUDE.md` is already loaded: read it for commands, architecture, generated code and pinned dependencies, and do not repeat it in briefs. Every agent brief must carry the **project overrides** below, because the shared global rules in `~/.claude/rules/` and `~/.claude/profiles/` were written for another codebase and some of them are wrong here.

- **State management:** the app is moving from Bloc/Cubit to MVVM with `ValueNotifier` state. Follow `CLAUDE.md` ("Target architecture" and "Target state management") for new code and `docs/mvvm-migration.md` for the order. A feature that is not migrated yet keeps its Bloc/Cubit layout (barrel file with `part` directives) until its migration step. Never mix both in one feature. `go_router` stays.
- **Strings:** the app has no localization. Hardcode user-facing English text in the widget. No `FIXME-ALEX` blocks, ARB files or `Localized` keys.
- **No `docs/CodeStyleGuide.md`** exists. The Dart style rules in `~/.claude/rules/flutter/dart-core.md` still apply (switch and pattern matching, null safety, trailing commas, format and analyze on touched files only, by literal path).
- **Tests:** out of scope for the MVVM migration. For other changes, unit tests use hand-written fakes (no mocking package unless the plan adds one). Not `mocktail`, `alchemist` or `patrol_finders`. Test paths mirror `lib/`: `test/features/<name>/<file>_test.dart`.
- **Generated code:** only for features not migrated yet. After changing a freezed class, an `@injectable` class or a `@module`, run `fvm dart run build_runner build`. Generated files are git-ignored. New and migrated code has none.
- **Dependencies:** `pubspec.yaml` versions stay pinned exactly, with no `^`. Do not bump a package unasked, and never edit `basic_flutter_helper` (it is a separate repo). The package is being removed (migration step 8), so do not add new uses of it.
- **Commands:** always `fvm flutter` and `fvm dart`, never bare `flutter` or `dart`.
- **Personal repo (`alexaniko88`):** nothing from any employer in code, comments, commit messages or generated files. No `/Users/<name>/...` paths, no company names or emails.
- **Git:** agents never stage, commit, push or create branches. Only you, after the Stage 5 approval.

Briefs: ask each agent for a short report (about 300 words, findings first, no file dumps). Run independent agents in parallel in one message. Model and effort of the named agents come from their own frontmatter, so do not override them. Do not use `agent-terminal-app-solution-impl` or `agent-test`: both are built to ask before every edit and to read test rules written for another codebase.

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

Dispatch one general-purpose agent with `model: sonnet`. Put in the brief: the approved plan, the decisions, the step list, the project overrides, and these rules:

- Do all the steps in order, without waiting for approval between them. The user approved the plan already.
- Scope is exactly the plan: no bonus refactors, no unrelated cleanup, no extra tests or docs. Mention an unrelated issue in one line at the end.
- Comments: one or two short plain sentences explaining why, only where the code is not obvious. Match the density of the surrounding code.
- Run `build_runner` after a step that changes generated-code inputs. Run `fvm dart format` and `fvm flutter analyze` on the touched files by literal path, and fix what they report.
- **Stop only on a design surprise** that breaks the approved plan (a wrong assumption, a conflict between steps). Return 2 short options with a recommendation and the work done so far. Do not guess.
- Final report: files touched, what changed and why in a few bullets, the analyze result, and every `TODO` or `FIXME` added.

When the agent reports a surprise, decide it yourself if the answer is clear from the code and tell the user in one line afterwards. Ask the user only when the choice changes the approved plan in a way they would care about.

## Stage 3: Tests

Skip this stage for pure UI or text changes with no logic, and for the MVVM migration steps (tests are out of scope there). Otherwise dispatch a general-purpose agent with `model: sonnet` (or continue the Stage 2 agent with `SendMessage`) to write tests for the changed logic only, never for untouched surrounding code. The project has almost no tests: only the old counter smoke test, which fails and is out of scope unless the user says so.

- Use the test rules in the project overrides. Read one existing test of the same kind first if there is one, and copy its structure.
- If a test needs infrastructure that does not exist yet (a first fake or test helper), build the smallest version the plan's tests need and say so in the report. Do not add anything else.
- Run only the tests it wrote or touched, by file path: `fvm flutter test <path>`. Fix failures that come from the test. If a failure shows a real bug in the code, stop and report it instead of patching production code silently.

## Stage 4: Review

- Dispatch `agent-pr-review` on the diff against `master` (`git diff master` for uncommitted work), with the project overrides in the brief so it does not flag Bloc, hardcoded strings or the missing style guide. For UI changes, optionally `agent-flutter-a11y-agent` in parallel.
- **Fix Critical and General findings** with the Stage 2 agent, without asking, then re-run the Stage 3 tests and `flutter analyze`. Do at most 2 review-and-fix rounds. If Critical findings remain after the second round, stop and show them to the user. Minor findings are not fixed unless trivial; list them in the summary.
- Suggest the built-in `/code-review` for a second pass only when the change is large or risky. Do not run it unasked.

## Stage 5: Hand-off 🛑

Run the checks that apply and show the result:

- `fvm dart run build_runner build` ran after any freezed, injectable or module change (not-yet-migrated features only).
- `fvm flutter analyze` reports no issues, and the new or touched tests pass.
- If `android/`, `ios/` or `pubspec.yaml` changed: `fvm flutter build apk --debug` (and `fvm flutter build ios --debug --no-codesign` when `ios/` changed) succeeds.
- No local absolute path in the diff (`git diff | grep -n "/Users/"` returns nothing), and no company name or work email address when you read it.
- List every `TODO` or `FIXME` the diff adds, with `file:line`.

Then give a short summary of what was done and which decisions changed on the way. Draft the commit: a message in the format of `.claude/rules/git-commits.md` (`<type>: <description>`, such as `feat: add workout templates page`), the `Co-Authored-By` trailer, and the exact list of files. Show it and wait for approval. After approval, check that `git config user.email` is the repo-local noreply address, then commit. Never push without a separate explicit approval.
