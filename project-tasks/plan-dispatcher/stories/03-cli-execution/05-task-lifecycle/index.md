---
id: PLD-03-05
status: draft
type: feat
complexity: high
executor: orchestrator
depends-on: [PLD-01-03, PLD-02-01, PLD-03-01, PLD-03-02, PLD-03-03, PLD-03-04]
touches:
  - tool/plan_dispatcher/src/plan_dispatcher/lifecycle.py
  - tool/plan_dispatcher/src/plan_dispatcher/state.py
  - tool/plan_dispatcher/src/plan_dispatcher/cli.py
  - tool/plan_dispatcher/src/plan_dispatcher/resources/prompts/worker.md
  - tool/plan_dispatcher/src/plan_dispatcher/resources/prompts/repair.md
  - tool/plan_dispatcher/src/plan_dispatcher/resources/prompts/reviewer.md
  - tool/plan_dispatcher/tests/test_lifecycle.py
  - tool/plan_dispatcher/tests/support.py
skills: []
---

# Run and resume the worker/check/review lifecycle

Story: [CLI execution and reviewed publication](../index.md)

Epic: [PlanDispatcher](../../../index.md)

## Goal

Add the one engine state machine that takes an approved launch request through reservation, preparation, one worker, engine checks, up to two repairs and a fresh reviewer, and that can resume or hand over a saved run. Publication is plugged in later by PLD-03-06; until then the real CLI stops honestly at `pending_publication`.

## Context

- The Dart `tool/dispatcher/launch_pipeline.dart` has separate implementation and test stages, separate check and review repair loops, and pushes WIP on failure. Read it only to see what is replaced; do not port its shape.
- Cross-task shapes are owned by [contracts.md](../../../contracts.md) and are not restated here: "Launch request and run record" (request, record fields, `drive`/`step`/`state` signatures, `ports` keys, phases, blocker codes), "Local state and reservations" (state files, `plan.json`, run ID, active rule), "Stage protocol" (request, `permission_profile`, normalized result, reports, schema files), "Checker" (check report, `pd check --run`), "Workspace, runtime and doctor" and "CLI" (envelope and exit codes).
- Inputs from earlier tasks: `reservations.py`, `selection.py` and `selection.snapshot` (PLD-01-03), `checks.py`, `diff.py`, `globs.py` (PLD-02-01), `workspace.py`, `runtime.py`, `preflight.py` (PLD-03-01), and the three adapters (PLD-03-02..04).
- Shared requirements: R6 (only the engine part: an unavailable explicit model is refused, and `auto_model` is recorded for this run only), R7, R9, R12, R13.

## Contract

Provided here, public shapes in contracts "Launch request and run record": `state.new_run`, `state.load_run`, `state.save_run`, `lifecycle.step`, `lifecycle.drive`, and the CLI rows `pd start` and `pd resume`.

Private to this task (`P` = `tool/plan_dispatcher/src/plan_dispatcher/`):

- `reservations.run_state(record, reservation)` (PLD-01-03, contracts "Local state and reservations") decides `active`, `interrupted`, `blocked`, `pending_publication`, `done`, `running` and `released`; this task reuses it and never redefines it. An in-process interruption (below) clears `active_stage`, so it shows as `blocked` with blocker code `interrupted`.
- `state.new_run(root, launch, task)` stores `task = {id, title, type, touches, path, criterion_ids}` in the record, taken from the base snapshot task dict (`criterion_ids` = its acceptance IDs in order). This is a proposed run record field (see Decisions); every stage, the candidate and the publication read task data from it, never from the moving working tree.
- Prompt resources `P/resources/prompts/{worker,repair,reviewer}.md`, rendered with `str.format_map` and only these placeholders: `{task_snapshot_path}` (absolute path of the frozen `context/task.md`), `{instruction_paths}` (the frozen config's `instructions.paths`, workspace-relative, one `- path` line each), `{pd_path}` (absolute workspace `pd`), `{run_id}`, `{findings_path}` (repair only, absolute), `{base_sha}`, `{candidate_sha}` (reviewer only), `{report_schema_path}` (absolute path of `P/resources/schemas/worker.schema.json` for worker and repair, `reviewer.schema.json` for the reviewer), `{commit_subject_pattern}` (worker and repair: the frozen `policy.commit_subject_pattern`, so the first report's `commit_subject` can match without spending a repair). Worker and repair prompts say: implement only this task, read the instruction files, stay inside the task's `touches`, run `{pd_path} check --run {run_id}`, write `commit_subject` so it matches `{commit_subject_pattern}`, never commit, push, or edit or move the task folder, and end with the report as the final JSON message. The reviewer prompt asks for a read-only review of `git diff {base_sha}..{candidate_sha}` against the task, never to edit files, with findings in the reviewer schema.
- Findings file `runs/<RUN>/findings/<n>.json`, where `n` is the repair number (1 or 2): `{schema: 1, repair: n, source: "checks"|"final_checks"|"candidate"|"review"|"report"|"scope", checks: [failed or timed_out check results, with their log paths], scans: [failure scan matches], generated_changes: [paths], scope_violations: [paths], report_errors: [messages], failed_criteria: [criterion ids], findings: [critical and general reviewer findings]}`. Empty lists stay present.
- Stage request values: `report_path = runs/<RUN>/reports/<NN>-<name>.report.json` (the adapter writes the parsed report there); the normalized stage result is saved by the lifecycle as `runs/<RUN>/reports/<NN>-<name>.json`; `timeout_seconds = 2700` for every stage; `schema_path` = `P/resources/schemas/worker.schema.json` for worker and repair, `reviewer.schema.json` for the reviewer; `criterion_ids` = `task.criterion_ids` from the record for worker and repair, `[]` for the reviewer; `cwd` = the workspace path; `stdout_path`/`stderr_path` = `runs/<RUN>/logs/<NN>-<name>.stdout|.stderr`.
- Check context built by the lifecycle for the `checks` port (`run_checks(context, runner)`): `{root: workspace path, mode: "run", phase: "worker"|"final", base: base_sha, changes: diff.changed_files(workspace, base_sha, runner), config: config.load_config_file(runs/<RUN>/context/config.toml), options: {skip_groups, include_groups} from runs/<RUN>/context/plan.json, logs_dir: runs/<RUN>/logs/<NN>-<checks|final_checks>/}`. The checker builds its own plan from these. In `final_checks` the workspace HEAD is the candidate commit made by the `candidate` port, so the same diff against `base_sha` is the candidate's change.
- `cli.py` builds production ports for `pd start` and `pd resume`. The production `candidate`, `publish` and `cleanup` ports are `None` in this task; PLD-03-06 wires them.

Consumers: PLD-03-06 (fills the three ports and changes the unwired test), PLD-04-02 (skill calls `pd start` and `pd resume`), PLD-05-03 (live Codex smoke).

Execution route: **orchestrator** (see contracts "Runner boundary for this epic").

## Behavior

### `pd start --request PATH|-`

The request is read from the file, or from stdin for `-`. In this order, and nothing is written before step 5:

1. `contracts.validate_launch`; invalid or unreadable → exit 64, code `launch_invalid`.
2. `config.load_config(root)` (`needs_setup` or `config_invalid` pass through), then `selection.snapshot(root, config, runner, github)` and `selection.check_task(...)` for the request's `task_id` with executor `plan-dispatcher-v1`. Not eligible → exit 2, code `task_not_eligible`, with the reasons in `data`.
3. `preflight.doctor(root, config, adapters, runner)` with `adapters` limited to the request's worker and reviewer providers. Any blocker (including `artifact_missing`, `artifact_stale`, `gh_auth_missing`) → exit 2 with that code. Then the engine calls `adapter.describe([model])` for each role; a model marked `unavailable` → exit 2, code `model_unavailable`. `configured` and `verified` are accepted.
4. Generate the run ID and `reservations.reserve(root, run_id, task, invocation, busy)` with `busy` from step 2. Conflict → exit 2 `reservation_conflict`; nothing is written.
5. `state.new_run` writes `runs/<RUN>/run.json` with phase `preparing`. If this fails, `reservations.release(root, run_id, invocation)` runs before the error is raised.
6. `lifecycle.drive`.

### Phases

Each `step` runs one phase and saves the record.

| Phase | What happens | Next |
| --- | --- | --- |
| `preparing` | `workspace` port only (`prepare_workspace` does the clone, `freeze_context`, runtime and setup); its result is saved as `workspace` in the record at once, with `artifact = {version, wheel_sha256}` from `runtime.load_artifact(root)` | `working`; any error → `blocked` with its code |
| `working` | Fresh worker stage with `prompts/worker.md`, profile mode `write`, env `PLAN_DISPATCHER_RUN` and `PLAN_DISPATCHER_STATE` | see "Worker outcome" |
| `checking` | `checks` port in run mode, phase `worker`; scope check; change check | `candidate`, `repairing` or `blocked` |
| `repairing` | Fresh worker with `prompts/repair.md` and the findings file | see "Worker outcome" |
| `candidate` | `candidate` port; `None` → `pending_publication` with blocker `publication_unavailable` | `final_checks`, `repairing` or `blocked` |
| `final_checks` | `checks` port in run mode, phase `final`, at the candidate SHA | `reviewing`, `repairing` or `blocked` |
| `reviewing` | Fresh reviewer stage, profile mode `read`; before and after it, record `git status --porcelain=v1 --untracked-files=all` and `git rev-parse HEAD` | `publishing`, `repairing` or `blocked` |
| `publishing` | `publish` port | `cleaning`; any error → `blocked` with its code, no repair |
| `cleaning` | `cleanup` port | `done` (a cleanup warning keeps `done`) |

### Stage outcome rules

`repairs_used` counts repair attempts in total, at most 2. "Repair" below means: if `repairs_used < 2`, write the findings file, add 1 and go to `repairing` (or rerun the reviewer, see below); otherwise block with the listed code. Any repair throws away earlier final-check and review results.

Worker outcome (`working` and `repairing`), first match wins:

1. Engine interruption during the stage → block `interrupted`.
2. Result `timed_out`, or `provider_error` set → block `permission_denied` if `denied_actions` is not empty, else block `provider_error` (message names the adapter code, for example `timeout`, `output_missing`, `capability_fallback`). No repair.
3. `report_valid` false → block `permission_denied` if `denied_actions` is not empty, else repair with code `report_invalid`.
4. Report `blocked` not null → block `permission_denied` if `denied_actions` is not empty, else block `worker_blocked` (message includes the worker's question).
5. Otherwise → `checking`. The stage's `denied_actions` are kept as `pending_denials` for the checks that run directly after it. If those checks lead to any repair outcome (failed or timed-out check, scan, generated changes, failed criterion or `scope_violation`), block `permission_denied` instead of repairing. Denials are per stage: the next worker or repair stage replaces them, and a stage without denials clears them.

Checks (`checking` and `final_checks`), first match wins:

1. Any check with status `blocked`, or report `blocked` true → block `check_blocked`, no repair (a missing tool is a setup problem, not a code problem).
2. A check `failed` or `timed_out`, a failure-severity scan match, or `generated_changes` not empty → repair with code `checks_failed`.
3. `checking` only: a worker criterion with status `failed` → repair with code `checks_failed`. `not_verified` never blocks; it goes to the PR description.
4. `checking` only, scope: changed paths from `diff.changed_files(workspace, base_sha, runner)`. A path is allowed when `globs.match(pattern, path)` is true for some `touches` entry, or the entry has no wildcard and the path equals it or is below it, or the path is engine-owned: the task folder at its original path or under its parent's `done/`, the parent index file and the epic index file (PLD-03-06 rewrites links to the task in both). Any other path → repair with code `scope_violation`.
5. `checking` only: no changed path outside the engine-owned paths → block `no_change`.

Candidate port errors: `scope_violation` and `report_invalid` (bad commit subject) repair with that code; `no_change` blocks; any other code blocks.

Reviewer outcome, first match wins:

1. Engine interruption → block `interrupted`. `timed_out` or `provider_error` → block `provider_error`.
2. Status or HEAD changed during the stage → block `reviewer_mutated`, no repair, no reset.
3. `report_valid` false → rerun the reviewer once; this counts as a repair (`repairs_used += 1`, no worker runs, no findings file). A second invalid report, or no budget left, blocks `report_invalid`.
4. Any `critical` or `general` finding → repair with code `review_major`.
5. Otherwise → `publishing`. `minor` findings and `denied_actions` of the read-only stage are kept in the run reports for the PR description.

Every block sets `blocker = {code, message, phase}` (phase = the phase that failed), calls `reservations.mark(root, run_id, "blocked", code)` and keeps the clone. Nothing is pushed.

### Stages and interruption

- Before each stage: `stage_seq += 1`, `active_stage = {name, pid: os.getpid(), pgid: None, host: socket.gethostname(), started_at}`, save. The adapter for the stage is built per stage with `ports["get_adapter"](provider, StageRunner(ports["runner"], on_start))`; `StageRunner.run` forwards every call with `on_start`, and `on_start(child_pid)` sets `active_stage.pgid = child_pid` (the child starts its own session, so its PID is its process group ID) and saves the record. `run_state` then treats the stage as `active` while either `pid` or the `pgid` group is alive (`os.killpg(pgid, 0)` succeeds), so a SIGKILLed `pd` with a still-running provider is never resumed over.
- Worker and repair stages get `env = {"PLAN_DISPATCHER_RUN": run_id, "PLAN_DISPATCHER_STATE": <absolute state_dir>}`. Their `permission_profile.extra_write_dirs` contains only the frozen `policy.caches` paths that planned checks need; the state folder is never added, so the worker can read the frozen context (via `pd check --run`) but never change it. The worker's own check logs go to `<workspace>/.plan-dispatcher/local/check-logs/` (PLD-02-01, contracts "Checker"). The stage name is `worker`, `repair-<n>` or `reviewer`. After it: clear `active_stage`, save. Reports go to `reports/<NN>-<name>.json`, logs to `logs/<NN>-<name>.stdout|.stderr` (`NN` = `stage_seq`, two digits). Check runs also get a sequence number and save their check report as `reports/<NN>-checks.json` or `reports/<NN>-final_checks.json`. A stage report file holds the normalized stage result. Every report path is appended to `run.reports` in order, so PLD-03-06 can build the PR body from it.
- `drive` installs a SIGTERM handler that raises `KeyboardInterrupt` (only in the main thread) and restores the previous handler when it returns. `step` catches `KeyboardInterrupt` around the stage call, after the runner has stopped the child process group: it clears `active_stage`, blocks `interrupted` in the current phase, saves, and returns the record. `drive` then returns it, and the CLI exits 2.
- A crash leaves `active_stage` with a dead PID (`interrupted` state). Nothing reclaims it automatically.

### `pd resume RUN --invocation T`

- Refuses with exit 2: `run_active` (live stage), `invocation_mismatch` (other token, without `--adopt`), `run_done` (phase `done`), `run_released` (`run_state` is `released`).
- Revalidates: `config.load_config` of the project checkout, `doctor` with the run's two providers, `describe([model])` for each role (`unavailable` → `model_unavailable`), `git fetch <remote>`, `git merge-base --is-ancestor <base_sha> <remote>/<base_branch>` (else `base_moved`), and the remote task branch is absent or equals `publication.head_sha` (else `remote_head_unexpected`). A failure keeps the run `blocked` with the new code and blocker message.
- On success: `reservations.mark(root, run_id, "active", "resumed")` (a no-op when already active), clear `blocker`, set the phase to restart, save, `drive`.
- Restart phase: `blocker.phase` for most blocks. A block in `preparing` first deletes that run's partial clone (the path from `workspace.workspace_path(root, config, run_id)`, only when it resolves inside the cache root) and `runs/<RUN>/context/`, then reruns `preparing`; no worker work exists yet, so nothing is lost.
- `worker_blocked` needs `--answer TEXT` (else exit 64, code `answer_required`). The answer is written to a findings file `runs/<RUN>/findings/answer-<k>.json` = `{schema: 1, source: "answer", question, answer}` and the blocked phase reruns with `prompts/repair.md` pointing at it. An answer rerun does not add to `repairs_used`, because it fixes a missing decision, not a failure.
- `pending_publication` keeps the reservation `active` (it is never marked blocked, because the work is complete and only publication is missing), so `reservations.mark(..., "active", …)` on resume is a no-op for it. For an exhausted budget (`checks_failed`, `scope_violation`, `report_invalid`, `review_major`) it restarts `checking`, with no repair added, so fixes the user made by hand in the clone are checked; the same failure blocks again. For `interrupted` (in-process or crash), the interrupted phase reruns; an interrupted `repairing` keeps its repair number and does not add one. `pending_publication`, `candidate_changed` and `leak_detected` restart `candidate`, so a hand fix in the clone becomes a new candidate that is checked and reviewed again.

### Adoption: `pd resume RUN --invocation NEW --adopt --request PATH|-`

- Only for a run whose state is `blocked`, `interrupted` or `pending_publication`. The request must pass `validate_launch`, have the run's `task_id` and `invocation == NEW`. Missing or invalid → exit 64 `launch_invalid`; live stage → `run_active`.
- Replaces `invocation` and `launch` in the record (models and `auto_model` come only from the new request), calls `reservations.transfer(root, run_id, NEW)`, keeps workspace and reports, then revalidates and restarts as above.

### Output

`pd start` and `pd resume` return the contracts CLI envelope with `data = {run_id, phase, outcome, blocker, pr_url}` (`outcome` = `done`, `blocked` or `pending_publication`; `pr_url` null until published). Exit 0 for `done`, 2 for `blocked` or `pending_publication`, 64 for invalid input.

## Decisions

- One worker owns code and tests; a fresh reviewer checks the exact candidate; two repairs in total across checks and review (user decisions D12, D43 and the approved acceptance R9).
- Blocked work stays local with its reservation and is never WIP-pushed; recovery by another thread needs explicit adoption and fresh model approval (D16, D48, D49).
- The engine never picks or swaps a model; `auto_model` is an audit flag for this run only. This keeps R6's "scoped automatic selection" in the coordinator and avoids a dependency on PLD-04-02.
- A blocked check (missing executable) blocks at once, because a code repair cannot install a tool. Provider failures and timeouts block too, because a fresh worker would hit the same limit.
- The task summary and `criterion_ids` live in the run record so a resumed or adopted run checks evidence against the same acceptance list it started with, even if the task file changed on the base branch.
- A blocked worker's question is answered through `pd resume --answer`, so the answer is saved with the run and reaches a fresh worker without a session resume.
- An invalid reviewer report gets one rerun that counts against the shared budget, so a flaky reviewer cannot loop.
- Resuming an exhausted budget only rechecks, so a person can fix the clone by hand; the engine never adds budget.
- `not_verified` evidence is reported, not blocking, because the engine's own final checks and the independent review decide.
- Stage prompts are engine resources here, so one source defines what every worker and reviewer is told.

## Out of scope

- Archive, commit, push, PR and cleanup (PLD-03-06).
- Model recommendation and the dispatcher skill (PLD-04-02).
- Any app, UI or localization change, global agent settings, or helper scripts.

## Files and tests

Create `state.py`, `lifecycle.py` and the three prompt files. Extend `cli.py` and `tests/support.py`:

- `FakeAdapter(results: list[dict], describe_result: dict)`: returns scripted normalized results in order, records each request in `.requests`, and raises `KeyboardInterrupt` when a scripted entry is the string `"interrupt"`.
- `fake_checks(reports: list[dict])`: a `checks` port returning scripted check reports in order.
- `fake_ports(tmp, **overrides) -> dict`: all ten ports with fakes (workspace returns a real clone from `make_git_repo`).

`tests/test_lifecycle.py` (fakes plus a real temp Git repo):

- `test_happy_path_with_fake_ports_reaches_done`
- `test_repair_budget_is_shared_between_checks_and_review` (check fails, review major, review major again → exactly 2 repair workers, then `review_major`)
- `test_repair_discards_final_checks_and_review`
- `test_invalid_report_and_failed_criterion_spend_repair`
- `test_scan_failure_and_generated_changes_spend_repair`
- `test_blocked_check_blocks_without_repair`
- `test_not_verified_is_reported_not_blocking`
- `test_worker_blocked_and_provider_error_block_without_repair`
- `test_worker_timeout_and_output_missing_are_provider_error`
- `test_permission_denial_blocks_with_permission_denied`
- `test_reviewer_invalid_report_reruns_once_and_counts`
- `test_reviewer_mutation_blocks_without_repair`
- `test_minor_findings_are_kept`
- `test_scope_allows_touches_globs_and_engine_owned_paths`
- `test_scope_violation_and_no_change`
- `test_findings_file_lists_failures_and_major_findings`
- `test_prompts_render_only_known_placeholders`
- `test_interrupt_during_stage_keeps_state_and_reservation`
- `test_dead_pid_is_interrupted_and_resume_restarts_stage`
- `test_live_pgid_after_pd_killed_stays_active` (a fake record with a dead `pid` and a live process group from a real `sleep` child started with `start_new_session=True` → `run_state` is `active`, `pd resume` refuses `run_active`; the child is killed in teardown)
- `test_worker_env_and_profile_exclude_state_dir` (the worker stage request has both env vars, and no `extra_write_dirs` entry is inside the state folder)
- `test_prompt_includes_commit_subject_pattern`
- `test_leftover_tmp_removed_and_corrupt_record_kept`
- `test_resume_marks_active_and_clears_blocker`
- `test_resume_after_preparing_failure_discards_partial_clone`
- `test_worker_blocked_resume_needs_answer_and_passes_it` (no `--answer` → 64 `answer_required`; with it, the findings file holds the answer and `repairs_used` is unchanged)
- `test_pending_publication_keeps_reservation_active`
- `test_denials_apply_only_to_following_checks`
- `test_stage_request_paths_timeout_schema_and_criterion_ids`
- `test_check_context_uses_frozen_config_and_base_sha`
- `test_resume_after_exhausted_budget_rechecks_without_repair`
- `test_resume_revalidates_and_refuses_moved_base`
- `test_resume_refuses_done_released_and_active`
- `test_resume_with_other_invocation_is_refused`
- `test_adoption_needs_inactive_run_and_new_request`
- `test_adoption_takes_models_and_auto_model_from_new_request`
- `test_unavailable_explicit_model_refused_without_record`
- `test_start_reservation_conflict_writes_nothing`
- `test_start_and_resume_output_and_exit_codes` (0 done, 2 blocked and pending, 64 invalid; `--request -` from stdin)
- `test_unwired_ports_stop_at_pending_publication` (injected `None` ports, and the production CLI ports in this task)

Commands, from the repository root:

- `python3 tool/plan_dispatcher/tests/run_tests.py test_lifecycle test_workspace test_claude test_codex test_antigravity`
- `fvm dart tool/agent_check.dart`
- `fvm flutter test`

No app launch, device test, golden or ARB change. Do not report a check as passed without running it.

## Acceptance

- [ ] When checks and review both need repairs, then exactly two repairs run in total and every new candidate is checked and reviewed again. Check: `test_repair_budget_is_shared_between_checks_and_review`, `test_repair_discards_final_checks_and_review`, `test_reviewer_invalid_report_reruns_once_and_counts`.
- [ ] When a stage result is a provider error, timeout, blocked check, worker block, denial or reviewer mutation, then the run blocks without a repair and with the listed code. Check: `test_worker_blocked_and_provider_error_block_without_repair`, `test_worker_timeout_and_output_missing_are_provider_error`, `test_blocked_check_blocks_without_repair`, `test_permission_denial_blocks_with_permission_denied`, `test_reviewer_mutation_blocks_without_repair`.
- [ ] When the worker changes a path outside `touches` and the engine-owned task paths, or nothing at all, then the run repairs `scope_violation` or blocks `no_change`. Check: `test_scope_allows_touches_globs_and_engine_owned_paths`, `test_scope_violation_and_no_change`.
- [ ] When a major issue remains or a stage is interrupted, then the record, clone and reservation stay local and `pd resume` restarts the right phase after revalidation. Check: `test_interrupt_during_stage_keeps_state_and_reservation`, `test_dead_pid_is_interrupted_and_resume_restarts_stage`, `test_resume_marks_active_and_clears_blocker`, `test_resume_after_exhausted_budget_rechecks_without_repair`, `test_resume_revalidates_and_refuses_moved_base`.
- [ ] When another conversation wants the run, then only `--adopt` with a new approved request on an inactive run transfers it, and models come from that request. Check: `test_resume_with_other_invocation_is_refused`, `test_adoption_needs_inactive_run_and_new_request`, `test_adoption_takes_models_and_auto_model_from_new_request`.
- [ ] When an explicit model is unavailable or the task is reserved, then `pd start` refuses and writes no record or reservation. Check: `test_unavailable_explicit_model_refused_without_record`, `test_start_reservation_conflict_writes_nothing`.
- [ ] When a run blocks in preparation or on a worker question, then `pd resume` discards the partial clone or requires `--answer` and passes it to a fresh worker without spending a repair. Check: `test_resume_after_preparing_failure_discards_partial_clone`, `test_worker_blocked_resume_needs_answer_and_passes_it`.
- [ ] When `pd start` or `pd resume` ends, then the envelope data and exit code match the outcome. Check: `test_start_and_resume_output_and_exit_codes`.
- [ ] When publication ports are not wired, then the run stops at `pending_publication` with `publication_unavailable` and exit 2. Check: `test_unwired_ports_stop_at_pending_publication`.
