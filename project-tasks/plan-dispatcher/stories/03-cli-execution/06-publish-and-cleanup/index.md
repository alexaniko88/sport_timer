---
id: PLD-03-06
status: draft
type: feat
complexity: high
executor: orchestrator
depends-on: [PLD-03-05]
touches:
  - tool/plan_dispatcher/src/plan_dispatcher/archive.py
  - tool/plan_dispatcher/src/plan_dispatcher/publication.py
  - tool/plan_dispatcher/src/plan_dispatcher/cleanup.py
  - tool/plan_dispatcher/src/plan_dispatcher/github.py
  - tool/plan_dispatcher/src/plan_dispatcher/lifecycle.py
  - tool/plan_dispatcher/src/plan_dispatcher/state.py
  - tool/plan_dispatcher/src/plan_dispatcher/cli.py
  - tool/plan_dispatcher/tests/test_publication.py
  - tool/plan_dispatcher/tests/test_cleanup.py
  - tool/plan_dispatcher/tests/test_portable_flow.py
  - tool/plan_dispatcher/tests/test_lifecycle.py
  - tool/plan_dispatcher/tests/support.py
  - tool/plan_dispatcher/tests/fixtures/sample_consumer/**
skills: []
---

# Assemble reviewed publication, archiving and cleanup

Story: [CLI execution and reviewed publication](../index.md)

Epic: [PlanDispatcher](../../../index.md)

## Goal

Fill the lifecycle's `candidate`, `publish` and `cleanup` ports so a run ends as one reviewed commit on the task branch with one PR, and the clone is removed after success. Prove the whole flow on a temporary sample consumer with a real local bare remote and a fake GitHub.

## Context

- Today's `tool/dispatcher/task_archiver.dart`, `git_publisher.dart` and `launch_pipeline.dart` archive after review (so the pushed head differs from the reviewed one) and push WIP on failure. Read them only to avoid both bugs.
- Cross-task shapes are owned by [contracts.md](../../../contracts.md) and are not restated here: "Candidate, publication and cleanup" (function signatures, return shapes, publication step names), "GitHub boundary", "Local state and reservations" and "Launch request and run record" (run record, blocker codes, ports).
- Stage outcome handling (which candidate and publish errors repair or block) is fixed in [PLD-03-05](../05-task-lifecycle/index.md) "Stage outcome rules": candidate `scope_violation` and `report_invalid` repair, every other candidate or publish error blocks.
- Prerequisite: [PLD-03-05](../05-task-lifecycle/index.md) (phases, ports, stops at `pending_publication`). Shared requirements: R8, R9, R12, R13, R14, R18.

## Contract

Provided here, public shapes in contracts "Candidate, publication and cleanup": `archive.prepare_candidate(root, run, runner)`, `publication.publish_candidate(root, run, candidate, runner, github)`, `cleanup.cleanup_run(root, run_id, runner, cache_root=None)`, `GhCli.create_pr`, and the CLI row `pd cleanup RUN` (`P` = `tool/plan_dispatcher/src/plan_dispatcher/`). `root` is the project checkout. Both signatures, with `root`, are fixed in contracts "Candidate, publication and cleanup".

Inputs both functions read, never from the workspace's own files: the frozen config `<state_dir>/runs/<run_id>/context/config.toml` (via `config.load_config_file`; `policy`, `project.remote`, `project.github_repo`) and the run record's `task` summary `{id, title, type, touches, path, criterion_ids}` (PLD-03-05) and `workspace`, `base_sha`, `launch`, `reports`.

Private to this task:

- `P/lifecycle.py` and `P/cli.py`: the production `candidate`, `publish` and `cleanup` ports become these functions. The `cleanup` port is a closure that passes the same `cache_root` the `workspace` port used. The lifecycle stores the candidate result in the run record field `candidate` (contracts "Run record") right after the `candidate` phase, so `publishing` can verify after a crash or resume.
- `P/state.py`: writes `publication.steps` (the contract step names, in order) and `cleanup`.
- `tests/support.py`: `FakeGitHub` gains `remote: Optional[Path] = None` and `lose_create_reply: bool = False`. With `remote` set, `open_prs` and `find_pr` fill each PR's `head_sha` from `git --git-dir <remote> rev-parse refs/heads/<head>` at call time (missing branch → `head_sha: None`). `lose_create_reply=True` creates the PR and then raises `PdError("github_unavailable")`; `make_consumer_repo(tmp, template: Path) -> Path` copies the template into `<tmp>/consumer`, runs `git init -b main`, sets a repo-local identity (`git config user.name pd-test`, `git config user.email pd-test@users.noreply.github.com`, because CI runners have none), commits, creates the bare remote `<tmp>/consumer-remote`, pushes `main`, sets `origin/HEAD`, and returns the checkout path (its `github_repo` is `local/consumer-remote`, per contracts `parse_github_repo`).

Consumers: PLD-04-02 (skill shows results), PLD-05-01 (cutover), PLD-06-02 (release fixture).

Execution route: **orchestrator** (see contracts "Runner boundary for this epic").

## Behavior

Candidate (phase `candidate`, run again after each repair; the repair worker works on the tree that already holds the previous archive, and the worker prompt forbids editing the task folder):

1. In the workspace, `git reset --soft <base_sha>` so there is always exactly one commit on top of base.
2. Archive this task only. The archived files are always rendered from the base versions, so running this step again gives the same result:
   - If the old folder `<parent>/<folder>` still exists in the worktree, `git mv <parent>/<folder> <parent>/done/<folder>` (attachments such as `mockup.html` move with it).
   - `<parent>/<folder>` comes from the record's `task.path`. Write `<parent>/done/<folder>/index.md` from `git show <base_sha>:<parent>/<folder>/index.md` with `status: ready` replaced by `status: done` and one `../` added to every relative Markdown link target that leaves the task folder (links starting with `http`, `#` or `/` are left alone).
   - Write `<parent>/done/<folder>/notes.md` from the latest valid worker report: `## Summary`, `## Evidence` (one line per criterion: id, status, check ids, details), `## Open notes`. Its links are written for the `done/` location from the start.
   - Write the parent index from `git show <base_sha>:<parent index>`, with every link target `<folder>/index.md` (or `./<folder>/index.md`) replaced by `done/<folder>/index.md` (a story index links a task from its task list and its coverage rows). Then do the same in the epic index `<backlog>/<epic>/index.md` for every link target `stories/<story>/<folder>/index.md`. Nothing else in either file changes. A parent index without such a link is left as is and a warning is added to the candidate result. Standalone `bugs/` and `improvements/` tasks have no epic index.
3. Scope check with the same rule as PLD-03-05 "Checks" step 4, using the record's `task.touches`: `touches` globs, plus the engine-owned paths (old and `done/` task folder, parent index file, epic index file). Anything else → `scope_violation`.
4. `git add -A`, then commit with the latest valid worker report's `commit_subject` (must match `policy.commit_subject_pattern`, else `report_invalid`), plus a blank line and `attribution_template` filled with `{tool}` = `run.launch.worker.provider` and `{model}` = `run.launch.worker.model` when the template is set. Repairs use the same launch settings, so these never come from a report. Author from the workspace Git identity.
5. `tree_digest = git rev-parse <sha>^{tree}`; empty diff from base → `no_change`.

Publication (phase `publishing`; each step is saved in `publication.steps` before the next starts; a retry skips saved steps):

1. `verify`: workspace `HEAD` and tree must equal the reviewed candidate, and `git status --porcelain` must be empty; else `candidate_changed` (blocked). On `pd resume` this code restarts `candidate` (PLD-03-05), so a changed tree becomes a new candidate with fresh final checks and review.
2. `leak_scan`: `policy.leak_scans` from the frozen config over added lines of `git diff <base_sha> <sha>` (`checks.scan_lines`); a match → `leak_detected` (blocked, evidence is path and line only). On resume it also restarts `candidate`.
3. `remote_check`: branch must not equal the base branch (`base_branch_push`). `git ls-remote <remote> refs/heads/<branch>`: absent or equal to `sha` continues. Any other head, including an ancestor of the candidate, → `remote_head_unexpected` (blocked). The engine never fast-forwards over an unknown head.
4. `pushed`: `git push <remote> <sha>:refs/heads/<branch>`; no `--force` or `+` refspec ever. If the push call fails, `ls-remote` is checked again: equal to `sha` counts as pushed.
5. `pr_found_or_created`: `find_pr(repo, branch, base)`; if none, `create_pr` with title from `pr_title_template` (`{type}`, `{title}` from the task) and the body below. If `create_pr` fails, `find_pr` is called again before any retry, so a lost reply never makes a second PR.

   PR body, built from the run record and the reports listed in `run.reports` (the last valid worker or repair report, the last `final_checks` report and the last reviewer report):

   ```text
   ## Task
   <ID>: <title> (`<task path at base>`)

   ## Summary
   <worker report summary>

   ## Acceptance evidence
   - <criterion id> <status> (<check ids, comma separated>): <details>

   ## Final checks
   - <check id>: <status>

   ## Minor review notes
   - <file>:<line or "-"> <summary>
   ```

   An empty list prints `- None`. No local paths, logs or tokens go into the body.
6. `confirmed`: `find_pr` returns the PR and its `head_sha` equals `sha`.

Cleanup (phase `cleaning`, and `pd cleanup RUN`):

- `cleanup_run(root, run_id, runner, cache_root=None)`; `cache_root` defaults to the contracts default, the lifecycle passes the workspace port's value, and `pd cleanup` uses the default.
- Allowed only when publication is `confirmed`, the run has no live `active_stage`, and the resolved workspace path is inside `<cache_root>/workspaces/` (checked with `Path.resolve()` against the passed or default root, never against a value read from the record). Otherwise refuse: `run_not_published`, `run_active` or `workspace_outside_cache` (exit 2).
- Removes the clone, removes the reservation with `reservations.release(root, run_id, run["invocation"])` (the remote branch and PR keep the task busy), keeps `runs/<RUN>/`. On a retry, a clone that is already gone and a reservation that is already released (`unknown_run`) both count as done, not as errors.
- Then deletes old wheels: every folder under `<root>/.plan-dispatcher/local/artifacts/` whose wheel's SHA256 is neither the current `artifact.json` `wheel_sha256` nor the `artifact.wheel_sha256` of any run record under `runs/` is removed. A deletion error only adds a warning. A removal error returns `{removed: false, warning}`, the run stays `done` with `cleanup.state = "failed"`, and `pd start` still exits 0 with the warning. `pd cleanup RUN` retries without republishing.

Errors before publication keep the clone and reservation and push nothing. The engine never merges, force-pushes, deletes remote branches or posts comments.

## Decisions

- Archive and notes are part of the reviewed commit, so the pushed SHA is the reviewed SHA (D45 split review; fixes the current post-review archive bug).
- An existing remote head that is not the candidate always blocks, even an ancestor, because the engine cannot tell an earlier attempt from someone else's work.
- Successful runs are cleaned automatically; a cleanup failure never turns a published PR into a failure (D27).

## Out of scope

- Stage logic and repair rules (PLD-03-05), installer and update.
- Any app, UI or localization change, global settings, helper scripts.

## Files and tests

Fixture consumer `tests/fixtures/sample_consumer/`: a tiny repo template with `docs/tasks/demo/index.md` (epic `abbr: DEM`), one story `docs/tasks/demo/stories/01-basics/index.md` linking its tasks, and two ready tasks (`DEM-01-01` touching `calc.py` and `test_calc.py`, executor `plan-dispatcher-v1`; `DEM-01-02` depending on it), `calc.py`, `test_calc.py`, `AGENTS.md`, and a complete `.plan-dispatcher/config.toml` (contracts "Configuration schema 1"): `project = {name = "demo", backlog = "docs/tasks", remote = "origin", base_branch = "auto", github_repo = "local/consumer-remote"}`, `distribution` with `source_kind = "local"` and `content_digest = "sha256:pending"`, `integrations.tools = ["codex"]`, `instructions.paths = ["AGENTS.md"]`, no setup commands, one file set `py` (`include = ["*.py"]`), one check `unit` (`argv = ["python3", "-m", "unittest", "test_calc"]`, `trigger_any = []`), no scans, an empty policy except `commit_subject_pattern = "^(feat|fix): \\S"`, and one worker and one reviewer `codex` candidate. Tests build it with `support.make_consumer_repo`, and use fake worker/reviewer adapters (scripted file edits and reports), a test artifact from PLD-03-01's `build_test_artifact`, and `FakeGitHub`.

`test_publication.py`:

- `test_archive_is_inside_reviewed_sha`
- `test_pushed_sha_equals_reviewed_and_reported_sha`
- `test_change_after_final_checks_is_refused` (inject a tracked edit after review → `candidate_changed`)
- `test_new_candidate_after_repair_is_one_commit`
- `test_lost_push_reply_is_reconciled` (push succeeds, runner then raises; retry sees head = sha)
- `test_lost_pr_reply_reuses_existing_pr` (`lose_create_reply=True`; exactly one PR)
- `test_unexpected_or_ancestor_remote_head_blocks`
- `test_no_force_push_argv_and_base_branch_refused`
- `test_leak_scan_blocks_before_push`
- `test_archive_is_rendered_from_base_and_idempotent` (two candidates in a row give the same archived files; links shifted once)
- `test_archive_updates_parent_and_epic_links_only` (every link to the task in both indexes moves to `done/`; no other line changes)
- `test_scope_allows_parent_and_epic_index_and_task_folders`
- `test_publication_resumes_from_saved_steps` (crash after `pushed` and after `pr_found_or_created`; resume skips them and verifies the stored `candidate`)
- `test_pr_body_layout` (exact headings, `- None` for empty lists, no absolute paths)
- `test_inputs_come_from_frozen_config_and_record` (editing the workspace `config.toml` and task file after launch changes nothing in the commit subject check, leak scan or PR title)
- `test_commit_attribution_uses_launch_worker`
- `test_candidate_changed_and_leak_restart_at_candidate` (resume after each code runs `candidate`, `final_checks` and `reviewing` again)

`test_cleanup.py`: `test_cleanup_failure_returns_warning_and_retry_works` (patched `shutil.rmtree` raises once), `test_cleanup_refuses_unpublished_active_or_outside_cache`, `test_cleanup_retry_with_missing_clone_or_reservation_succeeds`, `test_cleanup_deletes_unreferenced_old_wheels` (three wheel folders: current, referenced by a blocked run record, unreferenced → only the last is removed).

`test_portable_flow.py`: `test_full_flow_on_fixture_consumer` (select → reserve → prepare → worker → checks → candidate → final checks → review → push → PR → cleanup; asserts one PR, branch head = reviewed SHA, clone removed, temp folder removed by `tearDown`), `test_blocked_run_resumes_on_fixture_consumer` (the first fake worker result is a report with `blocked` set → run `blocked` with `worker_blocked`; `pd resume --answer "use integers"` with the same invocation restarts `working`, the second scripted result is valid, and the run reaches `done` with one PR).

`test_lifecycle.py`: change `test_unwired_ports_stop_at_pending_publication` so it only uses injected `None` ports, and add `test_production_ports_are_wired` (the CLI's ports for `candidate`, `publish` and `cleanup` are the new functions).

Commands, from the repository root:

- `python3 tool/plan_dispatcher/tests/run_tests.py test_publication test_cleanup test_portable_flow test_lifecycle`
- `fvm dart tool/agent_check.dart`
- `fvm flutter test`

No network, models, app launch, goldens or ARB changes.

## Acceptance

- [ ] When a task is published, then the archive and notes are in the reviewed commit and the reviewed, pushed and reported SHAs are the same. Check: `test_archive_is_inside_reviewed_sha`, `test_pushed_sha_equals_reviewed_and_reported_sha`, `test_change_after_final_checks_is_refused`.
- [ ] When a push or PR reply is lost, then a retry reconciles with the remote and never creates a second PR or overwrites a head. Check: `test_lost_push_reply_is_reconciled`, `test_lost_pr_reply_reuses_existing_pr`, `test_unexpected_or_ancestor_remote_head_blocks`, `test_no_force_push_argv_and_base_branch_refused`.
- [ ] When publication succeeds but deleting the clone fails, then the PR is reported with a cleanup warning and `pd cleanup` retries safely, and old wheels no run uses are removed. Check: `test_cleanup_failure_returns_warning_and_retry_works`, `test_cleanup_refuses_unpublished_active_or_outside_cache`, `test_cleanup_retry_with_missing_clone_or_reservation_succeeds`, `test_cleanup_deletes_unreferenced_old_wheels`.
- [ ] When the workspace config or task file is edited after launch, or publication blocks on a changed tree or leak, then publication uses only frozen inputs and a resume builds a new reviewed candidate. Check: `test_inputs_come_from_frozen_config_and_record`, `test_candidate_changed_and_leak_restart_at_candidate`.
- [ ] When the temporary sample consumer runs the full flow, then it finishes using only its configured check and is removed afterward. Check: `test_full_flow_on_fixture_consumer`, `test_blocked_run_resumes_on_fixture_consumer`.
