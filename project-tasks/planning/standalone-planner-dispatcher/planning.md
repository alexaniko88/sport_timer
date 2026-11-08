# Planning: standalone planner and dispatcher

## Original request

"I need to extract the planner and dispatcher into a standalone library that can be used for any project as it is not."

## Evidence

- Planner skill: `.agents/skills/skill-planner/` (SKILL.md, references, roles). Dispatcher skill: `.agents/skills/skill-dispatcher/` (SKILL.md, `references/project-overrides.md`, roles implementer/tests/reviewer).
- Dispatcher engine is Dart: `tool/dispatcher.dart`, `tool/dispatcher/**` (~2,700 lines), `tool/sync_master.dart`; tests in `test/tool/dispatcher/**`. Task format rule: `.agents/rules/project-tasks-format.md`.

- Coupling found (Sport Timer specifics inside the engine): base branch `master` hard-coded (`git_publisher.dart`, `master_sync.dart`, `run_workspace.dart`, `dispatcher.dart`), setup `fvm flutter pub get` + analyze (`run_workspace.dart`), check command `fvm dart tool/agent_check.dart` (`launch_pipeline.dart`), allowed Claude commands (`tool_command.dart`), goldens folder `test/snapshots/goldens` (`git_publisher.dart`, `pr_description.dart`), role path `.agents/skills/skill-dispatcher/roles/` (`stage_runner.dart`), temp folder `sport-timer-runs` (`run_workspace.dart`), fixed models (`role_models.dart`).
- Coupling in Markdown: `skill-dispatcher/references/project-overrides.md` is fully Sport Timer; roles read `CLAUDE.md`, `.agents/rules/dart-style.md`, `git-commits.md`; planner `mockup.md`/`ui-questions.md` name Sport Timer theme files and goldens; `ai_setup_test.dart` checks skill folders and imports `role_models.dart`.
- The dispatcher only runs tasks stored in the repo it serves (loads `origin/master`, clones `origin`).

- More engine coupling: commit subject pattern with Sport Timer's types (`git_publisher.dart:6`), a private-data scan that contains the company email domain pattern (`git_publisher.dart:27`, must not go public), required `@users.noreply.github.com` email (`run_workspace.dart:39`), `Co-Authored-By` trailer and `docs: close task`/`wip:` subjects (`launch_pipeline.dart`).
- Other Sport Timer files that mention planner/dispatcher: `CLAUDE.md` (Commands, Workflow, AI tools setup), `docs/task-automation.md` (315-line build record), `.agents/skills/skill-orchestrator/SKILL.md` (task requests, archiving via skill-project-tasks), `.agents/skills/skill-project-tasks/` (older backlog skill), `test/architecture/ai_setup_test.dart`, `.codex/agents/agent-plan-reader.toml`.

## Coverage

| Ref | Area | State | Evidence / decision |
| --- | --- | --- | --- |
| C2 | Target form: repo, language | resolved | D2, D3, D9, D10, D11, D12, D16 |
| C3 | What stays project-specific vs generic | partial | Coupling list in Evidence; P1-P4 proposals not yet accepted |
| C4 | Sport Timer migration | partial | D17, D18; ordering vs release in P6 |
| C5 | Success checks | partial | P5 proposal |
| C6 | Supported project kinds | resolved | D4 |
| C7 | Install and pin | resolved | D5, D6 |
| C8 | Seed and bootstrap | resolved | D8, D13, D20 |
| C9 | Releases | resolved | D15 |
| C10 | Models per stage | resolved | D19 |
| C11 | Privacy of the public repo | resolved (fact) | Company email pattern and any local paths must never be published (user CLAUDE.md privacy rule); Sport Timer config may keep its own pattern |
| C12 | Upgrading a project to a new library version | partial | D6 (re-run install); P2 (project files never overwritten) |
| C13 | Library repo CI and own checks | partial | P5 |

## Proposals (not accepted yet)

- P1: One project config file `planner_dispatcher.yaml` at the project root (YAML, like `pubspec.yaml`): base branch, setup commands, the full check command, extra allowed runner commands, how to run Dart (`fvm dart` or `dart`), golden folder (optional), commit types and subject rules, private-data patterns, required git email suffix (optional), run folder name, model overrides (D19), and the project rule files the roles must read.
- P2: Generic files are installed at today's paths (`.agents/skills/skill-planner/`, `.agents/skills/skill-dispatcher/`, `.agents/rules/project-tasks-format.md`) plus the `.claude/skills/*` symlinks, so existing links keep working. Install fills command placeholders from the config. It overwrites only library-owned files; project-owned files (config, `project-overrides.md`, UI notes for the planner) are created once as starters and never overwritten.
- P3: Commands: `dart run planner_dispatcher:dispatcher next|models|launch|status`, `dart run planner_dispatcher:sync` (today's `sync_master`), `dart run planner_dispatcher:install`.
- P4: Planner UI parts (`mockup.md`, `ui-questions.md`) become generic; the project's theme files and goldens are named in a project-owned planner notes file.
- P5: The library repo has CI (`dart analyze`, `dart test`) and an independence test that fails when a forbidden project name/path appears in the library sources.
- P6: Sport Timer migration tasks are written now as `draft`, blocked only by the external release tag `v0.1.0`; a short planner pass marks them `ready` after the tag exists (cross-repo ids cannot be in `depends-on`).
- P7: Library backlog lives in `planner-dispatcher/project-tasks/` (same format); Sport Timer migration tasks live in Sport Timer's `project-tasks/`.

## Decisions

- D1: Start fresh. No earlier plan is used. User-chosen.
- D2: The library lives in a new, separate GitHub repo of its own, which projects install or link to. User-chosen.
- D3: Keep the engine in Dart; move the tested `tool/dispatcher` code and make it generic rather than rewrite. Consumers need the Dart SDK. Accepted recommendation (least rewrite risk).
- D4: First version targets Flutter/Dart projects only; other languages later (out of scope). User-chosen.
- D5: A project adds the library as a git `dev_dependency` in `pubspec.yaml`, pinned to a release tag, and runs it with `fvm dart run <pkg>:<command>`. Accepted recommendation (fits Dart-only scope and exact-pin rule).
- D6: An install command of the library copies the generic skill and role files into the project's `.agents/skills/`; they are committed, and re-run after a version bump. Accepted recommendation (works in fresh and runner clones).
- D7: The new repo exists from day one (seed content: see D20); making it generic happens there, with its own backlog. User-chosen (over building a package folder in Sport Timer first).
- D8: The planner (this session) creates the new GitHub repo and seeds it. User-chosen (visibility D10, license D11).
- D9: Repo `alexaniko88/planner-dispatcher`. Dart forbids hyphens in package names, so the package is `planner_dispatcher`. User-chosen name.
- D10: The repo is public. User-chosen (Sport Timer's CI can fetch it without a token).
- D11: MIT license, same as Sport Timer. Accepted recommendation.
- D12: The new repo starts with one fresh initial commit; no Sport Timer history. User-chosen.
- D13: The new repo's first task (bring the engine over in generic form, with setup, check and base branch configurable, so the dispatcher can run on its own repo) is run by hand in a normal session; after it merges, the library's own dispatcher runs the rest of its backlog. User left the choice to the planner ("whatever better fits"); chosen because the planner writes no code and the copied dispatcher cannot run there yet.
- D14: "Clean install": planner-dispatcher is an independent project. It does not depend on Sport Timer or mention its files, rules, theme or paths, and any (Flutter/Dart, per D4) project can use it by itself through the dependency and the install command. User-chosen (clarified in their words).
- D15: A GitHub Action in planner-dispatcher creates the release tag `vX.Y.Z` when a version bump in its `pubspec.yaml` merges to its default branch; a task adds that workflow. User-chosen.
- D16: The new repo's default branch is `main` (GitHub default; the base branch is configurable anyway). Planner default, routine.
- D17: Include the migration: remove everything planner/dispatcher-related from Sport Timer, which then uses planner-dispatcher as its dependency to access the planner and dispatcher. User-chosen.
- D18: `skill-project-tasks` stays in Sport Timer unchanged in purpose; only its links are kept working. User-chosen.
- D19: The library ships today's per-tool stage models as defaults; a project can override any stage in its own config file. User-chosen (option 1, after a plain explanation).
- D20: The first public commit is a working skeleton only: README, MIT `LICENSE`, `pubspec.yaml`, CI. The first task (run by hand, D13) copies the code from Sport Timer and makes it generic in the same change, so the public history never contains Sport Timer content. Accepted recommendation (fits D14). Replaces the "seeded with a copy" part of D7.
- D21: Library task files under `project-tasks/` may name the Sport Timer source paths they copy from; the independence test checks only shipped files (`lib/`, `bin/`, `.agents/`, `templates/`, `README.md`). User-chosen.
- D22: Split T1-T6 and design P1-P11 accepted by the user ("ok"), with one change: install copies files byte for byte and fills nothing in; skills read the Dart command from `planner_dispatcher.yaml`. Acceptance criteria accepted ("ok").
- D23: The library backlog lives in `alexaniko88/planner-dispatcher` `project-tasks/core/` (PD-01-01 to PD-03-02); the migration is Sport Timer task IMP-08, run by hand through the orchestrator. The user asked to mark the library tasks ready; a fourth cold-read round was run first and its findings fixed.
- D24: The independence test does not contain the company email domain (it would publish it); Sport Timer keeps its own pattern in its config (IMP-08, written as `@vent[r]ata\\.com`).

## Open questions

- IMP-08 waits for the external tag `v0.1.0` of planner-dispatcher. After it exists: check IMP-08's paths against the released files, cold-read it, mark it `ready`, then delete this record.

## Review

Interview completeness review, round 1 (fresh read-only agent, 2026-11-08): verdict incomplete. Findings and resolution:

1. D7/D20 wording and independence rule: D7 already points to D20. Proposed P8: the library's independence test forbids `sport`, `Sport Timer`, `agent_check`, the company email domain and `/Users/` in library files; the hand-run tasks open normal PRs in the new repo that the user reviews, and that test runs in them.
2. Check command contract: proposed P9: `tool/agent_check.dart` stays in Sport Timer (also used by the orchestrator and pr-feedback skills). The library only needs a configured check command that exits non-zero on failure.
3. fvm vs plain dart: covered by P1 (configured Dart command); D14 says any Flutter/Dart project.
4. Failure behavior: proposed P10: missing or invalid config stops every command with an error naming the file and field; install is safe to re-run and reports what it wrote; a changed starter is reported, never overwritten; `pub get` of the public git dependency needs no auth (D10), and an offline setup failure ends the run as `failed` like today.
5. Migration list: made explicit in the split proposal (one atomic Sport Timer PR, so there is no window without a working dispatcher).
7. Whole-goal success check: proposed P11: (a) the library dispatches its own backlog after the hand-run tasks; (b) an install test into a temporary Flutter-style fixture project; (c) after migration, Sport Timer's `next` and its full test run pass with no planner/dispatcher code left in its tree.
8. Privacy: part of P8.
9. Library's own config and overrides: part of the second hand-run task in the split.

Cold reads: PD-01-01..PD-03-02 four rounds (PD-03-02 passed in round 2; the others passed or had only small points fixed in round 4). IMP-08 not cold-read yet (blocked on the release).
