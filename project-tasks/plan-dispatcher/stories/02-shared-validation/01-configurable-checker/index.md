---
id: PLD-02-01
status: draft
type: feat
complexity: medium
executor: orchestrator
depends-on: [PLD-01-02, PLD-01-03]
touches:
  - tool/plan_dispatcher/src/plan_dispatcher/checks.py
  - tool/plan_dispatcher/src/plan_dispatcher/diff.py
  - tool/plan_dispatcher/src/plan_dispatcher/globs.py
  - tool/plan_dispatcher/src/plan_dispatcher/cli.py
  - tool/plan_dispatcher/tests/test_checks.py
  - tool/plan_dispatcher/tests/test_diff.py
  - tool/plan_dispatcher/tests/fixtures/checks/**
skills: []
---

# Implement the shared configured checker in both modes

Story: [Shared project validation](../index.md)

Epic: [PlanDispatcher](../../../index.md)

## Goal

Provide one `pd check` that turns a change list and the project's validation config into an ordered argv plan, runs it, scans added lines, and reports a meaningful exit code. It has a developer mode for people and a frozen run mode for dispatcher runs that edited config cannot widen.

## Context

- `tool/agent_check.dart` is the consumer behavior this must be able to express through config (read-only here; PLD-02-02 owns the mapping).
- Exact shapes: [contracts — Configuration schema 1](../../../contracts.md#configuration-schema-1-pld-01-02-loads-and-validates-owners-fill-values) (file sets, checks, scans, groups) and [Checker](../../../contracts.md#checker-pld-02-01-checkspy-diffpy). Exit codes and envelope: [CLI](../../../contracts.md#cli-pld-01-02-envelope-each-commands-owner-adds-it).
- Shared requirements: R2, R10, R11. Prerequisites: [PLD-01-02](../../01-foundation/02-bootstrap-python-package/index.md) and [PLD-01-03](../../01-foundation/03-select-and-reserve-tasks/index.md) (for `gitutil.resolve_base`).

## Contract

Cross-task shapes are owned by [contracts.md](../../../contracts.md) and implemented here exactly, without restating them: [Checker](../../../contracts.md#checker-pld-02-01-checkspy-diffpy) (`changed_files`, `added_lines`, `build_check_plan`, `run_checks`, `scan_lines`, report shape including `logs_dir`, skip-reason order, exit precedence, `pd check` forms), the file-set forms and scan rules in [Configuration schema 1](../../../contracts.md#configuration-schema-1-pld-01-02-loads-and-validates-owners-fill-values), the frozen `plan.json` and `PLAN_DISPATCHER_STATE` rule in [Local state and reservations](../../../contracts.md#local-state-and-reservations-pld-01-03-pld-03-05), and `executable_not_found` in [Command runner](../../../contracts.md#command-runner-pld-01-02-portspy).

Private to this task:

- `globs.py`: `match(pattern, path) -> bool` with `*` (within a segment), `**` (zero or more segments), `?`; matching is on `/`-separated repo-relative paths, case-sensitive. `selection.py` keeps its own static-prefix logic.
- `diff.py` commands: `git -c core.quotepath=off diff --name-status -M -z <merge-base>` and `git ls-files --others --exclude-standard -z` for the change list. `added_lines` runs one `git -c core.quotepath=off diff -U0 -M --no-color --src-prefix=a/ --dst-prefix=b/ <merge-base>` for the whole tree and parses each `+++ b/<path>` section (`+` lines, not `+++`), so a renamed file counts only its changed lines. Untracked and explicit files count every line. Binary: NUL byte in the first 8 KB. Deleted and missing files return no lines. File sets see only the new `path` of a rename; `old_path` is informational.
- `checks.load_run_context(state_dir, run_id) -> dict`: reads `runs/<RUN>/context/config.toml` with `config.load_config_file` and `runs/<RUN>/context/plan.json`; uses `run_id`, `workspace`, `base_sha`, `skip_groups`, `include_groups` and ignores the other keys. Missing → `PdError("run_context_missing", 2)`; `run_id` mismatch or bad JSON → `run_context_invalid` (2).
- `run_checks` context: `{root, mode: "developer"|"run", phase, base, changes, config, options, logs_dir}`.
- Logs: developer mode creates `logs_dir` with `tempfile.mkdtemp(prefix="pd-check-")`; run mode called by the engine (no `PLAN_DISPATCHER_RUN` in the environment, the engine's own `checking` and `final_checks`) uses `runs/<RUN>/logs/checks-<phase>-<UTC %Y%m%d%H%M%S>/` in the state folder; run mode called by a worker (`PLAN_DISPATCHER_RUN` set) uses `<workspace>/.plan-dispatcher/local/check-logs/checks-<phase>-<UTC %Y%m%d%H%M%S>/`, which is inside the worker sandbox and excluded from Git (contracts "Checker", run-mode logs). In worker mode the checker only reads the state folder (frozen `config.toml` and `plan.json`); it never creates, writes or deletes anything there. Files are `<NN>-<check id>.stdout` / `.stderr`, `NN` = two-digit plan position starting at `01`. Skipped checks have `stdout_path` and `stderr_path` `None`.
- Developer mode base: `gitutil.resolve_base(root, remote, base_branch, runner)` (PLD-01-03), then `<remote>/<base>`. Failure → exit 2 with `base_branch_unknown` (no base found) or `git_failed` (a Git command failed).
- State folder for run mode: `PLAN_DISPATCHER_STATE` when set; otherwise `gitutil.state_dir(Path.cwd())` (a person typing `pd check --run RUN` in the project checkout). If neither gives a folder that contains `runs/<RUN>/`, exit 2 `run_context_missing`. `PLAN_DISPATCHER_RUN` without `PLAN_DISPATCHER_STATE` uses the same fallback.
- Run mode root: the `workspace` recorded in `plan.json` is the root for diffs, the `exists` check, each check's `cwd` and the generated-change snapshots; the current directory is ignored. A `workspace` folder that does not exist → exit 2 `run_context_invalid`.
- Group names: a `--skip-group`/`--include-group` name (or `--skip-build` when no check uses group `build`) that no check uses is ignored and adds the warning `unknown group <name>` to the envelope `warnings`. In run mode, `--skip-build`/`--skip-group G` is accepted only when the frozen `plan.json` already skips that group; otherwise exit 64 `mode_conflict`.
- `scan_lines` result order: config scan order, then path (sorted), then line number.
- CLI output on failure (contract failure-data rule): `pd check` keeps the report as `data`, with `ok: false` and `error.code` `checks_failed` (exit 1) or `checks_blocked` (exit 2). The plain text block always goes to stdout; on failure the single line `error <code>: <n> check(s) failed|blocked` also goes to stderr. A missing or invalid run context is a raised error with no report (`data: null`).
- `needs` has no effect in the checker: it only feeds the frozen sandbox profile (PLD-03-01/03-05). The checker never blocks a check because of `needs`.
- Text output: one line per check `PASS|FAIL|SKIP|BLOCKED|TIMEOUT <id>` (SKIP adds the reason), then scan lines `<severity> <scan_id> <path>:<line>`, then `result: ok|failed|blocked (logs: <logs_dir>)`.

Consumers: PLD-02-02 (parity), PLD-03-02..04 (worker `pd check` grant), PLD-03-05 (final checks call `run_checks` directly with the frozen config), PLD-05-03 (retirement).

Execution route: **orchestrator** (see [Runner boundary](../../../contracts.md#runner-boundary-for-this-epic)).

## Behavior

- Plan order is config order. When a check qualifies for several skip reasons, the first in this order is reported: `fix_in_final` (a `fix` variant in the final phase), `phase` (check not in this phase), `group_skipped`, `not_triggered`, `no_files`.
- A check runs every planned entry even after a failure; the report aggregates all results.
- Per-check timeout is the check's `timeout_seconds` (default 900); a timeout is `timed_out`.
- A check whose runner call raises `PdError("executable_not_found")` is `blocked`; `report.blocked` is true when any check is blocked. A missing run context never produces a report: it is the raised `run_context_missing` error (exit 2).
- Exit precedence: 2 when anything is blocked (a repair worker cannot fix a missing tool), else 1 when any check failed or timed out, a failure scan matched or `generated_changes` is non-empty, else 0.
- No changes → every non-`always` check is `not_triggered`, `ok: true`, exit 0.
- Final phase snapshots status and HEAD before and after; any difference lists the changed paths in `generated_changes` and makes `ok` false, exit 1.
- Scan evidence never includes the matched text.
- Under `PLAN_DISPATCHER_RUN`, a plain `pd check` (no arguments) runs in run mode for that run. Developer arguments (`--base`, `--include-group`, explicit paths, a different `--run`) are refused with exit 64 `mode_conflict`. A worker can still read the repo config, but its edits never reach run mode, which reads only the frozen copy.

## Decisions

- The run state folder comes from `PLAN_DISPATCHER_STATE`, because task workspaces are separate clones whose own Git common dir is not the project's state folder.
- Failures do not stop later checks, so one run reports everything a repair worker must fix.

## Out of scope

- Sport Timer config and parity data (PLD-02-02); writing `plan.json` (PLD-03-01); running setup commands (PLD-03-01).

## Files and tests

Created or changed files are exactly `touches`. Fixtures use synthetic paths (`src/app/main.py`, `tests/app/test_main.py`, `assets/strings.json`).

- `test_checks.py`: ordered plan with three checks; skip-reason precedence (a `fix` check in final reports `fix_in_final`; a check in a skipped group with no changes reports `group_skipped`); exit precedence (one failed and one blocked check → exit 2; failure scan plus blocked → 2; failed only → 1); skipped checks have `None` log paths and run checks have `NN-<id>` log files under `logs_dir`; `needs = ["network"]` does not change the plan; prefix/suffix mapping then `existing_only` with an injected `exists`; union of two sets is sorted and de-duplicated; `source_must_exist` drops a deleted source before mapping; a fixed set emits its path only when a `when_any` set is non-empty and respects `existing_only`; explicit `./b.md`, `b.md` and `` normalize to one `b.md`; `scan_lines` result order (scan order, path, line); `{files:X}` expansion into separate argv entries, including a path with a space; empty expansion skipped and `run_without_files` run; `trigger_any = []` always runs; `--skip-build` skips group `build`; `default_skipped_groups` plus `--include-group`; `fix` variant dropped in final; failure aggregation (two failing checks both reported, exit 1); timeout; missing executable (`FakeRunner` raising `executable_not_found`) → `blocked`, exit 2; no changes; base resolution failure → exit 2; run mode with missing context → exit 2 `run_context_missing` and `data: null`; run mode uses the `plan.json` workspace as root even when started from another directory; missing workspace folder → `run_context_invalid`; state folder fallback without `PLAN_DISPATCHER_STATE`; unknown group name → warning; run-mode `--skip-group G` not in the frozen skips → `mode_conflict`; `--json` failure envelope keeps the report with `checks_failed`/`checks_blocked`; run mode ignores a command added to the workspace `.plan-dispatcher/config.toml` (tamper case); `PLAN_DISPATCHER_RUN` plus `--base` → exit 64 `mode_conflict`; `PLAN_DISPATCHER_RUN` with no arguments → run mode; final phase where a fake check writes a tracked file → `generated_changes`, exit 1; argv passed to `FakeRunner` as a list (no shell).
- `test_checks.py` worker-mode isolation: `test_worker_mode_writes_only_in_workspace` — with `PLAN_DISPATCHER_RUN` and `PLAN_DISPATCHER_STATE` set to a temp state folder made read-only (`chmod -R a-w`), `pd check --run RUN` completes, its logs are under `<workspace>/.plan-dispatcher/local/check-logs/`, and a recursive listing of the state folder (names, sizes, mtimes) is identical before and after. `test_engine_mode_writes_logs_in_state` — the same run without `PLAN_DISPATCHER_RUN` writes under `runs/<RUN>/logs/`.
- `test_diff.py` (real temp repos from `make_git_repo`): modified hunk added lines; deleted file; rename with one edited line counts only that line and reports `old_path`; untracked file counts every line; explicit path counts every line; binary file skipped; Unicode and space paths; failure scan → exit 1; advisory scan → exit 0 and listed; scan `exclude` honoured; matched text absent from report.

Commands, from the repository root:

- `python3 tool/plan_dispatcher/tests/run_tests.py test_checks test_diff`
- `python3 tool/plan_dispatcher/tests/run_tests.py`
- `fvm dart tool/agent_check.dart --skip-build`
- `fvm flutter test`

## Acceptance

- [ ] When `pd check` runs under `PLAN_DISPATCHER_RUN`, then it uses only the frozen config and plan, ignores workspace config edits, and rejects developer arguments with exit 64 `mode_conflict`. Check: `test_checks.py` run-mode and tamper cases.
- [ ] When file sets, checks, groups and scans apply to a change, then the ordered argv plan, statuses, scan severities and exit codes match the contract. Check: `test_checks.py` plan cases and `test_diff.py`.
- [ ] When a final-phase check changes a tracked file, then the report lists it in `generated_changes` and exits 1. Check: `test_checks.py` generated-change case.
