---
id: PLD-01-03
status: draft
type: feat
complexity: medium
executor: orchestrator
depends-on: [PLD-01-02]
touches:
  - tool/plan_dispatcher/src/plan_dispatcher/gitutil.py
  - tool/plan_dispatcher/src/plan_dispatcher/selection.py
  - tool/plan_dispatcher/src/plan_dispatcher/reservations.py
  - tool/plan_dispatcher/src/plan_dispatcher/github.py
  - tool/plan_dispatcher/src/plan_dispatcher/cli.py
  - tool/plan_dispatcher/tests/test_selection.py
  - tool/plan_dispatcher/tests/test_reservations.py
  - tool/plan_dispatcher/tests/support.py
  - tool/plan_dispatcher/tests/fixtures/tasks/**
skills: []
---

# Select eligible tasks and reserve their scope atomically

Story: [Foundation and task eligibility](../index.md)

Epic: [PlanDispatcher](../../../index.md)

## Goal

Pick the next eligible task with exact reasons for every task that must wait, and reserve a task's ID and scope atomically in local state shared by all linked worktrees. Provide the read-only GitHub lookup and the `pd next`, `pd status` and `pd release` commands.

## Context

- Reference behavior (read-only): `tool/dispatcher/task_selector.dart` (dependency completion, overlap, busy IDs) and `tool/dispatcher.dart` `_branchNames` (remote heads plus open PR heads).
- Failed runs no longer push WIP branches, so local blocked reservations are a busy signal of their own.
- Exact shapes: [contracts — Paths and overlap](../../../contracts.md#paths-and-overlap-pld-01-03-selectionpy), [Selection](../../../contracts.md#selection-pld-01-03), [Local state and reservations](../../../contracts.md#local-state-and-reservations-pld-01-03-pld-03-05), [GitHub boundary](../../../contracts.md#github-boundary-pld-01-03-read-pld-03-06-write-githubpy-portspy), [CLI](../../../contracts.md#cli-pld-01-02-envelope-each-commands-owner-adds-it).
- Shared requirements: R4, R5 (recommendation data and named-task validation only; approval is PLD-04-02), R8, R13, R14. Prerequisite: [PLD-01-02](../02-bootstrap-python-package/index.md).

## Contract

Cross-task shapes are owned by [contracts.md](../../../contracts.md); this task implements them exactly and does not restate them:

- [Paths and overlap](../../../contracts.md#paths-and-overlap-pld-01-03-selectionpy) and [Selection](../../../contracts.md#selection-pld-01-03): `select_tasks`, reason codes (including `archived` for `check_task`), branch/PR matching.
- [Local state and reservations](../../../contracts.md#local-state-and-reservations-pld-01-03-pld-03-05): `reserve`, `mark`, `release`, `transfer`, `list_runs`, lock, atomic writes, run ID, "active" rule, and the minimal `run.json` keys `list_runs` reads.
- [GitHub boundary](../../../contracts.md#github-boundary-pld-01-03-read-pld-03-06-write-githubpy-portspy): `GhCli(runner)` with `open_prs` and `find_pr` (this task); `create_pr` stays `not_implemented` until PLD-03-06.
- `reservations.run_state(record, reservation)` and `selection.snapshot(root, config, runner, github)` (new here; contracts "Local state and reservations" and "Selection"). `pd next` is built on `snapshot` + `select_tasks`/`check_task`; `list_runs` uses `run_state`. Tests: `test_run_state_rules` (one case per rule, in order) in `test_reservations.py`, `test_snapshot_matches_next` in `test_selection.py`.
- `gitutil.resolve_base(root, remote, base_branch, runner) -> str` (new here, shared with PLD-03-01): [Local state and reservations](../../../contracts.md#local-state-and-reservations-pld-01-03-pld-03-05).
- [CLI](../../../contracts.md#cli-pld-01-02-envelope-each-commands-owner-adds-it) rows `pd next`, `pd status`, `pd release`, using the `ports` test seam of `cli.main`.

Private to this task:

- `selection.py` helpers `normalize_scope(s) -> str`, `static_prefix(s) -> str`, `scopes_overlap(a: list, b: list) -> bool`, and `check_task(snapshot, task_id, executor) -> dict` (contract signature; `snapshot` is the `selection.snapshot` dict) = `{task: summary|None, eligible: bool, reasons: [...]}`. Unknown ID → `task: None`, reason `unknown_task`. An archived ID → reason `archived`. The executor filter applies.
- `github.remote_heads(runner, root, remote) -> list[str]`: branch names from `git ls-remote --heads <remote>` (the `refs/heads/` prefix removed).
- `GhCli.find_pr(repo, head, base)`: `gh pr list --repo R --state open --head H --base B --json number,headRefName,baseRefName,url,headRefOid --limit 10`; first result mapped to `{number, head, base, url, head_sha}`, or `None` when empty. `GhCli` runs `gh` with `cwd = Path.cwd()`; `--repo` makes the cwd irrelevant.
- `cli.py` handlers:
  - `pd next [--task ID] [--json]`: `load_config(root)` → `git fetch <remote>` → `resolve_base` → `load_tasks(root, backlog, ref=f"{remote}/{base}", runner)` → `done_ids` = IDs archived in that snapshot → `busy` built as in the Selection contract per the Selection contract's `run_state` mapping (with each reservation's `touches` taken from its `reservations.json` item), `remote_heads` and `open_prs(project.github_repo)` filtered to PRs whose `base` is the resolved base branch → `select_tasks(…, executor="plan-dispatcher-v1")`. With `--task`, `check_task`; when not eligible: exit 2, error code `task_not_eligible`, and (failure-data rule) the envelope keeps `data = {task, eligible: false, reasons}`; plain text prints `<ID> is not eligible:` then one `- <code>: <detail>` line per reason to stderr.
  - `pd status [RUN] [--json]`: `{runs: list_runs()}`; with `RUN`, `{run: item}` or `unknown_run` (exit 2). Plain text output ends with the line `Reservations are local to this machine and checkout; other clones are only seen through remote branches and PRs.`
  - `pd release RUN --invocation T [--adopt] [--json]`: `--invocation` is always required; `--adopt` allows a different token.
  - Root is `Path.cwd()`; any `git` or `gh` failure → exit 2 with `git_failed` or `github_unavailable`; never an empty backlog.
- `support.py` additions: `make_linked_worktree(repo, name) -> Path`, `write_task(root, rel_dir, front_matter: dict, body="")`, `write_run_json(root, run_id, **keys)` (writes the minimal `run.json` keys), `reserve_in_subprocess(root, run_id, task, invocation) -> dict` (runs `reserve(root, run_id, task, invocation, busy=[])` in a separate `multiprocessing` process with the `spawn` start method and returns `{ok: True, item}` or `{ok: False, code}`).

Consumers: PLD-03-01 and PLD-04-01 (`resolve_base`), PLD-03-05 (`reserve`, `mark`, `release`, `transfer`, `run_state`, `snapshot`, `check_task`), PLD-03-06 (`GhCli`), PLD-04-02 (`pd next` output), PLD-05-02 (`pd status`).

Execution route: **orchestrator** (see [Runner boundary](../../../contracts.md#runner-boundary-for-this-epic)).

## Behavior

- Eligibility and reason codes exactly as in the Selection contract; every reason of a task is listed, in this order: `not_ready`, `invalid`, `executor_unsupported`, `duplicate_id`, `dependency_unknown`, `dependency_cycle`, `dependency_pending`, `busy_*`, `scope_overlap`.
- `dependency_cycle` is reported for every task on the cycle; detail lists the cycle IDs in path order.
- A dependency counts as done only when it is in `done_ids` (archived on the base snapshot), never from the local disk.
- `scope_overlap` compares with every `busy` entry's `touches` (from reservations; remote branch and PR entries use the touches of the matching task in the snapshot). A remote branch or PR head that matches no task in the base snapshot (for example a non-task branch, or a task that exists only on that branch) is ignored: it cannot be tied to an ID or a scope.
- `reserve` rechecks only conflicts: a reservation for the same `task_id`, a `busy` entry for it, or a `scope_overlap` with any reservation or `busy` entry. Every conflict raises the single code `reservation_conflict`; detail names the other task ID and run ID (or branch/PR). Readiness, dependencies and executor are not rechecked by `reserve`; the caller ran `check_task` just before.
- Liveness for `run_state`: an `active_stage` is live when its `pid` is alive (`os.kill(pid, 0)`) or its `pgid` group is alive (`os.killpg(pgid, 0)`); `ProcessLookupError` means dead and `PermissionError` means alive. Test: `test_run_state_live_pgid_after_pid_dead` in `test_reservations.py` (spawn a sleeping child in its own session, record a dead `pid` and the child's `pgid`, expect `active`; after killing the child, expect `interrupted`).
- `release`, `mark` and `transfer` on a run with no reservation raise `unknown_run` (exit 2). `release` checks in this order: `unknown_run`, then `run_active` (also with `--adopt`), then `invocation_mismatch`. An `active_stage` recorded on a different host cannot be proven dead, so `run_state` treats it as `active` (never released, cleaned or updated over).
- `reserve` with a `run_id` already present in `reservations.json` raises `reservation_conflict`.
- `reserve`, `mark`, `release`, `transfer` and `list_runs` take an optional keyword `runner=None` (default `SubprocessRunner()`) used only for `state_dir`; tests use real repositories from `make_git_repo`, and `reserve_in_subprocess` relies on the default runner in the spawned process. A run whose `active_stage` PID is dead (interrupted) can be released with its invocation or `--adopt`.
- `list_runs` lists every reservation (enriched from `run.json` when present: `phase`, `workspace`, `active_stage`; else `phase: "reserved"`, `workspace: None`), plus run folders without a reservation. `state` is always `run_state(record, reservation)`, so a folder without a reservation shows `done`, `pending_publication` or `released` according to its phase (`released` when no rule matches).
- A reservation counts as busy even when its task is missing from the base snapshot; its `touches` come from the reservation item.
- A `busy` entry never yields `scope_overlap` for its own task ID (it already yields `busy_*`). It ignores unknown keys in `run.json`.
- `reserve` runs under the `lock` file with `fcntl.flock(LOCK_EX)`; two processes cannot both succeed for the same task or overlapping scopes, also from two linked worktrees of one repository (same common dir).
- Blocked reservations are never removed by age or a vanished PID. `release` needs the recorded invocation, or `adopt=True`; a run with a live `active_stage` is refused with `run_active`.
- Separate clones or machines share no lock; the remote branch and PR checks are the only guard there. `pd status` text output states this limit once.

## Decisions

- Process-based concurrency tests (spawn), because `flock` only proves cross-process exclusion.
- Busy remote branches are matched by the known task prefix `<type>/<id-lower>-` for any of the three types, so no regex has to guess IDs and a branch with an old type still counts.
- `open_prs` fails with `github_unavailable` when the result reaches its limit (see contract), because a cut-off list would look like free work.
- Base resolution falls back to `git ls-remote --symref` because `refs/remotes/<remote>/HEAD` is often unset in fresh clones; when both fail, the error tells the user to set `project.base_branch`.

## Out of scope

- Workspaces, runs, lifecycle and publishing (PLD-03-*); PR creation; model recommendation and launch approval (PLD-04-02).

## Files and tests

Created or changed files are exactly `touches`.

- `test_selection.py`: empty backlog → `next: None`, exit 0; all tasks waiting; path order; each reason code (including `executor_unsupported` for `legacy`, `invalid` for an unchecked criterion, `duplicate_id`, 2-task cycle, unknown dependency, dependency done only on base vs only on disk); several reasons on one task listed in contract order; `busy_remote_branch` (same type and different type prefix) and `busy_open_pr` via `FakeGitHub`; a remote branch that matches no task is ignored; `scope_overlap` cases `a/b` vs `a/b/c.py` (overlap), `a/b` vs `a/bc` (no), `src/*.py` vs `src/x/y.py` (overlap), `**` vs anything (overlap); `check_task` for an eligible, an ineligible, an archived and an unknown ID; `resolve_base` with `base_branch = "dev"`, with `auto` via `symbolic-ref`, with `auto` via the `ls-remote` fallback, and with both failing (`base_branch_unknown`, exit 2, message names `project.base_branch`); `GhCli.open_prs` and `find_pr` argv and mapping through `FakeRunner`, `find_pr` empty → `None`, `open_prs` at the limit → `github_unavailable`; CLI `cli.main(["next", "--json"], ports={...})` with `FakeRunner` failing `git fetch` → exit 2 `git_failed`, failing `gh` → exit 2 `github_unavailable`, success → selection envelope; `next --task ID` for an ineligible task → exit 2, code `task_not_eligible`, envelope `data` with the reasons; busy mapping: one reservation per `run_state` value (`active`, `running`, `interrupted`, `pending_publication` → `busy_reserved`; `blocked` → `busy_blocked`; `done`, `released` → not busy); reservation whose task is missing from the snapshot still blocks an overlapping task; own busy entry gives no `scope_overlap`; an open PR against another base is ignored; `test_snapshot_matches_next`.
- `test_reservations.py`: reserve and list; same task from two spawned processes → exactly one success, the other `reservation_conflict`; overlapping scopes from two linked worktrees → one success; non-overlapping → both succeed; a `busy` remote-branch entry makes `reserve` fail; blocked reservation with a dead PID and an old `created_at` stays listed; `mark` active↔blocked; `transfer` changes the invocation; `release` with a wrong invocation → `invocation_mismatch`; with `adopt=True` → released, run folder kept and then listed by its phase (`released` when the phase is not `done`/`pending_publication`, `done` for a `done` phase); `test_run_state_rules`: one case per rule in order, including an `active_stage` from another host → `active`; release order (`run_active` wins over `invocation_mismatch`); `reserve` with an existing `run_id` → `reservation_conflict`; live `active_stage` (current PID) → `run_active`; dead-PID `active_stage` → release succeeds; `release`/`mark`/`transfer` of an unknown run → `unknown_run`; leftover `*.tmp` removed; corrupt `reservations.json` → `state_corrupt` and file unchanged; CLI `status --json`, `status RUN` (found and `unknown_run`, exit 2), plain `status` ends with the local-limit line, `release RUN --invocation T` and `--adopt`.

Commands, from the repository root:

- `python3 tool/plan_dispatcher/tests/run_tests.py test_selection test_reservations`
- `python3 tool/plan_dispatcher/tests/run_tests.py`
- `fvm dart tool/agent_check.dart --skip-build`
- `fvm flutter test`

## Acceptance

- [ ] When dependencies are pending, unknown or cyclic, the executor is unsupported, readiness is invalid or scopes conflict, then `pd next` leaves the task out and lists each exact reason code with its detail. Check: `test_selection.py`.
- [ ] When two processes in linked worktrees reserve the same or overlapping work, then exactly one succeeds and the other gets `reservation_conflict`. Check: `test_reservations.py` spawn cases.
- [ ] When a blocked reservation ages or its owner PID disappears, then it stays reserved until `pd release` with its invocation or `--adopt`. Check: `test_reservations.py` stale-owner and release cases.
- [ ] When Git or GitHub lookup fails, or the open-PR list is cut off, then `pd next` exits 2 with `git_failed` or `github_unavailable` and never reports an empty backlog. Check: `test_selection.py` CLI failure and limit cases.
- [ ] When `pd status` or `pd release` runs, then it lists or releases runs as in the contract and refuses unknown or active runs with exit 2. Check: `test_reservations.py` CLI cases.
