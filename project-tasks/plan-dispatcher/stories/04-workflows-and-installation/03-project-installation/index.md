---
id: PLD-04-03
status: draft
type: feat
complexity: medium
executor: orchestrator
depends-on: [PLD-03-01, PLD-04-01, PLD-04-02]
touches:
  - tool/plan_dispatcher/install.py
  - tool/plan_dispatcher/src/plan_dispatcher/install.py
  - tool/plan_dispatcher/src/plan_dispatcher/sources.py
  - tool/plan_dispatcher/src/plan_dispatcher/ownership.py
  - tool/plan_dispatcher/src/plan_dispatcher/cli.py
  - tool/plan_dispatcher/README.md
  - tool/plan_dispatcher/tests/test_install.py
  - tool/plan_dispatcher/tests/test_release_install.py
  - tool/plan_dispatcher/tests/support.py
skills: []
---

# Install project-local workflows and restore pinned runtimes

Story: [Portable workflows and project installation](../index.md)

Epic: [PlanDispatcher](../../../index.md)

## Goal

Give any project one setup command that installs the planner and dispatcher skills, the configuration and a project-local runtime, and a restore command that rebuilds the ignored runtime on a fresh clone from the pinned source. Nothing global is changed. Sport Timer's live skills are not touched here; PLD-05-01 runs this installer on Sport Timer.

## Context

- Shared shapes (not restated here): [contracts](../../../contracts.md) headings "Installer and update", "Installation and runtime", "Package layout", "Configuration schema 1", "Workspace, runtime and doctor" (artifact manifest, `content_digest`, `parse_github_repo`).
- Prerequisites: [PLD-03-01](../../03-cli-execution/01-prepare-workspaces/index.md) (`runtime.content_digest`, `prepare_runtime`, `parse_github_repo`), [PLD-04-01](../01-portable-planner/index.md) and [PLD-04-02](../02-portable-dispatcher/index.md) (skill assets). From PLD-01-02: `wheel.build_wheel`, `config.load_config` (including the `needs_setup` marker rule), the tomllib/tomli import in `config.py`, and the package-root `install.py` stub.
- Requirements: R1, R2, R3, R7.

## Contract

Command forms, the source shape, result shapes, codes and the manifest are in contracts "Installer and update". Private to this task:

- **Root.** `--root PATH`, default the Git top level of the current directory. Not a Git work tree root → `not_a_repo`.
- **Bootstrap entry** `python3 tool/plan_dispatcher/install.py install|restore …`: checks prerequisites before any package import, puts its own `src/` on `sys.path`, then calls `plan_dispatcher.cli.main(["install"|"restore", …])`. After install, `.plan-dispatcher/venv/bin/pd install|restore` take the same flags. The venv `pd` is the launcher; install prints it; no wrapper script.
- **Prerequisites** (exit 2, nothing written): `sys.platform == "darwin"` else `unsupported_os`; Python ≥ 3.9 else `unsupported_python` (message names the found version); `git` on `PATH` else `git_missing`. Missing `gh` adds a warning only.
- **Sources** (`sources.materialize`):
  - local: `path` relative to the root; copy to `work_dir` exactly the files `git -C <root>/<path> ls-files -z -- .` lists (untracked files never travel), then `git init` + commit the copy in `work_dir` so the digest can be computed the same way; `source_commit = ""`.
  - git: `git clone --no-checkout <url> <work_dir>`, `git -C <work_dir> rev-parse "<ref>^{commit}"` must equal `commit`, then `git -C <work_dir> checkout --detach <commit>`; mismatch → `source_mismatch`. Tests use a local bare repository, never the network.
  - Digest: `runtime.content_digest(<root>/<path>, runner)` for a local source and `runtime.content_digest(work_dir, runner)` for a git source (PLD-03-01, Git-tracked files only); doctor and update use the same function, so the three always agree.
  - Version: the `version = "..."` line of the materialized tree's `pyproject.toml`, read as text (regex `^version = "([^"]+)"$`); missing → `source_mismatch` with the message `pyproject.toml has no version`.
- **Config values when no config exists.** `[project]`: `name` = root folder name, `backlog = "docs/tasks"`, `remote = "origin"`, `base_branch = "auto"`, `github_repo = parse_github_repo(git remote get-url origin)`; no origin or a non-GitHub URL → `PdError("github_remote_missing", exit 2)`. `[distribution]` from the materialized source; `[integrations] tools` from `--tools`. An unconfirmed config (no proposal) also gets these defaults so it is valid apart from the marker: `[instructions] paths = []`, `[validation]` with empty `file_sets`, `checks`, `scans` and `default_skipped_groups`, `[policy] commit_subject_pattern = "^.+$"` (all other policy keys default), `[models] candidates = []`, no `[[setup.commands]]`. A proposal that omits a table gets the same default for it. When a config exists, every table except `[distribution]` and `[integrations]` is kept byte-for-byte, and those two tables are rewritten in place by `install.rewrite_tables(text, tables) -> str`, which replaces the lines from each `[name]` header up to the next header (new tables are appended at the end).
- **Proposal mapping** (`--proposal PATH`, JSON): `setup` → `[[setup.commands]]`, `validation` → `[validation]` with `file_sets`, `checks`, `scans`, `default_skipped_groups`, `policy` → `[policy]` (including `caches`), `models` → `[[models.candidates]]`, `instructions` → `[instructions] paths`. The full config text is built, then validated with `config.load_config` on a staged copy before anything moves.
- **Confirmation states.**
  - No `--proposal`, no existing config: writes skills, links, venv, `managed.json` and a config whose first line is `# needs_setup: commands not confirmed` and whose `[validation]` has no checks; writes `.plan-dispatcher/local/proposal.json` = `{evidence: [paths], template: <proposal shape with empty lists>}`. Evidence = the existing files among `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `README.md`, `.github/workflows/*`, `package.json`, `pyproject.toml`, `pubspec.yaml`, `Cargo.toml`, `go.mod`, `Makefile`. Status `needs_setup`. No discovered command is run.
  - `--proposal PATH --confirm`, allowed only when there is no config or the config still has the marker: builds every table except `[distribution]` and `[integrations]` from the proposal (replacing the marker config's other tables) and writes the config without the marker. Status `installed`. A confirmed config (no marker) plus `--proposal` → `usage` (exit 64), because the project owns that config.
  - `--confirm` alone: writes a staged copy of the existing config without the marker line and validates it with `config.load_config_file(staged)`. Valid → the marker is removed in place, status `installed`. Invalid → `config_invalid` (exit 64) naming the key, the marker is kept and nothing else is written. No marker present → `usage`.
  - `--proposal` without `--confirm` → `usage` (exit 64).
  - An existing valid config without the marker counts as confirmed.
- **Install steps** (all-or-nothing):
  1. Prerequisites; recover an interrupted update (`recover_interrupted_update`, PLD-04-04, called once that task merges; until then no journal can exist).
  2. Materialize source; build the wheel into `.plan-dispatcher/local/staging/artifacts/<version>-<first 12 hex of content_digest>/`.
  3. `install.stage(root, tree, tools, config_text) -> Staging` builds in `.plan-dispatcher/local/staging/`: both skill trees, `.claude/skills/skill-planner -> ../../.agents/skills/skill-planner` and `.claude/skills/skill-dispatcher -> ../../.agents/skills/skill-dispatcher` when `claude` is selected, the config, and the new `managed.json`.
  4. Ownership: `ownership.diff(root, staged_entries) -> {added, changed, removed, edited, unowned, foreign_links, escapes}`, each a sorted list of repo-relative paths. `staged_entries` = `{files: {path: sha256}, links: {path: target}}` of the new managed set; `managed.json` is the old set (empty when absent). For each path:
     - `added`: in the new set, not in the old set, and nothing exists at the path (no file, folder or link).
     - `changed`: in both sets, on disk with exactly the old digest (or the old link target), and the new digest or target differs.
     - `removed`: in the old set, not in the new set, and on disk with exactly the old digest or target.
     - `edited`: in the old set, and on disk with a different digest or target, or missing from disk.
     - `unowned`: in the new set, not in the old set, and something already exists at the path.
     - `foreign_links`: an `unowned` path that is a symlink (also listed in `unowned`).
     - `escapes`: any new-set path whose parent folder resolves (`os.path.realpath`) outside the root, or any new link whose target resolves outside the root.
     Any `edited`, `unowned`, `foreign_links` or `escapes` → `ownership_conflict` listing every path; staging deleted; nothing written. `config.toml` and `.gitignore` are never managed entries (the project owns them).
  5. `install.commit(staging, phase_hook=None)`: the single backup mechanism, also used by PLD-04-04. It calls `phase_hook(name)` (when given) on entering each of its three phases:
     - `replace`: copies `config.toml`, `managed.json`, `artifact.json` and `.gitignore` (those that exist) into `.plan-dispatcher/local/staging/backup/`; moves each `changed` and `removed` target there too; renames the staged files and links into place; deletes the `removed` paths and then their empty parent folders up to (not including) the skill root `.agents/skills/<skill>/`; writes the config text; appends missing `.gitignore` lines.
     - `venv`: moves the old venv (if any) to `staging/backup/venv`, creates the new venv at `.plan-dispatcher/venv` with `prepare_runtime` logic, and moves the wheel to `.plan-dispatcher/local/artifacts/<version>-<digest12>/`.
     - `manifest`: writes `artifact.json` (with an absolute `wheel_path`) and then `managed.json` last.
     Venvs are never renamed to a different path (their scripts hold absolute paths); the old one only moves aside and back.
  6. Any failure in step 5 → `install.rollback(staging)` moves every backed-up item back to its original path, removes new items (including the new `artifacts/<version>-<digest12>/` folder, which can never be an old run's folder because its name includes the new digest), and deletes staging. Success deletes staging.
  - `unchanged` is judged by `content_digest` (contracts "Installer and update").
  - Same source digest, same tools and no config change → `unchanged`, no writes. A confirmation that only changes the config → `installed`.
  - Fewer tools: a `.claude/skills/...` link is removed only when it is in `managed.json`. The `.agents/skills` trees always stay (Codex and Antigravity read them).
  - `--tools` default `claude,codex,antigravity`; an unknown name → `usage`.
- **Restore** (`install.py restore` or `pd restore`): takes only `[--root PATH]`; any `--source`, `--path`, `--url`, `--ref`, `--commit`, `--tools`, `--proposal` or `--confirm` flag → `usage` (exit 64). It reads `[distribution]` with the tomllib/tomli import from `config.py` (other tables are not validated, so a config with the marker still restores). Missing config → `needs_setup`. Materializes the source, compares `content_digest` (mismatch → `source_mismatch`, nothing written). If `artifact.json` already records the same version and wheel SHA256 and the venv's `pd --version` prints that version → `unchanged`. Otherwise builds the wheel and recreates the venv (old venv moved aside and restored on failure). Never changes tracked files.
- **Helpers used by PLD-04-04**: `install.stage`, `install.commit`, `install.rollback`, `install.rewrite_tables`, `ownership.diff`, `ownership.load`, `ownership.write`.

## Behavior

- Never edits global settings, installs providers or Python, or writes secrets into tracked files.
- Never touches the backlog folder or unrelated skills under `.agents/skills/` and `.claude/skills/`.

## Decisions

- One confirmation step owned by whichever skill runs first; Python validates and saves it.
- The config is project-owned, not a managed file, so user edits never cause conflicts.
- No wrapper launcher: the venv `pd` path is the launcher.
- `install.commit` owns the only backup and removal logic, so install and update cannot drift; update only adds a journal through `phase_hook`.

## Out of scope

- Updates between versions (PLD-04-04), running the installer on Sport Timer (PLD-05-01), extraction (PLD-06-01).

## Files and checks

- New: `src/plan_dispatcher/install.py`, `sources.py`, `ownership.py`, `tests/test_install.py`, `tests/test_release_install.py`. Changed: package-root `install.py` (stub replaced), `cli.py` (`pd install`, `pd restore`), `README.md` (setup, restore, subset, confirmation), `tests/support.py`: `make_consumer(tmp) -> Path` (`make_git_repo` plus `AGENTS.md`, with `origin` set to `https://github.com/example/consumer.git`; install never fetches, so no network is used), `make_bare_source(tmp, tree, tag) -> (url, commit)` (a local bare repo with one tagged commit of a package tree), and `fake_venv_runner()` (a `FakeRunner` that answers `python -m venv` and `pip install` by creating `bin/pd` printing the version).
- `test_install.py` uses `fake_venv_runner` (fast, no ensurepip). Cases: `test_local_digest_ignores_untracked_files` (an untracked `dist/` and `__pycache__/` in the source folder neither change the digest nor get copied), `test_restore_rejects_source_flags` (each source flag with `restore` → `usage`), `test_default_three_tools`, `test_subset_without_claude_links`, `test_links_are_relative`, `test_gitignore_lines_added_once`, `test_evidence_only_needs_setup` (no non-Git command except the fake venv calls), `test_proposal_confirm_writes_valid_config`, `test_confirm_alone_removes_marker`, `test_proposal_without_confirm_usage`, `test_proposal_on_confirmed_config_usage`, `test_proposal_replaces_marker_config_tables`, `test_confirm_alone_invalid_keeps_marker` (exit 64 `config_invalid`), `test_unconfirmed_config_defaults_valid_without_marker`, `test_version_from_pyproject`, `test_diff_classification` (one case per `ownership.diff` key), `test_commit_phase_hook_order` (`replace`, `venv`, `manifest`), `test_unconfirmed_config_refused_by_load_config`, `test_second_run_unchanged`, `test_existing_config_tables_kept`, `test_conflict_unowned`, `test_conflict_edited`, `test_conflict_foreign_link`, `test_conflict_escape` (each lists the path and leaves the tree byte-identical), `test_venv_failure_rolls_back`, `test_subset_reinstall_removes_owned_links_only`, `test_unsupported_os`, `test_unsupported_python`, `test_git_missing`, `test_github_remote_missing`, `test_unrelated_skills_and_backlog_unchanged`.
- `test_release_install.py` uses the real `SubprocessRunner` (real offline venv): `test_local_install_then_restore_in_fresh_clone`, `test_git_source_restore`, `test_restore_unchanged_when_current`, `test_restore_with_marker_config`, `test_restore_rejects_source_flags`, `test_tampered_tree_source_mismatch`, `test_wrong_commit_source_mismatch`, `test_backlog_byte_identical`.
- Commands, from the repository root:
  - `python3 tool/plan_dispatcher/tests/run_tests.py test_install test_release_install`
  - `fvm dart tool/agent_check.dart --skip-build`
  - `fvm flutter test`

## Acceptance

- [ ] When install runs with defaults or a `--tools` subset, then only the selected integrations are created, links are relative, `.gitignore` gets the two lines once, and unrelated skills, the backlog and existing config tables are unchanged. Check: `test_install` default, subset and preservation cases.
- [ ] When commands are not confirmed, then install returns `needs_setup` without running any discovered command, and `load_config` refuses until `--proposal --confirm` or `--confirm` confirms a valid config. Check: `test_install` confirmation cases.
- [ ] When any ownership conflict exists or the venv cannot be built, then the tree is left exactly as before and every conflicting path is listed. Check: `test_install` conflict and rollback cases.
- [ ] When a fresh clone restores, then the pinned source is rebuilt into a real venv, a current install is `unchanged`, and a digest or commit mismatch fails without writes. Check: `test_release_install`.
