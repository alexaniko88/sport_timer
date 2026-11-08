---
id: PLD-04-04
status: draft
type: feat
complexity: medium
executor: orchestrator
depends-on: [PLD-04-03, PLD-03-05]
touches:
  - tool/plan_dispatcher/src/plan_dispatcher/updates.py
  - tool/plan_dispatcher/src/plan_dispatcher/install.py
  - tool/plan_dispatcher/src/plan_dispatcher/cli.py
  - tool/plan_dispatcher/README.md
  - tool/plan_dispatcher/tests/test_update.py
  - tool/plan_dispatcher/tests/support.py
skills: []
---

# Update managed workflows transactionally

Story: [Portable workflows and project installation](../index.md)

Epic: [PlanDispatcher](../../../index.md)

## Goal

Add `pd update`, which moves an installed project to an explicitly named source version in one transaction. Managed skills, the `[distribution]` table, the artifact and the runtime change together or not at all, and blocked tasks keep working.

## Context

- Shared shapes (not restated here): [contracts](../../../contracts.md) headings "Installer and update" (flags, result, codes, journal, blocked-run and old-wheel rules), "Local state and reservations" (`list_runs` states), "Configuration schema 1".
- Prerequisites: [PLD-04-03](../03-project-installation/index.md) (`sources.materialize`, `install.stage/commit/rollback/rewrite_tables`, `ownership.diff`), [PLD-03-05](../../03-cli-execution/05-task-lifecycle/index.md) (run records with `active_stage`). From PLD-01-02: `config.SCHEMA_VERSION`; `PdError` takes any code string, so no `errors.py` change is needed.
- Requirements: R3, R13.

## Contract

Command forms, result and codes are in contracts "Installer and update". Private to this task:

- **Root.** `--root PATH`, default the Git top level of the current directory; cwd not inside a Git work tree → `not_a_repo` (exit 2).
- **Order of checks** (all before any write, exit 2): source materialized and checked (`source_mismatch`); `to_version` from the new tree's `pyproject.toml` (PLD-04-03 version rule); `runs_active` when `list_runs` reports any run with state `active` (an `interrupted` or `blocked` run does not block); `incompatible` when the new tree's `src/plan_dispatcher/config.py` line matching `^SCHEMA_VERSION = (\d+)$` (read as text, not imported) differs from the `schema` value in `config.toml`; `ownership_conflict` from `ownership.diff` (same rules as install, listing every path). Same `content_digest` (and, for git, same `source_commit`) as installed → `unchanged`, no writes; when `[distribution] content_digest` is `sha256:pending`, compare with `artifact.json` `content_digest`. A new version string is not needed: a same-version build with a different digest updates normally, because wheel folders are keyed by version and digest.
- **Tools** come from `config.toml` `[integrations] tools` and are kept.
- **New managed set** = the `install.stage` output for the new tree with the kept tools. `install.commit` (PLD-04-03) deletes `removed` files and links and their empty parent folders; an `edited` one is `ownership_conflict`. This task adds no removal code.
- **Journal** `.plan-dispatcher/local/update-journal.json` = `{schema: 1, from_version, to_version, from_digest, to_digest, staging_dir, phase}`, written atomically on every phase change. Phases, entered in order:
  - `backup`: the journal is created (nothing else moves yet).
  - `stage`: `install.stage` builds the new set and the new config text (`[distribution]` rewritten with `install.rewrite_tables`; the `needs_setup` marker line, if present, is kept).
  - `replace`, `venv`, `manifest`: entered through `install.commit(staging, phase_hook=…)`, whose hook updates the journal. The only backup is `install.commit`'s `staging/backup/` (it already holds `config.toml`, `managed.json`, `artifact.json`, `.gitignore`, the changed and removed files and the old venv).
  - `done`: the journal is deleted with the staging folder.
  - Any exception rolls back with `install.rollback(staging)` and then deletes the journal. The new wheel folder `artifacts/<to_version>-<to_digest12>/` is removed by that rollback and can never be an old run's folder.
- **Recovery.** `install.recover_interrupted_update(root) -> Optional[str]` (new here): a journal whose phase is not `done` → `install.rollback(<staging_dir>)` (a no-op for items not yet moved), return the warning `rolled back interrupted update to <from_version>`; phase `done` → delete journal and backup, return None. It runs at the start of `pd update`, `pd install` and `pd restore`.
- **Journal guard** in `cli.main`: when `<root>/.plan-dispatcher/local/update-journal.json` exists, every command except `update`, `install`, `restore`, `status`, `--help` and `--version` fails with `update_incomplete` (exit 2) telling the user to run `pd update` or `pd restore`. `root` is the Git top level of the current directory; when cwd is not in a Git work tree the guard is skipped (commands that need a root then fail on their own). Task clones have no journal, so worker `pd check` calls are unaffected.
- **Old wheels.** Update never deletes anything under an old `artifacts/<version>-<digest12>/` folder and never touches clones; PLD-03-06's `pd cleanup` deletes unreferenced wheels.
- **Fault injection (tests only).** `update_project(root, source, runner, _fault=None)`; `_fault(phase)` is called on entering `backup` and `stage` directly, and on entering `replace`, `venv` and `manifest` from inside the `phase_hook` it passes to `install.commit`. Raising `Exception` exercises rollback; raising `tests.support.SimulatedCrash` (a `BaseException` subclass) skips rollback and leaves the journal, simulating a killed process.

## Behavior

- Backlog, `host.json`, reservations and run state are never touched.
- No authentication, global setting or permission changes.
- Planner and dispatcher commands never call update.

## Decisions

- Only a live stage blocks an update; blocked runs are safe because each clone has its own venv and wheel.
- Roll back, never roll forward, after an interrupted update.

## Out of scope

- Config schema migrations (none in schema 1), deleting old wheels (PLD-03-06), removal logic (PLD-04-03 `install.commit`), the release itself (PLD-06-01).

## Files and checks

- New: `updates.py`, `tests/test_update.py`. Changed: `install.py` (`recover_interrupted_update`, called from install and restore), `cli.py` (`pd update`, journal guard), `README.md` (update section), `tests/support.py` (`SimulatedCrash`, `fail_at(phase, exc=Exception)` returning a `_fault` callable, `make_live_run(state_dir)` writing a `run.json` whose `active_stage` has `os.getpid()` and `socket.gethostname()`, `make_blocked_run(state_dir, clone_dir)`, and `make_release_tree(base: Path, version: str, changes: dict) -> Path`, which copies the real package tree `tool/plan_dispatcher/` (found from `Path(__file__).resolve().parents[1]`) into `base`, rewrites the `pyproject.toml` version line to `version`, and applies `changes` = `{repo-relative path in the tree: new text, or None to delete}`. `fake_venv_runner` (PLD-04-03) makes `bin/pd --version` print the version from the wheel file name it was given).
- `test_update.py` uses `fake_venv_runner` and `make_bare_source` from PLD-04-03. Cases: `test_local_to_local_new_version`, `test_git_tag_update`, `test_same_digest_unchanged`, `test_same_version_new_digest_updates` (two wheel folders coexist), `test_pending_digest_compared_with_artifact`, `test_not_a_repo`, `test_no_source_usage_64`, `test_tag_commit_mismatch`, `test_edited_managed_conflict_no_writes`, `test_unowned_new_path_conflict_no_writes`, `test_removed_file_deleted_when_unedited`, `test_removed_file_edited_conflict`, `test_schema_change_incompatible`, `test_live_stage_runs_active`, `test_interrupted_run_does_not_block`, `test_blocked_run_keeps_clone_and_old_wheel` (asserts the clone venv folder and the old `artifacts/<version>-<digest12>/` folder still exist), `test_rollback_at_each_phase` (for each of `backup`, `stage`, `replace`, `venv`, `manifest`: every backed-up path is byte-identical to before, `pd --version` of the venv prints the old version, the new wheel folder and the journal are gone), `test_crash_then_recover_by_update`, `test_crash_then_recover_by_restore`, `test_crash_blocks_next_with_update_incomplete`, `test_other_tables_and_backlog_unchanged`.
- Commands, from the repository root:
  - `python3 tool/plan_dispatcher/tests/run_tests.py test_update test_install`
  - `fvm dart tool/agent_check.dart --skip-build`
  - `fvm flutter test`

## Acceptance

- [ ] When `pd update` runs without a source, then it exits 64 and nothing changes. Check: `test_no_source_usage_64`.
- [ ] When an update succeeds, then managed files, `[distribution]`, `managed.json`, the artifact and the venv show the new version, removed unedited files are gone, and other config tables and the backlog are unchanged. Check: `test_update` success and removal cases.
- [ ] When an update fails at any phase, or a crashed update is found later, then the previous installation is restored exactly and other commands refuse with `update_incomplete` until recovery. Check: `test_rollback_at_each_phase`, crash cases.
- [ ] When a run has a live stage, then update refuses before writing; when runs are only blocked or interrupted, then update succeeds and blocked clones keep their runtime and old wheel. Check: `test_update` run-state cases.
