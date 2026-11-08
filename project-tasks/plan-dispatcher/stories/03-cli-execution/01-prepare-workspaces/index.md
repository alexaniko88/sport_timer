---
id: PLD-03-01
status: draft
type: feat
complexity: medium
executor: orchestrator
depends-on: [PLD-01-03, PLD-02-01]
touches:
  - tool/plan_dispatcher/src/plan_dispatcher/workspace.py
  - tool/plan_dispatcher/src/plan_dispatcher/runtime.py
  - tool/plan_dispatcher/src/plan_dispatcher/preflight.py
  - tool/plan_dispatcher/src/plan_dispatcher/cli.py
  - tool/plan_dispatcher/tests/test_workspace.py
  - tool/plan_dispatcher/tests/test_preflight.py
  - tool/plan_dispatcher/tests/support.py
skills: []
---

# Prepare external workspaces, runtimes and preflight

Story: [CLI execution and reviewed publication](../index.md)

Epic: [PlanDispatcher](../../../index.md)

## Goal

Give the engine one call that prepares a task: a clean clone outside every repository at a captured base commit, the frozen run context, an offline runtime from the prepared wheel, and the approved setup commands. Add `pd doctor`, which reports every missing prerequisite before any coding starts. The user's active checkout is never changed.

## Context

- Shared contracts: [Workspace, runtime and doctor](../../../contracts.md) and [Local state and reservations](../../../contracts.md) sections. Paths below are planned outputs.
- Provided by PLD-01-02: `config.load_config`, `tasks.task_branch`, `ports.CommandRunner`/`SubprocessRunner`, `wheel.build_wheel`, `errors.PdError`, `adapters.get_adapter`, the CLI envelope, and `tests/support.py` (`make_git_repo`, `FakeRunner`).
- Provided by PLD-01-02: `gitutil.state_dir(root, runner)`.
- Provided by PLD-02-01: the `validation` part of the config that the frozen context copies.
- Reference only: `tool/dispatcher/run_workspace.dart` (today's temporary clones, with Flutter setup, `master` and noreply rules hardcoded).
- Requirements: R1, R3, R7, R8, R13.

## Contract

Cross-task shapes are owned by the contracts and are not repeated here:

- the public functions, return shapes, artifact manifest and doctor result: [Workspace, runtime and doctor](../../../contracts.md#workspace-runtime-and-doctor-pld-03-01);
- the frozen `plan.json` and the state layout: [Local state and reservations](../../../contracts.md#local-state-and-reservations-pld-01-03-pld-03-05);
- `PdError` and the CLI envelope: [Package layout](../../../contracts.md#package-layout-pld-01-02) and [CLI](../../../contracts.md#cli-pld-01-02-envelope-each-commands-owner-adds-it).

This task implements those functions in `workspace.py`, `runtime.py` and `preflight.py`, and adds `pd doctor` to `cli.py`. The private details follow.

`parse_github_repo(remote_url)`:

- `https://github.com/O/N`, `https://github.com/O/N.git`, `git@github.com:O/N(.git)` and `ssh://git@github.com/O/N(.git)` → `"O/N"`.
- An absolute local path or a `file://` URL → `"local/<last path part without .git>"`. Fixture consumers set `project.github_repo = "local/<bare folder name>"`.
- Anything else → `""`. That never equals a valid `github_repo`, so it ends as `remote_mismatch`.

`repository_key(remote_url)`: `"<N>-" + sha256(remote_url.encode()).hexdigest()[:12]`, where N is the last path part without `.git`, lowercased, with every character outside `[a-z0-9-]` replaced by `-`.

`freeze_context(root, run_id, config_path, task, base_sha, workspace, options, runner) -> Path`:

- `config_path` is the repo-relative path of the config (`.plan-dispatcher/config.toml`). The config is read with `git -C root show <base_sha>:<config_path>` and the task file with `git -C root show <base_sha>:<task["path"]>`, never from the working tree.
- Writes `context/config.toml`, `context/task.md` and `context/plan.json` under `state_dir(root, runner) / "runs" / run_id`, and returns that `context` folder.
- `plan.json` values:
  - `skip_groups` = `options.get("skip_groups")`, else `validation.default_skipped_groups` of the frozen config;
  - `include_groups` = `options.get("include_groups", [])`;
  - `allowed_scope` = the task's `touches`;
  - `caches` = the sorted union of the `needs` entries of every `validation.checks` entry, minus `"network"`;
  - `network` = whether any check lists `"network"` in `needs`;
  - `workspace` (the clone path, as a string), `base_sha` and `run_id` as given in the arguments.
- Every check of the frozen config may run, so every cache it needs is granted; nothing is filtered by diff. v1 always passes `options = {}`; the parameter exists so later launch options do not change the signature.
- A file missing at `base_sha` → `PdError("context_missing", "<path> is not in <base_sha>", exit 2)`. An existing `context` folder for this run ID → `PdError("context_exists", exit 2)`; nothing is overwritten.

`clone_at(root, config, branch, path, runner) -> dict` does steps 1-5 below and returns `{path, base_sha, base_branch, branch, git_identity: {name, email}}`. It writes no state. `config` is the active checkout's validated config; it supplies only `project.*` and `policy.required_email_suffix`.

1. `remote_url = git -C root remote get-url <project.remote>`. `parse_github_repo(remote_url)` must equal `project.github_repo`, else `PdError("remote_mismatch", "<remote> is <parsed>, config expects <github_repo>", exit 2)`.
2. Identity: `git -C root config user.name` and `git -C root config user.email` (the checkout's effective config). An empty name or email, or an email that does not end with `policy.required_email_suffix` when that is not empty, raises `identity_mismatch`.
3. `git -C root fetch <remote>`, then `b = gitutil.resolve_base(root, remote, project.base_branch, runner)` (PLD-01-03), then `base_sha = git -C root rev-parse refs/remotes/<remote>/<b>`.
4. Path rules on `path.resolve()`:
   - `path` inside `root.resolve()`, or `root.resolve()` inside `path`, raises `workspace_unsafe`. A path under the home folder is fine.
   - An existing `path` raises `workspace_collision`.
5. `git clone --no-hardlinks <remote_url> <path>`, then `git -C <path> checkout -b <branch> <base_sha>`. Append `.plan-dispatcher/venv/` and `.plan-dispatcher/local/` lines to `<path>/.git/info/exclude`. Set `user.name` and `user.email` in the clone's local config to the step 2 values.

A failure in steps 1-4 creates nothing.

`prepare_workspace(root, task, run_id, config, artifact, runner, cache_root=None)`, in this order:

1. `path = (cache_root or ~/Library/Caches/PlanDispatcher) / "workspaces" / repository_key(<remote URL from git remote get-url>) / run_id`.
2. `ws = clone_at(root, config, task_branch(task), path, runner)`.
3. `freeze_context(root, run_id, ".plan-dispatcher/config.toml", task, ws["base_sha"], str(path), {}, runner)`, then load the frozen config with `config.load_config_file`.
4. `prepare_runtime(path, artifact, runner)`.
5. Run each frozen `setup.commands` entry in order, with `cwd = path` and its own `timeout_seconds`. Stdout and stderr go to `runs/<run_id>/logs/00-setup-<id>.stdout|.stderr`.
   - Non-zero exit → `PdError("setup_failed", "<id> exited <code>; logs: <stdout>, <stderr>", exit 2)`.
   - Timeout → `PdError("setup_failed", "<id> timed out after <timeout_seconds>s; logs: <stdout>, <stderr>", exit 2)`.

The return value is the contract's workspace dict (`clone_at`'s keys plus `runtime_path` and `pd_path` from step 4). A failure after the clone keeps the clone, the context and the logs, and puts the clone path in the error message; nothing is pushed or deleted here. Recovery is the lifecycle's job: on `pd resume` of a run blocked in `preparing`, PLD-03-05 deletes that run's clone and `runs/<run_id>/context/` and calls `prepare_workspace` again (contracts "Workspace, runtime and doctor").

`content_digest(folder: Path, runner) -> str` (the only digest implementation; contracts "Installer and update"):

- Lists the files with `git -C <folder> ls-files -z -- .` (paths relative to `folder`). Only files Git tracks count, so `.git/`, `__pycache__/`, `*.pyc`, `dist/`, `build/`, `*.egg-info/` and `.DS_Store` never change the digest, and two clones of the same commit always agree.
- SHA256 over the sorted lines `"<relative posix path>\0<sha256 hex of the working-tree file bytes>\n"`. A tracked symlink is hashed by its target text. A tracked file missing from disk → `PdError("source_mismatch", "<path> is tracked but missing", exit 2)`.
- `folder` not inside a Git work tree → `PdError("not_a_repo", exit 2)`.
- Returns `"sha256:<hex>"`. PLD-04-03 (materialize, update) and doctor call it; nothing else computes a digest.

`load_artifact(root)`: reads `root/.plan-dispatcher/local/artifact.json`. A missing file raises `PdError("artifact_missing", "no prepared artifact; run the installer", exit 2)`. Bad JSON, a missing field or a `wheel_path` that is not absolute raises `artifact_missing` with the reason. `wheel_path` is absolute (contracts), so `prepare_runtime` opens it directly.

`prepare_runtime(workspace_path, artifact, runner)`:

- Check `sha256(wheel_path)` against `wheel_sha256`. Not equal → `PdError("runtime_failed", "wheel digest differs", exit 2)`; file missing → `PdError("runtime_failed", "wheel missing", exit 2)`.
- Run `[sys.executable, "-m", "venv", <workspace>/.plan-dispatcher/venv]`, then `[<venv>/bin/python, "-m", "pip", "install", "--no-index", "--no-deps", <wheel_path>]`. Both get the env var `PIP_NO_INDEX=1`.
- Returns `{runtime_path: <venv>, pd_path: <venv>/bin/pd}`. A non-zero exit → `runtime_failed`, with the command and the last stderr lines.

`doctor(root, config, adapters, runner)`. `adapters` is `{provider: Adapter}`, and `config` may be `None` when no config exists. The probes below run in this order, and all of them run except where noted. Each failing probe adds the listed blocker code to the contract's doctor result.

1. **Config.** `config is None` → no other probe runs and the result is `{providers: {}, git: {}, gh: {}, runtime: {}, caches: {}, blockers: [{code: "needs_setup", message: "run the installer to confirm setup"}]}`: every contract key is present, the others empty. `pd doctor` loads the config itself and turns `PdError("needs_setup")` into this case. `config_invalid` is not a blocker: it fails the command with exit 64.
2. **Providers.** `adapter.describe(models)`, with the unique `models.candidates` IDs for that provider in config order.
   - `binary is None` → `binary_missing`, and that provider's other checks are skipped.
   - `version_ok` false → `version_unsupported`.
   - Non-empty `missing_flags` → `flag_unsupported`.
   - `auth == "missing"` → `auth_missing`.
   - Each `unavailable` model → one `model_unavailable` naming it. `configured` and `verified` are fine.
3. **gh.** `gh --version` non-zero or not found → `gh_missing`, and `gh auth status` is not run. Otherwise a non-zero `gh auth status` → `gh_auth_missing`.
4. **Git.** Steps 1-2 of `prepare_workspace`, without the fetch → `remote_mismatch` and/or `identity_mismatch`.
5. **Runtime.** `load_artifact` fails → `artifact_missing`. When it loads and `distribution.source_kind == "local"`, `content_digest(root / distribution.source, runner)` must equal the manifest's `content_digest`, else `artifact_stale`.
6. **Caches.** For each id in the union of all checks' `needs` (minus `network`), take the `policy.caches` entry with that id (`{id, path}` from the config schema) and expand `~`.
   - The path is writable when it exists and `os.access(path, os.W_OK)`, or when it does not exist and its nearest existing parent is writable.
   - Otherwise → `cache_not_writable`. Doctor never creates the folder.

`doctor` writes nothing. Its only network calls are `gh auth status` and the adapters' read-only probes.

`pd doctor [--provider P ...] [--json]` in `cli.py`:

- Root is `git rev-parse --show-toplevel` run in `Path.cwd()`; outside a Git repo → `PdError("not_a_repo", exit 2)`.
- Providers are the `--provider` values, else `integrations.tools`.
- Adapters come from `adapters.get_adapter(name, SubprocessRunner())`. `PdError("adapter_unavailable")` gives the warning `adapter <name> is not available in this version` and no blocker, so `pd doctor` works before PLD-03-02..04 merge.
- Exit 0 with no blockers, 2 with blockers, 64 on `config_invalid` or usage errors.

Consumers:

- PLD-03-05: the lifecycle calls `prepare_workspace`, `doctor` and `load_artifact`.
- PLD-04-01: `prepare_plan` calls `clone_at` with the plan branch (no runtime, context or setup).
- PLD-04-03: reuses `content_digest` and writes `artifact.json`.
- PLD-04-04.

Execution route: **orchestrator**, under the epic's [runner boundary](../../../contracts.md#runner-boundary-for-this-epic).

## Behavior

- The active checkout is only read: `git remote get-url`, `git config`, `git fetch`, `git ls-remote`, `git rev-parse`, `git show`. No switch, stash, clean, reset or checkout there. `git fetch` only updates remote-tracking refs.
- Linked worktrees: `state_dir` uses `git rev-parse --git-common-dir`, so a run prepared from a linked worktree writes its context under the same `<common-dir>/plan-dispatcher/` as the main checkout.
- Setup failure is a preparation failure (`setup_failed`), never a worker failure, and never retried with broader flags.
- `doctor` makes no network calls beyond what `gh auth status` and the adapters' read-only probes do, and it writes nothing.

## Decisions

- The Git identity comes from the active checkout's own config, so each consumer's existing setup (Sport Timer's repo-local noreply email) carries into the clone. `policy.required_email_suffix` is the only check.
- Base resolution is the shared `gitutil.resolve_base` from PLD-01-03, so the selector, workspace and planner always agree on the base branch.
- The identity, fetch, base, path-rule, clone, branch, exclude and identity-copy steps are one public function, `workspace.clone_at` (contracts "Workspace, runtime and doctor"), so planning clones get the same safety checks. `prepare_workspace` calls it with `task_branch(task)`; PLD-04-01 calls it with the plan branch.
- Caches and network are granted for every check in the frozen config, not a per-diff subset: nothing is known about the diff before the worker runs.
- Setup commands come from the frozen config at `base_sha`, so an uncommitted config edit in the active checkout cannot add a setup command.
- `pd doctor` skips providers whose adapter is not in the installed version yet and warns instead, so it can ship before the adapters.
- Fixture remotes are local bare repositories identified as `local/<name>`, so tests need no URL rewriting.

## Out of scope

- Reservations, run records and the lifecycle (PLD-01-03, PLD-03-05).
- Building or installing the project's `artifact.json` (PLD-04-03); tests write their own.
- Deleting clones (PLD-03-06).

## Files and tests

- New `workspace.py`, `runtime.py` and `preflight.py`; `cli.py` gains `pd doctor`.
- `tests/support.py` gains `build_test_artifact(consumer_root: Path, source_rel: str = "pkgsrc") -> dict`. It uses no setuptools and:
  - builds the real package wheel with `plan_dispatcher.wheel.build_wheel(<tool/plan_dispatcher project root>, out_dir)` (PLD-01-02; the project root is the parent of `support.py`'s folder) into `consumer_root/.plan-dispatcher/local/artifacts/0.1.0-<first 12 hex of the source digest>/`;
  - creates `consumer_root/<source_rel>/marker.txt` when missing;
  - writes `{schema: 1, version: "0.1.0", source_kind: "local", source: source_rel, source_commit: "", content_digest: content_digest(consumer_root/source_rel, runner) (the copied package is committed in the consumer repo first, so `git ls-files` sees it), wheel_path (absolute), wheel_sha256}` to `consumer_root/.plan-dispatcher/local/artifact.json` and returns it.
- `test_workspace.py` uses real Git, temp folders, `SubprocessRunner`, a `cache_root` in a temp folder, and a consumer repo whose `origin` is a local bare repo and whose config has `github_repo = "local/<bare name>"`:
  1. Bare remote whose default branch is `main`, then `master`, then `trunk` with `base_branch = "trunk"`. The clone is on `<type>/<id-lower>-<slug>` at the remote branch SHA, and `base_branch` in the result is correct. The committed config has one setup command `["python3", "-c", "open('setup-ok.txt','w').write('ok')"]`: after preparation `setup-ok.txt` exists in the clone (cwd = clone), and `runs/<run_id>/logs/00-setup-<id>.stdout` and `.stderr` exist.
  2. Active checkout with a dirty tracked file, an untracked file and a non-default current branch: `git status --porcelain`, `HEAD` and the current branch are identical after preparation.
  3. The exclude lines are present, and the clone's `user.email` equals the active checkout's.
  4. Wrong `github_repo` → `remote_mismatch`; an email without the required suffix → `identity_mismatch`. In both cases nothing exists under `cache_root`.
  5. Path rules:
     - a second call with the same run ID → `workspace_collision`, raised by `clone_at`;
     - `clone_at` called directly on an arbitrary branch and a fresh path returns the contract shape and writes nothing under the state folder (`test_clone_at_without_task`);
     - a `cache_root` inside the repo → `workspace_unsafe`;
     - a repo created under the temp cache root → `workspace_unsafe`;
     - a cache root outside the repo but under the same parent folder is accepted.
  6. A setup command that exits 3 → `setup_failed` containing `exited 3`. A setup command with `timeout_seconds = 1` that sleeps 5 s → `setup_failed` containing `timed out after 1s`. The clone and both log files remain.
  7. Offline runtime: `prepare_runtime` with `build_test_artifact` and `PIP_NO_INDEX=1`, then `<venv>/bin/python -c "import plan_dispatcher"` exits 0. A changed `wheel_sha256` → `runtime_failed` (`wheel digest differs`). A relative `wheel_path` in `artifact.json` → `load_artifact` raises `artifact_missing`.
  8. Linked worktree: after `git worktree add`, `freeze_context` from the worktree and from the main checkout both write under the same `<common-dir>/plan-dispatcher/runs/`. A config edited in the working tree but not committed is not in the frozen copy, and its extra setup command does not run.
  9. `plan.json`: a frozen config with checks needing `["pub-cache"]` and `["network"]` gives `caches == ["pub-cache"]`, `network == true`, and `allowed_scope` equal to the task touches.
  10. `parse_github_repo` table: the https, `.git`, scp-style and `ssh://` forms give `O/N`; a local path and a `file://` URL give `local/<name>`; `https://gitlab.com/O/N` gives `""`.
- `test_preflight.py` uses `FakeRunner` for `gh` and git, and fake adapter objects that return fixed `describe` dicts:
  1. All good → no blockers, exit 0 through `cli.main(["doctor", "--json"])`.
  2. One case per blocker code in the contract's doctor list, each giving exactly that code. For `gh_missing`, the `FakeRunner` records no `gh auth status` call.
  3. The local source changed after the artifact was built → `artifact_stale`.
  4. Config problems: no config → only `needs_setup`, with all six result keys present and the other five empty; `pd doctor` run outside a Git repo → exit 2 `not_a_repo`; an invalid config → exit 64 with `config_invalid`. A provider whose `get_adapter` raises `adapter_unavailable` → a warning and no blocker.
  5. A missing cache path with a writable parent → no blocker; a read-only existing cache folder (`chmod 0o500`) → `cache_not_writable`.
  6. `content_digest`: stable across runs; adding untracked `__pycache__/x.pyc`, `dist/a.whl` and `.DS_Store` leaves it unchanged; two `git clone`s of the same commit give the same digest (clone-independence); editing a tracked file changes it; a folder outside Git → `not_a_repo`.
- Commands, from the repository root:
  - `python3 tool/plan_dispatcher/tests/run_tests.py test_workspace test_preflight`
  - `fvm dart tool/agent_check.dart`
  - `fvm flutter test`

## Acceptance

- [ ] When a task is prepared, then a clone outside the repository exists on the task branch at the captured base SHA with its runtime and setup done, and the active checkout's status, HEAD and branch are unchanged. Check: `python3 tool/plan_dispatcher/tests/run_tests.py test_workspace` cases 1-3, 7 and 9.
- [ ] When the remote, identity, path, setup, wheel, provider, `gh`, cache or config prerequisite fails, then preparation or `pd doctor` stops before any worker with exactly that blocker code, keeping diagnostics. Check: `test_workspace` cases 4-6 and 10, and `test_preflight` cases 1-5.
- [ ] When runs are prepared from a linked worktree and the main checkout, then their frozen contexts land in one canonical state folder and come from the base commit. Check: `test_workspace` case 8.
