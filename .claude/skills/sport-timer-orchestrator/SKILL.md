---
name: sport-timer-orchestrator
description: >
  End-to-end workflow for a change in the Sport Timer app, from a request the user writes in their own
  words: brief, diagnosis or plan, optional estimate, grilling of open decisions, user checkpoint,
  step-by-step implementation, tests, pre-commit review and hand-off. There are no tickets. Use when the
  user says "orchestrate", "let's build", "work on this", "handle this", "run the workflow for", or
  describes a bug, feature, improvement or refactor to be done end-to-end in this repo.
  Not for read-only investigation (use the agent-bug-investigator agent directly) or for PR review comments.
argument-hint: "<what you want, in your own words>"
model: claude-opus-5-5
effort: high
---

# Sport Timer Orchestrator

You are the conductor. Read-heavy work (investigate, plan, estimate, review, test) goes to subagents so their file dumps stay out of the main chat. Code edits go to the `agent-terminal-app-solution-impl` agent (Sonnet), so the conductor and the investigation, planning and estimate agents run on Opus and the editing runs on the cheaper model. The user validates each step.

There are no tickets in this project. The user's own message is the request. Never look for a ticket, a Linear link or a ticket ID, and never call a Linear tool.

## Project context

`CLAUDE.md` is already loaded: read it for commands, architecture, generated code and pinned dependencies, and do not repeat it in briefs. Every agent brief must still carry the **project overrides** below, because the shared global rules in `~/.claude/rules/` and `~/.claude/profiles/` were written for another codebase and some of them are wrong here.

**Project overrides (they win over the global rules and profiles):**

- **State management is Bloc/Cubit** with `injectable` + `get_it` and `go_router`. The global "MVVM + `ValueNotifier`, never BLoC" rule does not apply. Follow the existing feature layout (`lib/features/<name>/`, barrel file with `part` directives).
- **Strings:** the app has no localization. Hardcode user-facing English text in the widget. Do not add `FIXME-ALEX` blocks, ARB files or `Localized` keys.
- **No `docs/CodeStyleGuide.md`** exists. The Dart style rules from `~/.claude/rules/flutter/dart-core.md` still apply (switch and pattern matching, null safety, trailing commas, format and analyze on touched files only).
- **Tests:** `bloc_test` and `mockito` (mocks generated with `build_runner`). Not `mocktail`, not `alchemist`, not `patrol_finders`. Test paths mirror `lib/`: `test/features/<name>/<file>_test.dart`.
- **Generated code:** after changing a freezed class, an `@injectable` class or a `@module`, run `fvm dart run build_runner build`. Generated files are git-ignored, so they never appear in the diff.
- **Dependencies:** versions in `pubspec.yaml` stay pinned exactly, with no `^`. Do not bump a package unasked, and never edit `basic_flutter_helper` as part of a task here (it is a separate repo).
- **Commands:** always `fvm flutter` and `fvm dart`, never bare `flutter` or `dart`.
- **Personal repo (`alexaniko88`):** nothing from any employer may appear in code, comments, commit messages or generated files. No `/Users/<name>/...` paths, no company names or emails.

**Language profiles.** The language is Flutter/Dart. Task profiles are read on demand, by exact path:

| Who | Task profile to name in the brief |
| :--- | :--- |
| Investigator, planner, implementation agent | none (the core rules are enough) |
| `agent-test` | none. Give it the test rules from the overrides above instead of `tests.md`, which is written for another codebase |
| `agent-pr-review` | `~/.claude/profiles/flutter/review.md`, ignoring its test-file, `Localized`, MVVM and `CodeStyleGuide` lines |
| `agent-ticket-estimator` | `~/.claude/profiles/flutter/review.md`, same caveat |
| `agent-flutter-a11y-agent` | none. Name the overrides above |

The hand-off profile `handoff.md` is not used: it is about another repo's CI. Stage 8 below has this project's own checks.

Model and effort for each agent are set in its own frontmatter. Do not override them when dispatching.

When briefing any agent, ask for a short report (about 300 words, findings first, no file dumps), because every report counts against this thread's context. Run independent agents in parallel in one message. The estimator needs the investigator's fix as input, so it runs after it. Run agents one after another only when the second needs the first one's result.

## Core rules

1. **Never skip a checkpoint.** Stop for explicit user confirmation after the Stage \* request brief, and for explicit approval after Stage 4 and after every implementation step.
2. **Relay, don't rewrite.** Show subagent reports as they come, without rephrasing them. Add only a short line about what comes next.
3. **Git rules** (personal repo, from the global `CLAUDE.md`): never push, and never commit without showing the message and the exact file list and getting approval first. Do not create or switch branches unasked. The history is on `master`.

## Progress and state

Keep this checklist and print the updated copy at the end of every stage report and step report. Mark skipped stages as `skipped` with the Stage 0 reason.

```
Task: <short name>
- [ ] Request brief
- [ ] Route
- [ ] Diagnose / plan
- [ ] Estimate (optional)
- [ ] Grill (optional)
- [ ] Checkpoint approved
- [ ] Implementation: step 0/N
- [ ] Tests
- [ ] Review
- [ ] Hand-off
```

A task can run across many turns, so the chat can be compressed or the session can end. Keep the state in a project memory file, `project_<short-slug>.md` (for example `project_workout_templates_storage.md`), following the memory rules:

- **On start:** look in memory for a file about this task. If one exists, show its status and continue from the next open step instead of starting over.
- **After the Stage 4 approval:** create the file with the approved plan, the settled decisions, the numbered steps and the chosen implementer. Add its pointer line to `MEMORY.md`.
- **After each approved step or stage:** update the checklist and step status in the file. Write down any decision that changed during implementation.
- **At hand-off:** mark the task as ready to commit and list what is still pending (`TODO`s added).

## Stage \*: Request brief 🛑

The request is whatever the user wrote after invoking the skill, or their last message if they gave no argument. It may be one line. Do not ask for a ticket.

Before anything else, show a brief in plain English, 5-8 lines:

- **What it is:** one sentence (bug / feature / improvement / refactor, and the area of the app: timer, settings, templates, login, statistics, audio, build setup).
- **Problem or goal:** what is wrong or what is wanted, in simple words.
- **Expected result:** what "done" looks like.
- **Unclear or missing:** anything vague (repro steps, behaviour, screens affected). Write "none" if clear.

Then stop and ask the user to confirm, or to correct it. Do not route, dispatch any agent, or read code until the user confirms. The confirmed brief is what the rest of the stages work from.

## Stage 0: Route

You decide the route. Do not run every stage by default. After the brief is confirmed, size the work and pick only the stages and agents that fit, using the stage sections below as your menu:

- **Diagnose or plan:** the investigator, the planner or the a11y agent (see Stage 1). Skip it when the request already holds a clear root cause and fix. Then verify the claim against the code yourself and go to Stage 4.
- **Estimate (Stage 2) and grilling (Stage 3):** only when the triggers there apply.
- **Implementation:** the implementation agent, by the Stage 5 rules.
- **Tests (Stage 6) and review (Stage 7):** tests whenever logic changed (cubits, repositories, timer maths). Skip them for pure UI or text changes with no logic. Review always runs before hand-off.
- **Other skills and agents:** use any available one that fits (for example `agent-flutter-a11y-agent` on UI changes). Do not use one just because it exists.

State the route in 3-4 lines with a reason for each skipped stage, then continue. The user can change it at any time. Checkpoints and the core rules always apply.

## Stage 1: Intake

Reuse the brief confirmed in Stage \*.

Before dispatching, check the request has what the agent needs: repro steps or a clear symptom for a bug, a clear expected result for a feature. If it is missing, ask the user 1-3 short questions first, each with a suggested answer. Do not pay for an investigation built on guesses.

Then pick the agent:

| Request | Agent |
| :--- | :--- |
| Bug / regression / crash | `agent-bug-investigator` |
| New feature / improvement / refactor / build setup | `agent-ticket-planner` |
| Accessibility (screen reader, semantics, focus, contrast, tap targets) | `agent-flutter-a11y-agent`, plus the investigator or planner when real logic is involved |

Pass the confirmed brief, the project overrides, any user notes and the answers to your questions. Say in the brief that there is no ticket. Both investigator and planner end their report with an **Open Decisions** list.

## Stage 2: Estimate (optional)

Run `agent-ticket-estimator` when the user asks, or when the change touches more than ~3 files or a risky area: timer countdown logic, audio playback, Firebase auth, the Android or iOS build setup, or a dependency bump. Input: the brief plus the chosen or recommended fix. Show its table next to the Stage 1 report.

## Stage 3: Grill open decisions (optional)

- **Open Decisions is "None"** (one clear fix) → skip to Stage 4.
- **Otherwise** → invoke the `grilling` skill with the Open Decisions list as the starting frontier. It asks the questions in rounds with a recommended answer each, and looks facts up itself instead of asking the user.
- The user can also start it any time with `/grill-me`.
- End with a short list of the settled decisions. That list, with the plan, is what Stage 4 approves.

## Stage 4: Checkpoint 🛑

Present the final approach: the fix or plan, the settled decisions, and the numbered implementation steps (one file or concern each, sub-numbered like 2.1, 2.2). **Do not touch code until the user approves.**

**Who implements:** always `agent-terminal-app-solution-impl`. Implement in the main session only when the user asks for it.

## Stage 5: Implementation (agent)

Dispatch `agent-terminal-app-solution-impl` with the approved plan, the settled decisions, the step list, the project overrides and the rules below. Use one agent for the whole task: resume it with `SendMessage` for every step, so it keeps the plan and the files it already read.

A subagent cannot talk to the user, so each step takes two rounds:

1. The agent returns its proposal for the current step. Relay it.
2. Once the user approves, send the approval with `SendMessage`. The agent applies the change and returns its report. Relay it and wait for the user to validate before the next step.

Rules to put in the brief, and to check in every report:

- **One step per round.** Never continue to the next step without approval.
- **Report each step:** files touched, what changed and why in a few bullets, then name the next step.
- **Stop on design surprises:** if a step shows a problem the plan missed, return 2 short options with a recommendation instead of choosing silently. Make the decision with the user in the main chat, then send it back.
- **Generated code:** run `build_runner` after a step that changes a freezed class, an injectable class or a module, and say so in the report.
- **Format and analyze** only the touched files, by literal path, as in `dart-core.md`.
- **Code rules:** the agent follows the common rules, `dart-core.md` and the project overrides. Check each report against them.

If the user asks to implement in the main session instead, follow the same rules yourself, one step per turn.

## Stage 6: Tests

The project has almost no tests: only the old counter smoke test, which fails and is not part of any task unless the user says so. The first real test therefore sets the pattern.

- Before dispatching, tell the user if the change needs test infrastructure that does not exist yet (mock generation, a first `bloc_test` file) and raise it as a decision with a recommendation. Do not build it unasked.
- Dispatch `agent-test` for the changed code only, never untouched surrounding code. A subagent cannot ask the user, so ask the test kind yourself first (unit for cubits, repositories and pure logic; widget for screens), with a recommendation, and put the answer, the target files and the project test rules in the brief.
- Run only the tests that were touched or written, by file path: `fvm flutter test <path>`.

## Stage 7: Review before commit

- **Always:** `agent-pr-review` on the diff against `master` (`git diff master` for uncommitted work), grouped Critical / General / Minor. Tell it the project overrides, so it does not flag Bloc, hardcoded strings or the missing style guide.
- **Optional:** the built-in `/code-review` for a second pass focused on correctness bugs, when the change is large or risky. Suggest it, don't run it unasked.
- **UI changes:** optionally `agent-flutter-a11y-agent` on the diff.

Fix review findings the same way as Stage 5, with the same implementation agent: one step per round, after approval. After the fixes, re-run the Stage 6 test files and show the result. Do at most 2 review-and-fix rounds. If Critical findings remain after the second round, stop and show them to the user instead of looping.

## Stage 8: Hand-off

Run the project checks that apply, and show the result:

- `fvm dart run build_runner build` ran after any freezed, injectable or module change.
- `fvm flutter analyze` reports no issues.
- The new or touched tests pass.
- If `android/`, `ios/` or `pubspec.yaml` changed: `fvm flutter build apk --debug` (and `fvm flutter build ios --debug --no-codesign` when `ios/` changed) succeeds.
- No local absolute path in the diff (`git diff | grep -n "/Users/"` returns nothing), and no company name or work email address when you read it.
- List every `TODO` or `FIXME` the diff adds, with `file:line`.

Then draft the commit: a one-line message in the style of this repo's history (a sentence starting with a verb in present tense, such as "Adds workout templates page"), the `Co-Authored-By` trailer, and the exact list of files. Show it and wait for approval. After approval you may commit. Check `git config user.email` first: it must be the repo-local noreply address. Never push without a separate explicit approval.
