---
id: IMP-08
status: draft
type: improve
complexity: medium
depends-on: []
touches:
  - pubspec.yaml
  - pubspec.lock
  - planner_dispatcher.yaml
  - .agents/planner-dispatcher/**
  - .agents/skills/skill-dispatcher/**
  - .agents/skills/skill-planner/**
  - .agents/rules/project-tasks-format.md
  - tool/dispatcher.dart
  - tool/dispatcher/**
  - tool/sync_master.dart
  - test/tool/dispatcher/**
  - test/architecture/ai_setup_test.dart
  - docs/task-automation.md
  - CLAUDE.md
  - .agents/skills/skill-orchestrator/SKILL.md
  - .agents/skills/skill-project-tasks/**
skills: []
---

# Use the planner-dispatcher library

[Improvements](../index.md)

**Run this task by hand** through `.agents/skills/skill-orchestrator/SKILL.md`, not through the dispatcher: it removes the dispatcher itself, fetches a git dependency over the network and runs the new install command, which runners may not do.

**Waiting for:** the tag `v0.1.0` of `https://github.com/alexaniko88/planner-dispatcher` (created when its task PD-03-02 merges). Until it exists this task stays `draft`; a short planner pass then checks the paths below against the released files, cold-reads this task and marks it `ready`.

## Goal

Remove Sport Timer's own copy of the planner and dispatcher and use the independent `planner_dispatcher` library instead. After this change the skills come from the library, Sport Timer's own facts live in its project files, and the old Dart dispatcher code is gone.

## Context

- Current behavior: the dispatcher engine is `tool/dispatcher.dart`, `tool/dispatcher/**` and `tool/sync_master.dart`, tested in `test/tool/dispatcher/**`. The skills are `.agents/skills/skill-planner/` and `.agents/skills/skill-dispatcher/` (with Sport Timer rules in `references/project-overrides.md`). `test/architecture/ai_setup_test.dart` imports `tool/dispatcher/role_models.dart` and has `dispatcher` and `planner` groups. `docs/task-automation.md` is a build record of the old system.
- `.claude/skills/skill-planner` and `.claude/skills/skill-dispatcher` are already symlinks to `../../.agents/skills/<name>`, the same links the library's install writes.
- Library contract (from planner-dispatcher `project-tasks/core/index.md`, Shared contracts): config `planner_dispatcher.yaml` schema 1; commands `fvm dart run planner_dispatcher:dispatcher next|models|launch|status`, `planner_dispatcher:sync`, `planner_dispatcher:install`; library-owned paths `.agents/skills/skill-dispatcher/`, `.agents/skills/skill-planner/`, `.agents/rules/project-tasks-format.md`; project-owned paths `planner_dispatcher.yaml`, `.agents/planner-dispatcher/project-overrides.md` (sections `## Common`, `## Implementation`, `## Tests`, `## Review checks`), `.agents/planner-dispatcher/planner-notes.md` (sections `## Branches and pull requests`, `## UI sources`, `## Project skills`, `## Checks`, `## Coverage checks`); each role reads the config's `rules`, the shipped `runner-rules.md`, the project overrides (Common plus its stage section; Common names the per-file commands) and the format rule.
- `tool/agent_check.dart` stays: the orchestrator and pr-feedback skills use it too.

## Contract

- `pubspec.yaml` `dev_dependencies`: `planner_dispatcher` as a git dependency, `url: https://github.com/alexaniko88/planner-dispatcher.git`, `ref: v0.1.0`.
- `planner_dispatcher.yaml` (new here), with exactly the values the old code hard-coded:
  - `dart: fvm dart`, `base_branch: master`, `run_folder: sport-timer-runs`;
  - `setup: [fvm install --skip-pub-get, fvm flutter pub get, fvm flutter analyze --no-pub]`;
  - `check: [fvm dart tool/agent_check.dart --skip-build]`;
  - `allowed_commands: [fvm dart format, fvm flutter analyze, fvm flutter test, fvm flutter gen-l10n, fvm flutter pub get, fvm dart tool/agent_check.dart]`;
  - `rules: [CLAUDE.md, .agents/rules/dart-style.md, .agents/rules/git-commits.md]`;
  - `goldens_dir: test/snapshots/goldens`;
  - `commit_types: [feat, fix, refactor, chore, docs, style, perf, test, build]`;
  - `git_email_suffix: "@users.noreply.github.com"`;
  - `private_patterns: {a company email: "@vent[r]ata\\.com"}` (the bracket keeps the plain domain out of the file and out of its own scan);
  - no `models` (the library defaults equal the old table).
- `.agents/planner-dispatcher/project-overrides.md` (new here): every Sport Timer-specific bullet of the old `references/project-overrides.md` (layered architecture, state management, no style guide file, strings and ARB files, styling, format and analyze by literal path, unit tests with hand-written fakes, test paths, boundary test, snapshot goldens, integration tests are separate, review checks list), under the four agreed headings, with the per-file commands in `## Common`: `fvm dart format <path>`, `fvm flutter analyze --no-pub <path>`, `fvm flutter test <path>`, `fvm flutter gen-l10n`. Bullets the library ships in `runner-rules.md` are not repeated.
- `.agents/planner-dispatcher/planner-notes.md` (new here): branch prefixes, PR titles, commit subject and `Co-Authored-By` rule from `.agents/rules/git-commits.md` (planning commits use `docs`); UI sources from the old `skill-planner/references/mockup.md` and `ui-questions.md` (theme files in `lib/shared/presentation/theme/`, `AppSurface`, `AppButton`, goldens in `test/snapshots/goldens/` at 390 by 844, flow index `test/snapshots/README.md`, `CLAUDE.md` "Styling and theme"); project skills `skill-fl-chart` (and that `skill-integration-tests` is never listed on ordinary tasks); checks: what `tool/agent_check.dart --skip-build` selects and what it skips (debug builds), from `CLAUDE.md` Commands; coverage checks: the timer/background/audio, persistence/accounts, statistics and UI examples from the old `skill-planner/references/questions.md`.

## Behavior

1. Add the dependency, run `fvm flutter pub get`, then `fvm dart run planner_dispatcher:install`. Install replaces both skill folders and the format rule with the library's files and creates the three project files.
2. Fill the three project files as in Contract (replace the starter text).
3. Delete `tool/dispatcher.dart`, `tool/dispatcher/`, `tool/sync_master.dart`, `test/tool/dispatcher/` and `docs/task-automation.md`.
4. `test/architecture/ai_setup_test.dart`: remove the `role_models.dart` import and the `dispatcher` and `planner` groups (the library tests its own files). Add a group `planner-dispatcher`: `planner_dispatcher.yaml` exists and every `rules` entry exists; the two project files exist with their agreed `##` headings in order. Keep `documented paths` (its list still names the installed skills).
5. `CLAUDE.md`: the Commands line becomes `fvm dart run planner_dispatcher:dispatcher next   # which project task can start now (also: models, launch <ID> --tool=<tool>, status)`; the Workflow and dispatcher paragraphs say the skills come from the `planner_dispatcher` library (installed with `fvm dart run planner_dispatcher:install`, configured in `planner_dispatcher.yaml` and `.agents/planner-dispatcher/`) and must not be edited here; the AI tools setup table gets one line for the installed skills.
6. `.agents/skills/skill-orchestrator/SKILL.md` and `.agents/skills/skill-project-tasks/**`: change only links or commands that point to deleted files (for example `tool/sync_master.dart` becomes `fvm dart run planner_dispatcher:sync`).
7. Nothing else changes: `tool/agent_check.dart`, the app and `project-tasks/` stay as they are.

## Decisions

- Migration in one PR, so there is never a state without a working dispatcher.
- `skill-project-tasks` stays (only its links are kept working).
- `docs/task-automation.md` is deleted; it describes code that no longer exists here.
- Run by hand, because it fetches a dependency, runs install and replaces the tool that would run it.

## Out of scope

- Changing app code, tasks or `tool/agent_check.dart`.
- Changing the library itself (report a problem there instead).

## Files and tests

- Changed: `pubspec.yaml`, `pubspec.lock`, `test/architecture/ai_setup_test.dart`, `CLAUDE.md`, and only the pointing lines of `.agents/skills/skill-orchestrator/SKILL.md` and `.agents/skills/skill-project-tasks/**`.
- Written by install: `.agents/skills/skill-dispatcher/**`, `.agents/skills/skill-planner/**`, `.agents/rules/project-tasks-format.md`.
- New: `planner_dispatcher.yaml`, `.agents/planner-dispatcher/project-overrides.md`, `.agents/planner-dispatcher/planner-notes.md`, `.agents/planner-dispatcher/.starters/*`.
- Deleted: `tool/dispatcher.dart`, `tool/dispatcher/**`, `tool/sync_master.dart`, `test/tool/dispatcher/**`, `docs/task-automation.md`.
- Run: `fvm flutter test test/architecture/ai_setup_test.dart`, `fvm flutter analyze`, `fvm flutter test`, `fvm dart run planner_dispatcher:dispatcher next`, `fvm dart run planner_dispatcher:dispatcher models`.

## Acceptance

- [ ] When the migration is done, then `tool/dispatcher*`, `tool/sync_master.dart`, `test/tool/dispatcher/**` and `docs/task-automation.md` are gone and the skills are the library `v0.1.0` files. Check: `fvm flutter test` (includes `ai_setup_test.dart`).
- [ ] When `fvm dart run planner_dispatcher:dispatcher next` runs, then it prints Sport Timer's ready tasks from `origin/master`. Check: the command.
- [ ] When `fvm dart run planner_dispatcher:dispatcher models` runs, then it shows the same stage models as before. Check: the command.
- [ ] When `CLAUDE.md`, the orchestrator or `skill-project-tasks` name a planner or dispatcher path or command, then it exists. Check: `ai_setup_test.dart` (`documented paths`).
- [ ] When the project files are read, then they hold Sport Timer's runner rules and planner notes under the agreed headings, and the config has every `rules` file. Check: `ai_setup_test.dart` (`planner-dispatcher` group).
