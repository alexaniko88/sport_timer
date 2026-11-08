---
id: PLD-05-01
status: draft
type: feat
complexity: medium
executor: orchestrator
depends-on: [PLD-02-02, PLD-03-06, PLD-04-01, PLD-04-02, PLD-04-03, PLD-04-04]
touches:
  - .plan-dispatcher/config.toml
  - .plan-dispatcher/managed.json
  - .gitignore
  - .agents/skills/skill-planner/**
  - .agents/skills/skill-dispatcher/**
  - .agents/references/plan-dispatcher-project.md
  - .agents/rules/project-tasks-format.md
  - .agents/skills/skill-orchestrator/SKILL.md
  - .agents/skills/skill-project-tasks/SKILL.md
  - .claude/skills/skill-planner
  - .claude/skills/skill-dispatcher
  - tool/dispatcher.dart
  - tool/sync_master.dart
  - tool/dispatcher/**
  - test/tool/dispatcher/**
  - test/architecture/ai_setup_test.dart
  - docs/task-automation.md
  - CLAUDE.md
skills: []
---

# Switch Sport Timer workflows and retire the old runner atomically

Story: [Sport Timer cutover](../index.md)

Epic: [PlanDispatcher](../../../index.md)

## Goal

Replace Sport Timer's hand-written planner and dispatcher skills with the packaged ones, installed from the local package source, and delete the old Dart dispatcher, master synchronizer and their tests in the same PR. Sport Timer-specific guidance moves to one project-owned reference file that the packaged skills find through the configuration. The Dart validator `tool/agent_check.dart` stays live until PLD-05-03.

## Context

- Today `.agents/skills/skill-planner/` and `.agents/skills/skill-dispatcher/` are hand-written and hold Flutter, golden, locale and model guidance. `.claude/skills/skill-planner` and `.claude/skills/skill-dispatcher` are relative symlinks to them.
- `test/architecture/ai_setup_test.dart` imports `tool/dispatcher/role_models.dart` (line 11) and has a `dispatcher` group (role files, `RoleModels.table` names in SKILL.md) and a `planner` group (cold-reader role, fixed planner model names, links). The `skills` group requires a `.claude/skills/<name>` link for every `.agents/skills/<name>` folder. The `agent roles` group and `_modelPairs` cover the orchestrator roles and `.codex/agents/*.toml`; they stay unchanged.
- `docs/task-automation.md` only describes the old runner (`tool/dispatcher.dart`, `agent_check --skip-build`, role allowlists). Nothing else links to it.
- `.plan-dispatcher/config.toml` already exists from [PLD-02-02](../../02-shared-validation/02-sport-timer-check-parity/index.md) with the `validation` tables.
- Prerequisites: PLD-02-02 (config and parity), [PLD-03-06](../../03-cli-execution/06-publish-and-cleanup/index.md) (full lifecycle), [PLD-04-01](../../04-workflows-and-installation/01-portable-planner/index.md) and [PLD-04-02](../../04-workflows-and-installation/02-portable-dispatcher/index.md) (packaged skills), [PLD-04-03](../../04-workflows-and-installation/03-project-installation/index.md) (installer and restore), [PLD-04-04](../../04-workflows-and-installation/04-explicit-updates/index.md) (update). Read [the epic contracts](../../../contracts.md), headings "Installer and update" and "Configuration schema 1".
- `.plan-dispatcher/config.toml` from PLD-02-02 already has `[integrations]`, `[instructions]` and the nine `[[models.candidates]]` copied from `tool/dispatcher/role_models.dart`. This task keeps the candidates as they are and changes only `instructions.paths` (step 5).

## Contract

Consumed (provided by PLD-04-03, shapes in contracts "Installer and update"): the bootstrap command `python3 tool/plan_dispatcher/install.py install …`, the fresh-clone command `python3 tool/plan_dispatcher/install.py restore --root .`, the ownership manifest `.plan-dispatcher/managed.json`, the `.claude/skills/<skill>` links and the `.gitignore` lines. This task relies on two installer rules written in the contracts: an existing valid `.plan-dispatcher/config.toml` counts as the confirmed proposal and only its `[distribution]` and `[integrations]` tables are rewritten; and `config.toml` is never listed in `managed.json`, so editing other tables does not make it an "edited managed file".

Provided here (new, private to this task):

- `.agents/references/plan-dispatcher-project.md`: project-owned Sport Timer guidance for planner, worker and reviewer, with these sections in order: `## Implementation`, `## Tests`, `## Review checks`, `## UI planning`, `## Task splitting and checks`. Content comes only from the inventory below. Copy each listed bullet or paragraph verbatim from the old file, changing only mentions of removed tools (`tool/agent_check.dart` → `pd check`, a runner allowlist or `tool/dispatcher.dart` → removed sentence). Do not summarize. It never mentions `tool/dispatcher.dart` or a runner allowlist; it may mention `pd check` and config check ids.
- `.plan-dispatcher/config.toml`: `instructions.paths` becomes exactly `["CLAUDE.md", ".agents/rules/dart-style.md", ".agents/rules/git-commits.md", ".agents/references/plan-dispatcher-project.md"]` (the pointer file `.agents/rules/project-tasks-format.md` is removed from the list, because the packaged planner reads its own `references/task-format.md`). No other table changes in this step; `[distribution]` and `[integrations]` are written by the installer.
- `.agents/rules/project-tasks-format.md` becomes a thin project-owned pointer. It keeps its `paths:` front matter unchanged, followed by exactly this body:

  ```markdown
  # Project tasks format

  The task format (layout and archiving into `done/`, IDs, task front matter and sections, the ready checklist, overlap and deduced state) lives in the installed asset `[task-format.md](../skills/skill-planner/references/task-format.md)` (written verbatim into the pointer file; shown as code here because the target exists only after installation). Sport Timer's backlog root is `project.backlog` in `.plan-dispatcher/config.toml`.
  ```

- That packaged `task-format.md` (PLD-04-01) is the single source for every section this rule file holds today: layout and archiving, IDs, front matter and sections, the ready checklist, shared agreements, overlap and state deduction. `skill-project-tasks` and `skill-orchestrator` are not edited: they keep linking to `.agents/rules/project-tasks-format.md` and reach those rules through the pointer. Before writing the pointer, check that the installed `task-format.md` has a heading for each of those sections; if one is missing, stop and record it under `## Blocked` in `notes.md` (it is a PLD-04-01 gap, not something to add here).

### Inventory of old content

| Old location | What is Sport Timer-specific | New location |
| --- | --- | --- |
| `skill-dispatcher/SKILL.md` | model table, legacy launch commands, `sync_master` step | model table → config `models.candidates`; the rest is dropped (replaced by the packaged dispatcher) |
| `skill-dispatcher/references/project-overrides.md` § Common | layered architecture, MVVM, no style guide file, scope, fixed contract, unwired blocks | reference `## Implementation` |
| same § Common | git limits, minimal tools allowlist, one command per check, no `python3`/`sed` edits, no runtime validation | dropped: the engine owns git and the adapter profiles own permissions (contracts "Stage protocol") |
| same § Implementation | layers, extensions, styling, strings (gen-l10n), format/analyze on touched files, comments | reference `## Implementation` |
| same § Tests | test rules, goldens, fakes | reference `## Tests` |
| same § Review checks | layer-boundary and style review points | reference `## Review checks` |
| `skill-dispatcher/roles/{implementer,tests,reviewer}.md` | Dart/Flutter specifics inside generic role text | reference sections above; the role files are dropped (packaged worker/reviewer prompts replace them) |
| `skill-planner/SKILL.md` | planner model table, `fvm dart tool/sync_master.dart`, Flutter golden reads | models → config `planner-review` candidates; sync is dropped (D46); golden reads → reference `## UI planning` |
| `skill-planner/references/ui-questions.md`, `mockup.md` | goldens, `test/snapshots/README.md`, locales, theme | reference `## UI planning` |
| `skill-planner/references/task-splitting.md`, `templates.md` | `agent_check --skip-build`, `lib/l10n/**` touches, golden file listing | reference `## Task splitting and checks` (using `pd check` and config check ids) |
| `skill-planner/references/questions.md`, `roles/cold-reader.md`, `roles/interview-reviewer.md` | reads of `CLAUDE.md`, `dart-style.md`, `project-overrides.md` | config `instructions.paths`; the files are dropped (packaged versions replace them) |
| `docs/task-automation.md` | the whole file describes the old runner | deleted; `CLAUDE.md` "Workflow" points to the installed skills |

## Behavior

Do these in order in one change:

1. Check that `git status -sb` is clean apart from this task, and that no legacy runner is running (`pgrep -f tool/dispatcher.dart` prints nothing). If one is, stop and report; do not kill it.
2. Write `.agents/references/plan-dispatcher-project.md` from the inventory.
3. `git rm -r .agents/skills/skill-planner .agents/skills/skill-dispatcher` and `git rm .claude/skills/skill-planner .claude/skills/skill-dispatcher`. Deleting them first is the scoped migration: the installer's normal collision protection is not weakened and no installer flag is added.
4. Run the installer (first literal command below). It writes the packaged skills, the Claude links, `.plan-dispatcher/managed.json`, the `.gitignore` lines, the local runtime and artifact, and rewrites `[distribution]` (real `content_digest` instead of `sha256:pending`) and `[integrations]`. An `ownership_conflict` here means step 3 missed a path: stop and report the listed paths; never delete a path the conflict names unless it is one of the four from step 3.
5. In `.plan-dispatcher/config.toml`, set `instructions.paths` to the list above. This runs after step 4 so the installer's rewrite cannot undo it; it does not affect the second installer run (step 10), which compares only source digest and tools.
6. Make `.agents/rules/project-tasks-format.md` the pointer described above.
7. `git rm -r tool/dispatcher tool/dispatcher.dart tool/sync_master.dart test/tool/dispatcher docs/task-automation.md`.
8. Update `test/architecture/ai_setup_test.dart` (see Files and tests) and `CLAUDE.md`: in "Commands" replace the `tool/dispatcher.dart` line with `.plan-dispatcher/venv/bin/pd next` and add the fresh-clone restore command `python3 tool/plan_dispatcher/install.py restore --root .` (the venv does not exist yet on a fresh clone, so the `pd restore` form cannot be used there); in "Workflow" describe the installed planner and dispatcher, the config file and the reference file; remove the "deletes merged local branches" wording and any mention of `sync_master`. Keep every `tool/agent_check.dart` mention (PLD-05-03 owns it).
9. In `.agents/skills/skill-orchestrator/SKILL.md` and `.agents/skills/skill-project-tasks/SKILL.md`, replace any mention of the old dispatcher, `sync_master` or `project-overrides.md` with `.agents/references/plan-dispatcher-project.md`.
10. Re-run the installer with the same command: it must report `status: "unchanged"`.

The backlog root stays `project-tasks` (`project.backlog`) until PLD-05-02. No dispatcher run happens while this task runs.

## Decisions

- Delete `docs/task-automation.md` instead of rewriting it: it only documents the retired runner and nothing links to it; the installed skills and `CLAUDE.md` describe the new flow.
- Migrate by deleting the old folders before installing, so the installer keeps its normal ownership protection.
- Keep the old fixed model choices as configured candidates, so recommendations do not change on cutover.

## Out of scope

- Retiring `tool/agent_check.dart` and its tests (PLD-05-03), moving the backlog (PLD-05-02).
- Any app behavior, UI, localization, golden or global agent setting change.
- Changing the orchestrator roles, `.codex/agents/*.toml` or `_modelPairs`.

## Files and tests

Changed or created: every path in `touches`. `.plan-dispatcher/managed.json` is committed; `.plan-dispatcher/venv/` and `.plan-dispatcher/local/` stay ignored.

`test/architecture/ai_setup_test.dart` changes:

- Remove the `role_models.dart` import, the `dispatcher` group and the `planner` group test "SKILL.md names the planner model of every tool".
- Add a group `plan-dispatcher install` with these tests:
  - `.plan-dispatcher/managed.json` exists, has `schema` 1, and lists `.agents/skills/skill-planner/SKILL.md` and `.agents/skills/skill-dispatcher/SKILL.md`;
  - every file in `managed.json` `files` exists and its SHA256 (no new package: `await Process.run('shasum', ['-a', '256', path])`, the digest is the first whitespace-separated field of stdout, compared with the manifest value after removing a `sha256:` prefix if present) equals the recorded digest;
  - every entry in `managed.json` `links` is a relative symlink that resolves to its target;
  - `.agents/rules/project-tasks-format.md` mentions `.agents/skills/skill-planner/references/task-format.md` and that file exists;
  - every path in `instructions.paths` of `.plan-dispatcher/config.toml` exists (read the line with a regex, no TOML parser).
- In the `planner` group, also remove "the cold-reader role is read-only and says so" (the packaged role's content is tested by the package's own `test_planner`). Keep "every reference and role that SKILL.md links to exists" and "every file the planner files mention exists" unchanged: they check that the installed tree is complete, and PLD-04-01 keeps `references/` and `roles/cold-reader.md` in the packaged planner.
- `documented paths` stays unchanged: its `skillFiles` list still names both SKILL.md paths, which now hold the packaged files. If one of its tests fails on a packaged file, that is a package defect: stop, record it in `notes.md` under `## Blocked`, and do not edit the managed file or weaken the test.

Literal commands, from the repository root:

- `python3 tool/plan_dispatcher/install.py install --source local --path tool/plan_dispatcher --tools claude,codex,antigravity` (run twice; the second run must print `unchanged`)
- `python3 tool/plan_dispatcher/tests/run_tests.py`
- `python3 test/tool/test_plan_dispatcher_parity.py --source tool/plan_dispatcher/src`
- `.plan-dispatcher/venv/bin/pd doctor --json`
- `git grep -n -E "tool/dispatcher|sync_master|dispatcher\.dart|task-automation" -- . ':!project-tasks'` (must print nothing)
- `fvm dart format test/architecture/ai_setup_test.dart`
- `fvm flutter analyze test/architecture/ai_setup_test.dart`
- `fvm flutter test`
- `fvm dart tool/agent_check.dart --skip-build`

`pd doctor` may report missing provider auth on this machine; that is recorded, not fixed here. No app launch, device test, golden or ARB change.

## Acceptance

- [ ] When the packaged skills replace the old ones, then the old dispatcher, synchronizer, their tests, `docs/task-automation.md` and the `role_models` assertions are gone in the same PR and all remaining tests pass. Check: `fvm flutter test`, `python3 tool/plan_dispatcher/tests/run_tests.py` and the `git grep` reference scan printing nothing.
- [ ] When the installer runs a second time, then it reports `unchanged` and every managed file matches `.plan-dispatcher/managed.json`. Check: the second installer run and the `plan-dispatcher install` group in `test/architecture/ai_setup_test.dart`.
- [ ] When Sport Timer guidance is needed by the planner or a worker, then it is in `.agents/references/plan-dispatcher-project.md` (listed in `instructions.paths`) and not inside a managed skill folder. Check: the `instructions.paths` test in `ai_setup_test.dart` and `git grep -n -E "fvm|goldens|gen-l10n" -- .agents/skills/skill-planner .agents/skills/skill-dispatcher` printing nothing.
- [ ] When an existing workflow reads `.agents/rules/project-tasks-format.md`, then it points to the one packaged task-format file. Check: the pointer test in `ai_setup_test.dart`.
