---
id: PLD-05-03
status: draft
type: feat
complexity: medium
executor: orchestrator
depends-on: [PLD-05-02]
touches:
  - tool/agent_check.dart
  - test/tool/agent_check_test.dart
  - .agents/skills/skill-orchestrator/SKILL.md
  - .agents/skills/skill-pr-feedback/SKILL.md
  - .agents/references/plan-dispatcher-project.md
  - CLAUDE.md
  - tool/plan_dispatcher/tests/live_codex_smoke.py
  - tool/plan_dispatcher/README.md
  - .plan-dispatcher/config.toml
  - .plan-dispatcher/managed.json
  - docs/tasks/bugs/01-ios-auth-dependency-conflict/**
  - docs/tasks/developer-tools/stories/01-purge-local-activity/01-purge-activity-storage/**
  - docs/tasks/developer-tools/stories/01-purge-local-activity/02-add-developer-page/**
  - docs/tasks/improvements/05-add-shared-app-tag/**
  - docs/tasks/statistics/stories/06-record-partial-activity/01-count-partial-progress/**
  - docs/tasks/statistics/stories/06-record-partial-activity/02-save-on-leaving-timer/**
  - docs/tasks/statistics/stories/06-record-partial-activity/03-checkpoint-and-recover/**
  - docs/tasks/ui-refactor/stories/05-statistics-ui-refactor/01-rethink-statistics-cards-and-details/**
  - docs/tasks/plan-dispatcher/stories/05-sport-timer-cutover/index.md
  - docs/tasks/plan-dispatcher/stories/05-sport-timer-cutover/03-retire-dart-validator/**
  - docs/tasks/plan-dispatcher/stories/05-sport-timer-cutover/done/03-retire-dart-validator/**
skills: []
---

# Retire the Dart validator after parity and live CLI proof

Story: [Sport Timer cutover](../index.md)

Epic: [PlanDispatcher](../../../index.md)

## Goal

Prove the real Codex route once with a live smoke run on a throwaway framework-neutral fixture, plus one real check of this project inside the Codex sandbox,, then delete `tool/agent_check.dart` and its Dart tests and point every developer instruction to `pd check`. It also moves the existing `ready` Sport Timer tasks to the new engine (decision D56). If the live smoke or parity fails, nothing is deleted.

## Context

- The backlog is at `docs/tasks/` ([PLD-05-02](../02-move-task-backlog/index.md)); the packaged skills are installed and `.plan-dispatcher/venv/bin/pd` exists ([PLD-05-01](../01-switch-workflow-engine/index.md)). The Python parity test and its JSON case table ([PLD-02-02](../../02-shared-validation/02-sport-timer-check-parity/index.md)) stay and are not changed here.
- Live mentions of the old validator after PLD-05-01 (verify with the `git grep` command below before editing):

  | File | Mention | Replacement |
  | --- | --- | --- |
  | `CLAUDE.md` "Commands" code block | `fvm dart tool/agent_check.dart # only the checks the changed files need` | `.plan-dispatcher/venv/bin/pd check # only the checks the changed files need` |
  | `CLAUDE.md` paragraph after the block | `tool/agent_check.dart` compares with `master`, `--base=<branch>`, `--skip-build`, file paths, `ChangeSet`, `test/tool/agent_check_test.dart` | `pd check` compares with `origin/master` (`--base REF` changes it, `--skip-build` skips the `build` group, or pass file paths); the rules are in `.plan-dispatcher/config.toml` and the parity cases in `test/tool/fixtures/plan_dispatcher_check_cases.json`, tested by `test/tool/test_plan_dispatcher_parity.py`. Keep the sentences that `pd check` adds to, and does not replace, the full `fvm flutter test` run, and that domain/data changes still need the snapshot test by hand. |
  | `.agents/skills/skill-orchestrator/SKILL.md` Stage 5 (`fvm dart tool/agent_check.dart` passes …) | old command | `.plan-dispatcher/venv/bin/pd check` passes, same wording about what it picks |
  | `.agents/skills/skill-pr-feedback/SKILL.md` Step 3.1 | `Run fvm dart tool/agent_check.dart` | `Run .plan-dispatcher/venv/bin/pd check` |
  | `.agents/references/plan-dispatcher-project.md` | only if PLD-05-01 left a mention | `pd check` |
  | `tool/agent_check.dart`, `test/tool/agent_check_test.dart` | the validator and its tests | deleted |
  | The six pending tasks listed below | `fvm dart tool/agent_check.dart` in `Check:` lines and commands | `.plan-dispatcher/venv/bin/pd check`, keeping `--skip-build` and file-path arguments; `--base=<b>` becomes `--base <b>` |

- Pending tasks in other epics name the validator as a check (found with `git grep -l agent_check` on 2026-11-08, shown at their post-move paths). Without a rewrite, a later run of these tasks would call a deleted file:
  - `docs/tasks/developer-tools/stories/01-purge-local-activity/01-purge-activity-storage/index.md`
  - `docs/tasks/developer-tools/stories/01-purge-local-activity/02-add-developer-page/index.md`
  - `docs/tasks/improvements/05-add-shared-app-tag/index.md`
  - `docs/tasks/statistics/stories/06-record-partial-activity/02-save-on-leaving-timer/index.md`
  - `docs/tasks/statistics/stories/06-record-partial-activity/03-checkpoint-and-recover/index.md`
  - `docs/tasks/ui-refactor/stories/05-statistics-ui-refactor/01-rethink-statistics-cards-and-details/index.md`
  Only those command strings change; no requirement, status or other text in these tasks changes. Re-run `git grep -l agent_check -- docs/tasks ':(exclude,glob)docs/tasks/**/done/**' ':(exclude,glob)docs/tasks/planning/**' ':(exclude,glob)docs/tasks/plan-dispatcher/**' ':(exclude,glob)**/notes.md'` before editing; if it lists a pending task not named here, rewrite it the same way and add it to `notes.md`.
- Files that must keep naming the validator, excluded from the final scan with a reason: `tool/plan_dispatcher/tests/test_planner.py` (its forbidden-strings list contains the literal, PLD-04-01), `test/tool/test_plan_dispatcher_parity.py` and `test/tool/fixtures/plan_dispatcher_check_cases.json` (each case names the Dart test it was copied from, PLD-02-02), `.plan-dispatcher/config.toml` (comments that say which old rule each check mirrors, PLD-02-02). If any other live file outside `docs/tasks/` still names it, it is replaced, not excluded.

- Existing `ready` Sport Timer tasks outside this epic (found with `grep -rl "^status: ready"` on 2026-11-08, shown at their post-move paths). They have no `executor`, so they count as `legacy`, and PLD-05-01 removed the legacy runner. Decision D56: set `executor: plan-dispatcher-v1` on each and check it.

  | ID | Folder |
  | --- | --- |
  | BUG-01 | `docs/tasks/bugs/01-ios-auth-dependency-conflict/` |
  | DEV-01-01 | `docs/tasks/developer-tools/stories/01-purge-local-activity/01-purge-activity-storage/` |
  | DEV-01-02 | `docs/tasks/developer-tools/stories/01-purge-local-activity/02-add-developer-page/` |
  | IMP-05 | `docs/tasks/improvements/05-add-shared-app-tag/` |
  | STAT-06-01 | `docs/tasks/statistics/stories/06-record-partial-activity/01-count-partial-progress/` |
  | STAT-06-02 | `docs/tasks/statistics/stories/06-record-partial-activity/02-save-on-leaving-timer/` |
  | STAT-06-03 | `docs/tasks/statistics/stories/06-record-partial-activity/03-checkpoint-and-recover/` |
  | UI-05-01 | `docs/tasks/ui-refactor/stories/05-statistics-ui-refactor/01-rethink-statistics-cards-and-details/` |

  Before editing, re-run `grep -rl "^status: ready" docs/tasks --include=index.md` excluding `docs/tasks/plan-dispatcher/`, `done/` and `planning/`; a ready task not listed here is handled the same way and named in `notes.md`.

- `.github/workflows/ci.yml` runs only `flutter analyze` and `flutter test`; it never ran the validator, so no CI file changes. The live smoke is never added to CI.
- Read [the epic contracts](../../../contracts.md) headings "Stage protocol", "Launch request and run record", "Candidate, publication and cleanup" and "Workspace, runtime and doctor" (`parse_github_repo` local form).
- The package-boundary test in `test/tool/test_plan_dispatcher_parity.py` (PLD-02-02) scans all of `tool/plan_dispatcher/` with the patterns in `test/tool/fixtures/plan_dispatcher_boundary_patterns.txt`. The new `live_codex_smoke.py` and README section are inside that scan and must pass it: they say "consumer config", never name this project, its framework or its paths.

## Contract

New here: `tool/plan_dispatcher/tests/live_codex_smoke.py`. It is generic package test code (no Sport Timer paths), not a `test_*` module, so `run_tests.py` never discovers it.

```text
python3 tool/plan_dispatcher/tests/live_codex_smoke.py --config PATH [--provider codex] [--report PATH] [--keep]
```

- `--config`: a consumer config; only its `[[models.candidates]]` are read. For each role (`worker`, `reviewer`) the smoke takes the candidates with `provider = "codex"` and that role, keeps those with `complexity = "low"` (the fixture task's complexity), falls back to `complexity = "any"` when there are none, and picks the lowest `rank` (ties: the first in file order). No match for a role → exit 2. `--provider` accepts `claude`, `codex` or `antigravity` (default `codex`); only codex is a required gate here.
- It imports the package from `src/` next to its own folder.
- Fixture, all inside `tempfile.mkdtemp(prefix="pd-live-smoke-")`:
  - a bare repo folder named `smoke` (so `parse_github_repo` gives `local/smoke`) as `origin`, default branch `main`;
  - a work repo with `calc.py` (`def add(a, b):\n    return a + b\n`), `test_calc.py` (one `unittest` case for `add`) and a `.gitignore` containing exactly `__pycache__/\n.plan-dispatcher/venv/\n.plan-dispatcher/local/\n`, so the check's bytecode never shows up as a change or a scope violation;
  - `pd-source/`: a copy of this package's `pyproject.toml`, `build_backend/` and `src/` (without `__pycache__`), committed in the work repo, so the config can name a repo-relative local source;
  - the task file `docs/tasks/demo/stories/01-demo/01-add-subtract/index.md`, exactly:

    ```markdown
    ---
    id: DEM-01-01
    status: ready
    type: feat
    complexity: low
    executor: plan-dispatcher-v1
    depends-on: []
    touches:
      - calc.py
      - test_calc.py
    ---

    # Add subtract

    ## Goal

    Add `subtract(a, b)` to `calc.py` and test it.

    ## Acceptance

    - [ ] When `subtract(5, 3)` is called, then it returns 2. Check: `python3 -m unittest test_calc`.
    - [ ] When the tests run, then `add` and `subtract` both have a test. Check: `python3 -m unittest test_calc`.
    ```

    plus a one-line epic index `docs/tasks/demo/index.md` (`---\nabbr: DEM\n---\n\n# Demo`) and a story index `docs/tasks/demo/stories/01-demo/index.md` linking the task, so the archive step can rewrite the parent link;
  - `.plan-dispatcher/config.toml` (schema 1): `project = {name = "smoke", backlog = "docs/tasks", remote = "origin", base_branch = "main", github_repo = "local/smoke"}`, `distribution = {source_kind = "local", source = "pd-source", source_ref = "", source_commit = "", content_digest = runtime.content_digest(<work>/pd-source), version = <version from pd-source/pyproject.toml>}` (a repo-relative source inside the fixture, so `doctor` does not report `artifact_stale`), `integrations.tools = ["codex"]`, `instructions.paths = []`, no setup commands, one file set `py` (`include = ["*.py"]`), one check `tests` (`argv = ["python3", "-m", "unittest", "test_calc"]`, `trigger_any = []`, `phases = ["worker", "final"]`), no scans, `policy` with `commit_subject_pattern = "^feat: \\S"` and every other field empty, and the two codex candidates copied from `--config`;
  - all of it committed and pushed to `smoke` as the base commit. Then the wheel is built with `wheel.build_wheel(<work>/pd-source, <work>/.plan-dispatcher/local/artifacts/<version>-<first 12 hex of the digest>/)` and `<work>/.plan-dispatcher/local/artifact.json` is written (contracts "Workspace, runtime and doctor": absolute `wheel_path`, its SHA256, `source_kind = "local"`, `source = "pd-source"`, the same digest). `cache_root` is inside the temp folder.
- Preflight: before any run, `preflight.doctor(<work>, config, {"codex": get_adapter("codex", runner)}, runner)`. Any blocker → exit 2, with the blockers in the report.
- Launch request (contracts "Launch request and run record"): `task_id = "DEM-01-01"`, a generated `inv-` token, `approved = true`, `selection = "named"`, `auto_model = false`, `host = {kind: "unknown", thread_id: null}`, and `worker`/`reviewer` = the codex candidates chosen above.
- Cache route: the smoke makes a fresh folder `~/.pd-live-smoke-cache-<8 hex>` before the run and always deletes it afterward. The fixture config adds `policy.caches = [{id = "smoke-cache", path = "~/.pd-live-smoke-cache-<8 hex>"}]` and a second check `cache-write` (`argv = ["python3", "write_cache.py"]`, `trigger_any = []`, `phases = ["worker", "final"]`, `needs = ["smoke-cache"]`). The committed fixture file `write_cache.py` (added to the fixture's base commit next to `calc.py`; not in the task's `touches`) holds the line `CACHE = "~/.pd-live-smoke-cache-<8 hex>"`, expands it with `os.path.expanduser`, and writes `worker.txt` there when the environment has `PLAN_DISPATCHER_RUN` (a worker's `pd check`, contracts "Checker"), else `engine.txt`. So the worker's own check must write outside the clone through the sandbox's extra writable folder.
- Run: in-process `state.new_run` + `lifecycle.drive` with real `SubprocessRunner`, the real Codex adapter, real workspace, runtime, checks, candidate, publish (push to the bare remote) and cleanup, and `FakeGitHub` from `support.py` for PR lookup and creation. Stage timeout 900 s.
- Pass (exit 0): final phase `done`; `<cache>/worker.txt` exists (the worker's sandboxed check wrote to the cache folder); worker report valid with every criterion `passed`; final checks `ok`; reviewer report valid; `denied_actions` empty in every stage; the bare remote branch head equals `publication.head_sha`; `FakeGitHub` holds exactly one PR.
- Fail (exit 1): any other end state. Prerequisite missing (exit 2): `codex` not found, `codex login status` non-zero, a doctor blocker for codex, or no codex candidate in the config. Usage error: exit 64. For this task, exit 1 and exit 2 both count as "the smoke did not pass" (Behavior step 2).
- Sandbox check of the real project (`--sandbox-check-root PATH --sandbox-check-path FILE`, both optional; the gate passes `.` and `lib/main.dart`): after the fixture run, the smoke reads `PATH/.plan-dispatcher/config.toml`, makes a clone with `workspace.clone_at(PATH, config, "smoke/sandbox-check", <tmp>/sandbox-clone, runner)`, prepares its runtime from `PATH/.plan-dispatcher/local/artifact.json` with `prepare_runtime`, runs the config's setup commands outside the sandbox (as the engine does), and then runs one Codex worker stage through `adapter.invoke` in that clone. The stage request uses the worker model chosen above, `criterion_ids = ["A1"]`, `env = {}` (no `PLAN_DISPATCHER_RUN`, so `pd check` runs in developer mode), and `permission_profile = {mode: "write", pd_path: <clone runtime pd>, extra_write_dirs: the expanded `policy.caches` paths that any configured check `needs`, network: whether any check needs `network`}`. Its prompt says: run exactly `<pd_path> check --skip-build FILE` once, change no file, and report A1 `passed` only when that command exits 0, with its exit code in `details`. After the stage the smoke scans the stage stdout/stderr and the clone's `.plan-dispatcher/local/check-logs/` for lines containing `Operation not permitted`, `Read-only file system` or `Permission denied`, and collects every path in them under the home folder, cut to its first two levels (for example `~/.config/flutter`), into `sandbox_write_denials`. This part passes when the report is valid, A1 is `passed`, `denied_actions` is empty, `git status --porcelain` in the clone is empty, and `sandbox_write_denials` is empty. The clone is always deleted.
- Report: JSON `{schema: 1, provider, codex_version, worker: {model, effort}, reviewer: {model, effort}, doctor_blockers, phase, blocker, checks, denied_actions, duration_seconds, sandbox_check: null | {ok, exit_code, denied_actions, sandbox_write_denials}, ok}`. `ok` also requires `sandbox_check.ok` when the sandbox check was requested. Field shapes: `codex_version` = `describe()["version"]` or null; `doctor_blockers` = the doctor `blockers` list (`[{code, message}]`, empty when none); `phase` = the run record's final `phase` or null when no run started; `blocker` = the run record's `blocker` (`{code, message, phase}`) or null; `checks` = `[{id, status}]` from the last final-phase check report, empty if final checks never ran; `denied_actions` = `[{stage, tool, detail}]` collected from every stage result, where `stage` is the report file stem (for example `03-worker`); `duration_seconds` = float wall time; `ok` = the pass condition above. written to `--report` (default `.plan-dispatcher/local/live-smoke-<provider>.json`, which is git-ignored). The temp folder is deleted on pass, and kept on fail or with `--keep`; its path is printed.

## Behavior

Order, all in the user's session (`executor: orchestrator`, because the smoke uses the user's Codex login and this task deletes a tool the orchestrator itself uses):

1. Write `live_codex_smoke.py` and a README section "Live provider smoke" with the command, exit codes and the note that it uses real model calls and is never run in CI.
2. Run the gate commands (first block below). If parity or the live smoke does not pass (smoke exit 1 or 2), stop: delete nothing, write `## Blocked` in `docs/tasks/plan-dispatcher/stories/05-sport-timer-cutover/03-retire-dart-validator/notes.md` with the smoke report path, exit code and blocker, keep the smoke script and README change uncommitted on the local branch, open no PR, and report to the user. Never add bypass or full-access flags to make it pass; a denial is a finding.
3. Only after both pass: `git rm tool/agent_check.dart test/tool/agent_check_test.dart` and make the replacements in the Context table. If `sandbox_write_denials` was not empty, the gate already failed: `notes.md` `## Blocked` lists each folder and says it must be added to `policy.caches` (and to the `needs` of the checks that use it) in `.plan-dispatcher/config.toml` by a follow-up planned change; this task does not widen the config itself.
3a. Move the existing ready tasks to the new engine (D56): in each folder of the Context table, add the line `executor: plan-dispatcher-v1` to the front matter right after `complexity:`; change nothing else in the task. Then run `python3 test/tool/test_backlog_integrity.py --source tool/plan_dispatcher/src --check-ready` (PLD-05-02). For every task it lists, set `status: draft` and write `notes.md` in that task folder with a `## Not ready after cutover` section that names the `readiness_errors` codes and the date; leave its other text alone. Re-run until it exits 0. Dependency or busy state is not checked here (it is normal for a ready task to wait). Record the moved and returned IDs in this task's `notes.md`.
4. Package-edit rule (contracts "Planned tests and invocation"): this task changed `tool/plan_dispatcher/`, so run `.plan-dispatcher/venv/bin/pd update --source local --path tool/plan_dispatcher`; it must report `updated`, rewriting `[distribution]` in `.plan-dispatcher/config.toml` and `.plan-dispatcher/managed.json`. Then run the final commands (second block) and record the smoke report summary in `notes.md`. Claude and Antigravity live smokes are optional; if not run, `notes.md` says "unverified".
5. Archive this task the same way as PLD-05-02 step 8: `git mv` the folder to `done/03-retire-dart-validator`, set `status: done`, add one `../` to its relative links that leave the folder, keep `notes.md` with the evidence, and change the story index link to `done/03-retire-dart-validator/index.md`. The orchestrator opens the PR under its normal approval.

## Decisions

- Run this task through the orchestrator, not the new engine: the live smoke needs the user's Codex login and the retirement must not run inside a run that uses the tool being retired.
- The smoke runs the engine in-process so it can use `FakeGitHub`; no real PR and no permanent repository.
- The model comes from the consumer's configured candidates, not a hardcoded name.
- The smoke proves the cache route twice: a synthetic cache folder in the fixture, and one real developer-mode check of this project inside the Codex sandbox, so the validator is not retired with Flutter's cache and network needs unproven.
- Existing ready tasks switch to `plan-dispatcher-v1` here (D56), because this is the first PR after which nothing can run `legacy` tasks; a task that fails the readiness check goes back to `draft` instead of being forced through.

## Out of scope

- Changing the parity case table, the Python parity test or CI.
- Widening `policy.caches` or check `needs` in the config (a found gap blocks this task instead).
- Changing the requirements or other text of the moved ready tasks.
- Required live smokes for Claude or Antigravity.
- App code, goldens or ARB files.

## Files and tests

Gate commands (step 2):

- `python3 test/tool/test_plan_dispatcher_parity.py --source tool/plan_dispatcher/src`
- `python3 tool/plan_dispatcher/tests/run_tests.py`
- `python3 tool/plan_dispatcher/tests/live_codex_smoke.py --config .plan-dispatcher/config.toml --provider codex --sandbox-check-root . --sandbox-check-path lib/main.dart`

Final commands (step 4):

- `git grep -n "agent_check" -- . ':(exclude,glob)docs/tasks/**/done/**' ':(exclude,glob)docs/tasks/planning/**' ':(exclude,glob)docs/tasks/plan-dispatcher/**' ':(exclude,glob)**/notes.md' ':(exclude)tool/plan_dispatcher/tests/test_planner.py' ':(exclude)test/tool/test_plan_dispatcher_parity.py' ':(exclude)test/tool/fixtures/plan_dispatcher_check_cases.json' ':(exclude).plan-dispatcher/config.toml'` (must print nothing; the excludes are the historical and literal-carrying files listed in Context)
- `python3 test/tool/test_backlog_integrity.py --source tool/plan_dispatcher/src` (no live task links to the deleted files)
- `python3 test/tool/test_backlog_integrity.py --source tool/plan_dispatcher/src --check-ready` (exit 0 after step 3a)
- `.plan-dispatcher/venv/bin/pd update --source local --path tool/plan_dispatcher` (step 4; a second run reports `unchanged`)
- `.plan-dispatcher/venv/bin/pd doctor --json` (no `artifact_stale` blocker)
- `.plan-dispatcher/venv/bin/pd check`
- `.plan-dispatcher/venv/bin/pd check --skip-build CLAUDE.md`
- `python3 test/tool/test_plan_dispatcher_parity.py --source tool/plan_dispatcher/src`
- `fvm flutter analyze`
- `fvm flutter test`

No app launch, device test, golden or ARB change.

## Acceptance

- [ ] When the validator is retired, then parity passes, no live file (including pending tasks) mentions `agent_check` except the listed literal-carrying files, and the six pending tasks name `pd check` instead. Check: the parity command and the `git grep` scan printing nothing.
- [ ] When the live Codex smoke runs, then a real Codex worker and reviewer finish the fixture task with local Git and `FakeGitHub` only, the worker's sandboxed check writes to the configured cache folder, and the pushed head equals the reviewed candidate. Check: `live_codex_smoke.py` exit 0 and its report with `ok: true`, summarized in `notes.md`.
- [ ] When a real project check runs inside the Codex sandbox, then `pd check --skip-build lib/main.dart` exits 0 with no denied action and no write denial under the home folder. Check: the report's `sandbox_check.ok: true`, or `## Blocked` listing the missing cache folders.
- [ ] When the cutover is done, then every listed ready task has `executor: plan-dispatcher-v1` and passes the readiness check, or is back to `draft` with a `## Not ready after cutover` note. Check: `test_backlog_integrity.py --check-ready` exit 0.
- [ ] When this task's package edits are merged, then the recorded local install matches the source. Check: `pd update` reports `unchanged` on a second run and `pd doctor --json` has no `artifact_stale` blocker.
- [ ] When parity or the live smoke fails, then `tool/agent_check.dart` and its tests still exist and `notes.md` has `## Blocked` with the report path. Check: `git status` shows `tool/agent_check.dart` and `test/tool/agent_check_test.dart` still tracked, and `notes.md` has `## Blocked`.
- [ ] When a developer runs `pd check` after the cutover, then it runs the configured checks for the changed files and `--skip-build` skips the build group. Check: the two `pd check` commands above.
