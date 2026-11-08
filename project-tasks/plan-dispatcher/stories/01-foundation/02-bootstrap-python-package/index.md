---
id: PLD-01-02
status: draft
type: feat
complexity: medium
executor: orchestrator
depends-on: [PLD-01-01]
touches:
  - .gitignore
  - .github/workflows/plan-dispatcher.yml
  - tool/plan_dispatcher/pyproject.toml
  - tool/plan_dispatcher/README.md
  - tool/plan_dispatcher/LICENSE
  - tool/plan_dispatcher/install.py
  - tool/plan_dispatcher/build_backend/pd_build.py
  - tool/plan_dispatcher/src/plan_dispatcher/__init__.py
  - tool/plan_dispatcher/src/plan_dispatcher/__main__.py
  - tool/plan_dispatcher/src/plan_dispatcher/cli.py
  - tool/plan_dispatcher/src/plan_dispatcher/config.py
  - tool/plan_dispatcher/src/plan_dispatcher/tasks.py
  - tool/plan_dispatcher/src/plan_dispatcher/contracts.py
  - tool/plan_dispatcher/src/plan_dispatcher/ports.py
  - tool/plan_dispatcher/src/plan_dispatcher/errors.py
  - tool/plan_dispatcher/src/plan_dispatcher/wheel.py
  - tool/plan_dispatcher/src/plan_dispatcher/gitutil.py
  - tool/plan_dispatcher/src/plan_dispatcher/adapters/__init__.py
  - tool/plan_dispatcher/src/plan_dispatcher/resources/schemas/**
  - tool/plan_dispatcher/src/plan_dispatcher/_vendor/**
  - tool/plan_dispatcher/tests/__init__.py
  - tool/plan_dispatcher/tests/run_tests.py
  - tool/plan_dispatcher/tests/support.py
  - tool/plan_dispatcher/tests/fixtures/config/**
  - tool/plan_dispatcher/tests/fixtures/tasks/**
  - tool/plan_dispatcher/tests/test_config.py
  - tool/plan_dispatcher/tests/test_tasks.py
  - tool/plan_dispatcher/tests/test_cli.py
  - tool/plan_dispatcher/tests/test_wheel.py
  - tool/plan_dispatcher/tests/test_ports.py
  - tool/plan_dispatcher/tests/test_gitutil.py
  - tool/plan_dispatcher/tests/test_contracts.py
skills: []
---

# Bootstrap the independent Python package and contracts

Story: [Foundation and task eligibility](../index.md)

Epic: [PlanDispatcher](../../../index.md)

## Goal

Create the self-contained `tool/plan_dispatcher/` Python package with its offline test entry point, config and task loaders, shared validators, injected ports, CLI envelope and deterministic wheel builder. Every later module task builds on these fixed shapes.

## Context

- No Python package exists today. Reference behavior for task parsing: `tool/dispatcher/task.dart` and `tool/dispatcher/extensions/front_matter_text.dart` (read-only). Copy their behavior, not Flutter structure.
- Local interpreter is Python 3.9.6 (`/usr/bin/python3`), so the vendored tomli fallback is the path the required tests exercise.
- Exact shapes: [contracts — Package layout](../../../contracts.md#package-layout-pld-01-02), [Front matter subset](../../../contracts.md#front-matter-subset-pld-01-02-taskspy), [Task model](../../../contracts.md#task-model-pld-01-02-taskspy), [Command runner](../../../contracts.md#command-runner-pld-01-02-portspy), [CLI](../../../contracts.md#cli-pld-01-02-envelope-each-commands-owner-adds-it), [Configuration schema 1](../../../contracts.md#configuration-schema-1-pld-01-02-loads-and-validates-owners-fill-values), [Stage protocol](../../../contracts.md#stage-protocol-pld-01-02-validates-adapters-pld-03-0204) and [Runner boundary](../../../contracts.md#runner-boundary-for-this-epic).
- Shared requirements: R1, R7, R15, R16. Prerequisite: [PLD-01-01](../01-route-task-executors/index.md).

## Contract

Cross-task shapes are owned by [contracts.md](../../../contracts.md) and are not restated here. This task implements, exactly as written there:

- [Package layout](../../../contracts.md#package-layout-pld-01-02) (files, build, install of a wheel, TOML import, errors, test entry, `.gitignore`, CI).
- [Front matter subset](../../../contracts.md#front-matter-subset-pld-01-02-taskspy) and [Task model](../../../contracts.md#task-model-pld-01-02-taskspy) (`load_tasks`, `readiness_errors`, `task_slug`, `task_branch`).
- [Command runner](../../../contracts.md#command-runner-pld-01-02-portspy) (`CommandRunner`, `SubprocessRunner`, `FakeRunner`, `make_git_repo`, `FakeGitHub`, `fake_executable`).
- [CLI](../../../contracts.md#cli-pld-01-02-envelope-each-commands-owner-adds-it) envelope, output streams, exit codes and the `main(argv=None, ports=None)` test seam, with every row of the table registered as a stub.
- [Configuration schema 1](../../../contracts.md#configuration-schema-1-pld-01-02-loads-and-validates-owners-fill-values), including its "Required and optional keys" table and "Cross-reference rules", plus `load_config_file(path)` and the `sha256:pending` rule.
- [Stage protocol](../../../contracts.md#stage-protocol-pld-01-02-validates-adapters-pld-03-0204) "Validator rules" (`contracts.py`) and the three report JSON Schema files.
- `GitHubPort` protocol from [GitHub boundary](../../../contracts.md#github-boundary-pld-01-03-read-pld-03-06-write-githubpy-portspy) (protocol only; `github.GhCli` is PLD-01-03).
- `state_dir` from [Local state and reservations](../../../contracts.md#local-state-and-reservations-pld-01-03-pld-03-05).
- `adapters.get_adapter` registry rule from [Stage protocol](../../../contracts.md#stage-protocol-pld-01-02-validates-adapters-pld-03-0204).

Private to this task:

- `gitutil.git(runner, root, *args) -> str`: runs `["git", "-C", str(root), *args]`, returns stdout stripped of one trailing newline; non-zero exit raises `PdError("git_failed", "<args>: <last 500 chars of stderr>", 2)`.
- `plan_dispatcher.__version__ = "0.1.0"`; `pd --version` prints it to stdout and exits 0. `test_wheel.py` asserts it equals `pyproject.toml`'s version.
- CLI registry (contract "CLI"): `cli.py` defines `Command = namedtuple("Command", "name add_arguments run")` and `COMMANDS: dict[str, Command]`, one entry per CLI table row, keyed by the first word after `pd` (`plan` is one entry whose parser has `prepare`/`review` subcommands added by its owner). `main` builds one `argparse` subparser per entry and calls `entry.add_arguments(subparser)`, then `entry.run(args, ports)`; the returned dict becomes `data`, a raised `PdError` becomes the failure envelope. Stub entries use `add_arguments = lambda p: p.add_argument("rest", nargs=argparse.REMAINDER)` and `run` raises `PdError("not_implemented", "<name> is provided by <owner task id>", 64)`. A later owner replaces its entry's `add_arguments`/`run` in `COMMANDS` (editing `cli.py`).
- `--json` detection: before parsing, `json_mode = "--json" in argv` (anywhere, so a REMAINDER stub still sees it), and `--json` is removed from the list given to argparse. Every outcome, including `usage` errors and `not_implemented`, uses the envelope on stdout when `json_mode`, else plain text (success to stdout, `error <code>: <message>` to stderr).
- Default `ports` (contract "CLI"): `runner` → `SubprocessRunner()`; `get_adapter` → `adapters.get_adapter`; `adapters` → `{}`; `clock` → `time.time`; `github` → resolved lazily on first use by `ports_github(ports)`, which imports `plan_dispatcher.github` and returns `github.GhCli(ports["runner"])`; an `ImportError` raises `PdError("not_implemented", "github is provided by PLD-01-03", 64)`. Nothing is imported eagerly, so commands that never touch GitHub work before PLD-01-03.
- `wheel.build_wheel(project_root, out_dir)`: `project_root` is the folder that holds `pyproject.toml` (here `tool/plan_dispatcher`). It reads `name`, `version`, `requires-python`, `license.text` and `[project.scripts]` from `pyproject.toml` with the same TOML import as `config.py`. Files: every file under `src/plan_dispatcher/` except `__pycache__/`, `*.pyc` and `.DS_Store`, stored as `plan_dispatcher/...`. Metadata: `METADATA` (`Metadata-Version: 2.1`, `Name: plan-dispatcher`, `Version`, `Requires-Python`, `License: MIT`), `WHEEL` (`Wheel-Version: 1.0`, `Generator: pd_build`, `Root-Is-Purelib: true`, `Tag: py3-none-any`), `entry_points.txt` (`[console_scripts]` `pd = plan_dispatcher.cli:main`), `RECORD`. Zip: `ZIP_DEFLATED`, entries sorted, every timestamp `1980-01-01 00:00:00`, file mode `0o644` in `external_attr`.
- `build_backend/pd_build.py`: PEP 517 `build_wheel(wheel_directory, config_settings=None, metadata_directory=None)` calls `wheel.build_wheel(Path(__file__).parents[1], wheel_directory)` and returns the file name; `build_sdist` (a required PEP 517 hook; nothing in this epic consumes the sdist) writes `plan_dispatcher-0.1.0.tar.gz` with `pyproject.toml`, `README.md`, `LICENSE`, `install.py`, `build_backend/` and `src/` (same exclusions), entries sorted. It is not required to be byte-identical across builds.
- `install.py` (package root): prints `install.py is provided by PLD-04-03` to stderr and exits 64.
- `tests/support.py` also has `temp_dir()` (a `tempfile.TemporaryDirectory` context manager returning a `Path`). `make_git_repo` (and the bare remote it creates) sets a repo-local identity `git config user.name pd` and `git config user.email pd@users.noreply.github.com` before the first commit, so tests pass on CI runners that have no global Git identity. Every later helper that creates a repository does the same.
- Package text rule: no file under `tool/plan_dispatcher/` (code, tests, fixtures, docs) may contain a word that `test/tool/fixtures/plan_dispatcher_boundary_patterns.txt` (PLD-02-02) forbids. A test that must check for such a word builds it from parts at runtime (for example `'flut' + 'ter'`), as `tool/agent_check.dart` does for its home-path marker.
- `FakeRunner` and `FakeGitHub` follow the exact semantics in contracts "Command runner" (the test-helper paragraph). `FakeRunner(script)`: each entry is `(matcher, result_or_exception)`; `matcher` is an argv-prefix list or a callable `argv -> bool`; on each call the runner searches forward from the first unused entry for the first match, marks it used and returns `{"exit_code": 0, "stdout": "", "stderr": "", "timed_out": False}` updated with the entry's dict (or raises the entry's exception); it writes `stdout`/`stderr` to `stdout_path`/`stderr_path` when given; no match raises `AssertionError("unexpected call: <argv>")`; leftover entries are not a failure; every call is appended to `.calls` as `{argv, cwd, env, timeout_seconds, stdin}`. `FakeGitHub(prs=None, fail=None)`: `prs` is a list of `{number, head, base, url, head_sha}`; `fail` maps a method name to an exception raised on every call to it; `.calls` records `(method, args)`; `create_pr` appends a PR with the next number, `url = "https://example.invalid/pr/<n>"` and `head_sha` from `set_head(branch, sha)` (or `""` when not set); `set_head(branch, sha)` also updates existing PRs with that head.
- `_vendor/__init__.py` (empty), `_vendor/tomli/` = the files of `src/tomli/` from the sdist below, unmodified, plus `LICENSE` (from the sdist) and `PROVENANCE.md` (URL, version 2.0.1, SHA256 below, "copied unmodified from src/tomli/").
- `pyproject.toml`: `[project] name = "plan-dispatcher"`, `version = "0.1.0"`, `requires-python = ">=3.9"`, `license = {text = "MIT"}`, `readme = "README.md"`, `[project.scripts] pd = "plan_dispatcher.cli:main"`, `[build-system] requires = []`, `build-backend = "pd_build"`, `backend-path = ["build_backend"]`.
- `README.md` sections, in this order: `# PlanDispatcher` (one paragraph: what it does), `## Requirements` (macOS, Python 3.9 or newer, Git; GitHub CLI `gh` for publishing), `## Running tests` (`python3 tests/run_tests.py`), `## Building a wheel` (`python3 -m pip wheel --no-deps --no-build-isolation -w dist .`), `## License` (MIT, see LICENSE). No project-specific names.
- `.github/workflows/plan-dispatcher.yml`: `name: PlanDispatcher`; `on: pull_request` and `push` to `master`, both with the `paths` listed in the contract (paths that do not exist yet are fine); `permissions: contents: read`; one job `python-tests`, `runs-on: macos-latest`, `strategy.matrix.python: ["3.9", "3.13"]`; steps `actions/checkout@v7.0.1` (same pin as `ci.yml`), `actions/setup-python@<tag>` with `python-version: ${{ matrix.python }}`, where `<tag>` is the exact latest release tag printed by `gh api repos/actions/setup-python/releases/latest --jq .tag_name` at implementation time; then `run: python tool/plan_dispatcher/tests/run_tests.py`.

Consumers: every later package task. PLD-02-02 adds the parity step to the workflow.

Execution route: **orchestrator** (see [Runner boundary](../../../contracts.md#runner-boundary-for-this-epic)). The one network action allowed is downloading `https://files.pythonhosted.org/packages/c0/3f/d7af728f075fb08564c5949a9c95e44352e23dee646869fa104a3b2060a3/tomli-2.0.1.tar.gz` and checking that its SHA256 is `de526c12914f0c550d15924c62d72abc48d6fe7364aa87328337a31007fe8a4f` (the value PyPI publishes for this file) before extracting it in a temp folder. A mismatch stops the task. The `gh api` call for the setup-python tag is read-only.

## Behavior

- Front matter: exactly the contract subset; every other construct raises `front_matter_invalid` with `<path>:<line>`. Inline comments are stripped (`status: draft  # x` → `draft`).
- Task files: both the long Sport Timer layout and the shorter layout load; body text is preserved byte for byte; folders under `done/` load with `archived = true`.
- Files without a task `id`: a file whose first line is not `---` has no front matter and is skipped. A file with front matter is always parsed: a parse error raises `front_matter_invalid` even when there is no `id` (so a broken epic or story index is reported); a valid front matter without `id` is skipped. An opening `---` with no closing `---` raises `front_matter_invalid`. `key:` with no value and no following list items is an empty list (`[]`).
- Duplicate task IDs are not an error in `load_tasks` (selection reports `duplicate_id`); duplicate keys inside one front matter are.
- Config: every rule in "Configuration schema 1" (including the required/optional table and cross-reference rules) is validated; nothing is written by the loader. Validation stops at the first error, in file order.
- CLI: unknown command or bad flags on a real parser → exit 64, code `usage`; envelope always has `schema`, `ok`, `data`, `warnings`; `data` follows the contract's failure-data rule (`null` for every failure this task can produce).
- Wheel: building twice from the same tree gives byte-identical files; the wheel contains `plan_dispatcher/resources/schemas/*.json` and `plan_dispatcher/_vendor/tomli/LICENSE`.

## Decisions

- No third-party build tool: an in-tree stdlib backend keeps install and tests offline (planning decision from cold read; replaces "pinned release-only tools").
- `"sha256:pending"` lets the consumer config be committed (PLD-02-02) before the first install computes the digest (PLD-05-01).
- CI matrix is `macos-latest` with Python 3.9 and 3.13: the oldest supported and a current version.
- `LICENSE` is the standard MIT text with the line `Copyright (c) 2026 alexaniko88` (user decision D54: the usual form for a personal GitHub project, matching the Git author and keeping a real name out of a public file).

## Out of scope

- Selection, reservations, checks, adapters, lifecycle, installer and skills (later tasks).
- Any application, Flutter, Android or iOS change.

## Files and tests

Created or changed files are exactly `touches`. Fixtures under `tests/fixtures/config/` and `tests/fixtures/tasks/` use synthetic, framework-neutral paths (`src/app.py`, `docs/tasks/...`).

- `test_config.py`: valid minimal config (only required keys) loads with every default filled in; valid full config; each required table missing; each required key in `[project]`, `[distribution]`, `[policy]` missing; `schema = 2`; unknown key at top level and inside a check; wrong type (string for a list, list for a string, float for `timeout_seconds`); each enum out of range (`source_kind`, severity, phase, variant, provider, role, complexity, effort); duplicate id in file sets, checks, scans, setup commands and caches; `trigger_any`, `union`, `when_any` and `{files:X}` naming an unknown set; `{files:X}` inside a longer token; cyclic `union`; fixed set with `include`; pattern set without `include`; invalid regex in a scan and in `leak_scans`; `needs` naming an unknown cache; `default_skipped_groups` naming an unused group; candidate provider not in `integrations.tools`; `source_kind = "git"` with a short commit and with an empty `source_ref`; `source_kind = "local"` with a commit; absolute and `..` path in `backlog`, `instructions.paths` and `fixed`; argv as a string and as `[]`; `fix` variant with `final` phase; `sha256:pending` accepted for local and rejected for git; malformed digest; missing file → `needs_setup` (exit 2); `load_config_file` on a frozen copy; Unicode and spaces in paths and argv preserved.
- `test_tasks.py`: inline and block lists, `[]`, quoted values, inline comments; duplicate key, nested map, tab indent, multi-line scalar each rejected with line number; missing required key; bad enum; executor absent → `legacy`; acceptance IDs A1.. and `check` extraction (same line and next line); `archived`; `readiness_errors` for every code; `task_slug`/`task_branch`; long and short layouts; `ref` mode against `make_git_repo` and a `git_failed` case through `FakeRunner`.
- `test_contracts.py`: for each validator, one valid dict and one failing case per rule in "Validator rules" (missing key, unknown key, wrong type, bad enum, the cross-field rules such as `approved: false`, read profile with `extra_write_dirs`, `report` set while `report_valid` is false, missing/duplicate/extra criterion, empty `commit_subject` with and without `blocked`); every failure has code `<kind>_invalid` and exit 64. The three JSON Schema files parse with `json.load` and list the same required keys as the validators.
- `test_ports.py`: `SubprocessRunner` returns stdout/stderr/exit 0 for `python3 -c`; writes `stdout_path`/`stderr_path`; passes `stdin`; merges nothing into `env` when given (child sees only that env plus nothing else); a missing executable raises `executable_not_found` (exit 2); a child killed by SIGTERM from itself reports a negative `exit_code`; timeout with a child that starts a grandchild `sleep 60`: returns `timed_out: true`, `exit_code: None` within 15 s and the grandchild is gone (checked with `os.kill(pid, 0)`). `FakeRunner`: prefix and callable matchers; forward search skips a non-matching entry and later uses it; each entry used once; result merged with defaults; exception entry raised; `stdout_path` written; unexpected call raises `AssertionError`; leftover entries do not fail. `FakeGitHub`: seeded `prs` returned by `open_prs` and `find_pr`; `fail` raises on that method only; `create_pr` numbering and `set_head`; `.calls` log.
- `test_gitutil.py`: `git` returns stdout; `git_failed` with the stderr tail; `state_dir` in a `make_git_repo` checkout and in a linked worktree (`git worktree add`) returns the same path, created on first use.
- `test_cli.py`: `pd --version` prints `0.1.0`; `main([...], ports={"runner": FakeRunner([])})` passes the fake to a command handler (the test puts a `Command` into `cli.COMMANDS` with `unittest.mock.patch.dict` and removes it after); `--json` placed after a stub's other arguments still gives the envelope; a `usage` error with `--json` prints the envelope to stdout; `ports_github` without `plan_dispatcher.github` raises `not_implemented`; `python -m plan_dispatcher next --json` and `next --task X --json` return the `not_implemented` envelope with `data: null` and exit 64; plain (non-JSON) failure prints `error not_implemented: …` to stderr; unknown command exit 64 `usage`; envelope keys; `install.py` stub exits 64; `get_adapter("claude", runner)` raises `adapter_unavailable` (exit 2) when the import fails, tested with `unittest.mock.patch("importlib.import_module", side_effect=ImportError)` so the test stays green after the adapter modules exist; `get_adapter("other", runner)` raises `unknown_provider` (exit 64).
- `test_wheel.py`: build twice into two temp dirs and compare bytes; the wheel lists the schemas, the vendored license and no `__pycache__`; `RECORD` hashes match; `METADATA` fields as listed; `__version__` equals `pyproject.toml`'s version; `README.md` has the five headings; `pd_build.build_sdist` returns a file name that exists and its archive lists `pyproject.toml` and `src/plan_dispatcher/__init__.py`; install the wheel into a temp venv (`python3 -m venv`, then `<venv>/bin/python -m pip install --no-index --no-deps <wheel>`) and `<venv>/bin/pd --version` prints `0.1.0` (offline).

Commands, from the repository root:

- `python3 tool/plan_dispatcher/tests/run_tests.py test_config test_tasks test_contracts test_ports test_gitutil test_cli test_wheel`
- `python3 tool/plan_dispatcher/tests/run_tests.py`
- `fvm flutter test test/architecture/ai_setup_test.dart`
- `fvm dart tool/agent_check.dart --skip-build`
- `fvm flutter test`

## Acceptance

- [ ] When the source test command runs before any installation, then all package tests pass on Python 3.9 with no network and no third-party module. Check: `python3 tool/plan_dispatcher/tests/run_tests.py`.
- [ ] When front matter or config is invalid, then a `ContractError` with code `front_matter_invalid` or `config_invalid` names the file/line or key path and nothing is written. Check: `test_tasks.py` and `test_config.py` failure cases.
- [ ] When the wheel is built twice from the same tree, then both files are byte-identical and contain the schemas and vendor license. Check: `test_wheel.py`.
- [ ] When any `pd` command is called before its owner exists, then it returns the schema-1 envelope with `not_implemented` and exit 64, never success. Check: `test_cli.py`.
- [ ] When a stage request, launch request, stage result or report breaks a validator rule, then a `ContractError` `<kind>_invalid` with exit 64 names the key path. Check: `test_contracts.py`.
- [ ] When a command times out, then the runner kills its whole process group and reports `timed_out`. Check: `test_ports.py` timeout case.
- [ ] When this task's PR is open, then the new `PlanDispatcher` workflow passes on Python 3.9 and 3.13. Check: `gh pr checks <PR number>` shows both `python-tests` jobs passing.
