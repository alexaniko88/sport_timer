---
id: PLD-06-02
status: draft
type: feat
complexity: medium
executor: orchestrator
depends-on: [PLD-06-01]
touches:
  - .plan-dispatcher/config.toml
  - .plan-dispatcher/managed.json
  - .agents/skills/skill-planner/**
  - .agents/skills/skill-dispatcher/**
  - .claude/skills/skill-planner
  - .claude/skills/skill-dispatcher
  - tool/plan_dispatcher/**
  - .gitignore
  - .github/workflows/plan-dispatcher.yml
  - test/tool/test_plan_dispatcher_parity.py
  - test/tool/fixtures/plan_dispatcher_boundary_patterns.txt
  - .agents/references/plan-dispatcher-project.md
  - test/architecture/ai_setup_test.dart
  - CLAUDE.md
  - docs/tasks/plan-dispatcher/stories/06-extraction-and-adoption/02-adopt-pinned-release/index.md
  - docs/tasks/plan-dispatcher/stories/06-extraction-and-adoption/done/02-adopt-pinned-release/index.md
  - docs/tasks/plan-dispatcher/stories/06-extraction-and-adoption/done/02-adopt-pinned-release/notes.md
  - docs/tasks/plan-dispatcher/stories/06-extraction-and-adoption/index.md
  - docs/tasks/plan-dispatcher/index.md
skills: []
---

# Adopt the pinned release and remove temporary source

Story: [Independent release and consumer adoption](../index.md)

Epic: [PlanDispatcher](../../../index.md)

## Goal

Switch Sport Timer from the in-repo package source to the released `v0.1.0` commit of `alexaniko88/plan-dispatcher`, prove it works, and only then delete `tool/plan_dispatcher/`. Keep a tested way back to the local source until the PR merges.

## Context

- Run through skill-orchestrator, not the new dispatcher, because this task replaces the engine that would run it.
- Release values come from `docs/tasks/plan-dispatcher/stories/06-extraction-and-adoption/done/01-publish-independent-project/notes.md`, section `## Release` (repository, tag, commit, source), written by [PLD-06-01](../01-publish-independent-project/index.md).
- The backlog root is `docs/tasks` (PLD-05-02). The old Dart validator is gone (PLD-05-03); the project checker is `.plan-dispatcher/venv/bin/pd check`.
- Cross-task shapes are owned by [contracts.md](../../../contracts.md) and are not restated here: "Installer and update" (`pd update` and `install.py restore` forms, error codes), "CLI" (`pd status` data), "Extraction and adoption proof" and "Runner boundary for this epic". Shared requirements: R1, R3, R16, R18.
- `docs/task-automation.md` no longer exists (deleted by PLD-05-01).

## Contract

Consumed, all defined elsewhere: `pd update` (git and local forms) from PLD-04-04, `install.py restore` from PLD-04-03, `test/tool/test_plan_dispatcher_parity.py --installed` from PLD-02-02, `pd status` and `run_state` values from PLD-01-03 and PLD-03-05, and the release's own `tests/run_tests.py test_release_install test_portable_flow` from PLD-04-03 and PLD-03-06.

Private to this task:

- Backup folder `B = ~/Library/Caches/PlanDispatcher/backups/sport_timer-pld-06-02/` (outside the repository and outside `.plan-dispatcher/local/`, so step 8 cannot move it). It mirrors repository-relative paths and is deleted only after the PR merges.
- Backed-up paths: `.plan-dispatcher/config.toml`, `.plan-dispatcher/managed.json`, `.plan-dispatcher/local/artifact.json`, `.plan-dispatcher/local/artifacts/`, `.agents/skills/skill-planner/`, `.agents/skills/skill-dispatcher/`, `.claude/skills/skill-planner`, `.claude/skills/skill-dispatcher` (links), `.gitignore`.

Changed here: `[distribution]` in `.plan-dispatcher/config.toml` becomes `source_kind = "git"`, `source = "https://github.com/alexaniko88/plan-dispatcher.git"`, `source_ref = "v0.1.0"`, `source_commit = <commit>`, through `pd update` only (never by hand).

## Behavior

Steps, in order. Each step's result goes into this task's `notes.md` `## Steps`.

1. **Refuse unless all hold** (stop and report the first failure):
   - The `## Release` section above exists on `origin/master` and has a 40-hex commit.
   - `git ls-remote https://github.com/alexaniko88/plan-dispatcher.git 'refs/tags/v0.1.0^{}'` prints that commit.
   - `gh release view v0.1.0 --repo alexaniko88/plan-dispatcher --json isDraft` shows `false`.
   - `.plan-dispatcher/venv/bin/pd status --json`: every entry of `data.runs` has `state` `done` or `released` (an empty list is fine). Any other state (`active`, `interrupted`, `blocked`, `pending_publication`, `running`) stops the task.
2. **Back up:** `rm -rf B`, then for each backed-up path `P`: `mkdir -p "B/$(dirname P)"` and `cp -RP P "B/P"` (`-P` keeps links as links). Then `ls -la B/.claude/skills` shows both links.
3. **Adopt:** `.plan-dispatcher/venv/bin/pd update --source git --url https://github.com/alexaniko88/plan-dispatcher.git --ref v0.1.0 --commit <commit>`. It must report `status: updated`: the source kind and commit change, so the contracts' digest-and-commit rule never sees this as `unchanged`. If it reports `unchanged`, the task was already adopted in an earlier attempt: check that `[distribution]` already has `source_kind = "git"`, `source_ref = "v0.1.0"` and `source_commit = "<commit>"`, record that, and continue; any other `[distribution]` value stops the task.
4. **Prove** (all must pass): `python3 test/tool/test_plan_dispatcher_parity.py --installed`, `.plan-dispatcher/venv/bin/pd check`, `fvm flutter test test/architecture/ai_setup_test.dart`.
5. **Release fixtures:** `git clone https://github.com/alexaniko88/plan-dispatcher.git <tmp>/pd-src`, `git -C <tmp>/pd-src checkout --detach <commit>`, `python3 <tmp>/pd-src/tests/run_tests.py test_release_install test_portable_flow`. These build the release wheel and run a temporary framework-neutral consumer, then delete it. Remove `<tmp>` afterward.
6. **Rollback rehearsal:** `.plan-dispatcher/venv/bin/pd update --source local --path tool/plan_dispatcher` (must report `updated`, because the source kind changes back), then the parity test passes, then repeat step 3 (must report `updated` again) and the parity test. This proves the way back works before the source is deleted.
7. **Remove source:** `rm -rf tool/plan_dispatcher` (no staging; the user stages and commits through the orchestrator); remove the `tool/plan_dispatcher/...` lines from `.gitignore` (keep `.plan-dispatcher/venv/` and `.plan-dispatcher/local/`).
8. **Fresh-clone restore check:** `mkdir -p <tmp>/aside && mv .plan-dispatcher/venv .plan-dispatcher/local <tmp>/aside/`; re-clone `<tmp>/pd-src` at the commit if step 5 removed it; `python3 <tmp>/pd-src/install.py restore --root .`; then the parity test passes. Then copy back the machine-local files restore does not recreate: `cp -p <tmp>/aside/local/host.json .plan-dispatcher/local/` when it exists. Old wheel folders from `<tmp>/aside/local/artifacts/` are not copied back, because step 1 proved no run still uses them. Run records live in the Git common dir (`.git/plan-dispatcher/`), not in `local/`, so they are untouched by this step. Then `rm -rf <tmp>/aside`. On failure: `rm -rf .plan-dispatcher/venv .plan-dispatcher/local`, move both folders back from `<tmp>/aside/`, and go to Rollback.
9. **Update guidance and CI:**
   - `test/tool/test_plan_dispatcher_parity.py`: default mode becomes `--installed`; `--source` is removed. The package-boundary test is deleted with the source it walked, and so is `test/tool/fixtures/plan_dispatcher_boundary_patterns.txt` (its only other user, PLD-06-01's export scan, is finished). The case-table, merge-base and untracked-file tests stay and run against the installed package; `test/tool/fixtures/plan_dispatcher_check_cases.json` is unchanged.
   - `.agents/references/plan-dispatcher-project.md` (PLD-05-01): replace any `tool/plan_dispatcher/install.py` command with the release clone form used in `CLAUDE.md` below.
   - `.github/workflows/plan-dispatcher.yml` replaced with exactly the content below.
   - `CLAUDE.md`: replace the restore command `python3 tool/plan_dispatcher/install.py restore --root .` (added by PLD-05-01) with `git clone https://github.com/alexaniko88/plan-dispatcher.git <dir> && git -C <dir> checkout --detach <commit from .plan-dispatcher/config.toml> && python3 <dir>/install.py restore --root .`; say updates go through `pd update`; remove every other mention of `tool/plan_dispatcher`.
   - `test/architecture/ai_setup_test.dart`: in the `plan-dispatcher install` group added by PLD-05-01 (its checksum test already uses `Process.run('shasum', ['-a', '256', path])`, so no package is added), add one test "release source is pinned": `.plan-dispatcher/config.toml` has the lines `source_kind = "git"`, `source_ref = "v0.1.0"` and `source_commit = "<40 hex>"` (regex on lines, no TOML parser). No other assertion changes, because none points at `tool/plan_dispatcher`.
10. **Reference scan:** `git grep -n -I -E 'tool/plan_dispatcher|--source tool' -- . ':!docs/tasks' ':!.agents/skills/skill-planner' ':!.agents/skills/skill-dispatcher' ':!.plan-dispatcher/managed.json'` prints nothing. The files known to need cleaning are all handled above: `.gitignore` (step 7), `CLAUDE.md`, `test/tool/test_plan_dispatcher_parity.py`, `.github/workflows/plan-dispatcher.yml`, `.agents/references/plan-dispatcher-project.md` and the deleted patterns file (step 9), and `.plan-dispatcher/config.toml` (`[distribution] source`, rewritten by `pd update` in step 3). The excluded skill folders and manifest are release content that this task must not edit; the release is generic, so they never mention this repository's old source path. If a match appears in any other file that is not in `touches`, stop and record it under `## Blocked` instead of editing it.

Failures in steps 9 and 10 (guidance, CI, scan) are fixed forward inside `touches`, because the pinned install already works. Only when `fvm flutter test` or the parity test fails after step 9 and the cause is not a guidance edit is the full rollback below used.

Rollback (any failure in steps 3 to 8, or the case above, before the PR):

1. If step 7 ran: `git restore --source=HEAD --staged --worktree tool/plan_dispatcher .gitignore`.
2. If `pd` still runs: `.plan-dispatcher/venv/bin/pd update --source local --path tool/plan_dispatcher`.
3. If `pd` does not run: for each backed-up path `P`, `rm -rf P` then `cp -RP "B/P" P`; then `python3 tool/plan_dispatcher/install.py restore --root .`.
4. Run the parity test with `--source tool/plan_dispatcher/src`; it must pass. Stop and report; the backlog under `docs/tasks/` is never touched by rollback.

New `.github/workflows/plan-dispatcher.yml`:

```yaml
name: plan-dispatcher
on:
  pull_request:
    paths:
      - ".plan-dispatcher/**"
      - "test/tool/test_plan_dispatcher_parity.py"
      - "test/tool/fixtures/plan_dispatcher_check_cases.json"
      - "test/tool/test_backlog_integrity.py"
      - "docs/tasks/**"
      - ".github/workflows/plan-dispatcher.yml"
  push:
    branches: [master]
    paths:
      - ".plan-dispatcher/**"
      - "test/tool/test_plan_dispatcher_parity.py"
      - "test/tool/fixtures/plan_dispatcher_check_cases.json"
      - "test/tool/test_backlog_integrity.py"
      - "docs/tasks/**"
      - ".github/workflows/plan-dispatcher.yml"
jobs:
  consumer:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v7.0.1
      - uses: actions/setup-python@<tag>   # the exact tag already pinned in this file by PLD-01-02
        with:
          python-version: "3.9"
      # install.py restore builds .plan-dispatcher/venv with this same Python 3.9,
      # so the parity test finds exactly one lib/python3.9/site-packages folder.
      # No Flutter or fvm is needed for this job.
      - name: Restore pinned PlanDispatcher
        run: |
          COMMIT=$(sed -n 's/^source_commit = "\(.*\)"$/\1/p' .plan-dispatcher/config.toml)
          git clone https://github.com/alexaniko88/plan-dispatcher.git "$RUNNER_TEMP/pd-src"
          git -C "$RUNNER_TEMP/pd-src" checkout --detach "$COMMIT"
          python "$RUNNER_TEMP/pd-src/install.py" restore --root .
      - name: Consumer parity
        run: python test/tool/test_plan_dispatcher_parity.py --installed
      - name: Backlog integrity
        run: python test/tool/test_backlog_integrity.py --installed
```

## Decisions

- Pin by commit, never a tag alone or "latest" (D47, approved R17/R18).
- Delete the local source only after the released version passes parity, release fixtures, a rollback rehearsal and a fresh restore, so a failed adoption never leaves Sport Timer without a working engine.
- The second consumer is a temporary fixture from the release's own tests, not a permanent repository (D50).

## Out of scope

- Changing the released package, publishing a new release, or editing `docs/tasks/` content other than this task's own archive.
- Any app, UI or localization change.

## Files and tests

Files: see `touches` and the steps above.

Archive (last change, before the PR): `git mv` this folder to `../done/02-adopt-pinned-release/`; set `status: done`; tick every Acceptance box (`- [x]`) that has an `## Evidence` line; add one `../` to every relative link that leaves the task folder (`../index.md` → `../../index.md`, `../../../index.md` → `../../../../index.md`, `../../../contracts.md` → `../../../../contracts.md`), except the link to PLD-06-01: that task is already archived in the same `done/` folder, so `../01-publish-independent-project/index.md` stays exactly as written; write `notes.md` with `## Steps` and `## Evidence`; rewrite every link to this task in the story index and the epic index to the `done/` path (find them with `git grep -n "02-adopt-pinned-release/index.md" -- docs/tasks/plan-dispatcher/index.md docs/tasks/plan-dispatcher/stories/06-extraction-and-adoption/index.md`).

Commands, from the repository root, after step 10:

- `python3 test/tool/test_plan_dispatcher_parity.py --installed`
- `.plan-dispatcher/venv/bin/pd check`
- `fvm flutter test`
- the step 10 `git grep` (must print nothing)

No app launch, device test, golden or ARB change. Do not report a check as passed without running it.

## Acceptance

- [ ] When Sport Timer adopts the release, then installed parity, `pd check` and the AI setup test pass before `tool/plan_dispatcher` is deleted. Check: steps 3 to 7 recorded in order in `notes.md`, then `python3 test/tool/test_plan_dispatcher_parity.py --installed`.
- [ ] When restoration fails, then the way back gives a working local install with the backlog untouched. Check: the step 6 rollback rehearsal output (local update, parity pass, git update, parity pass) recorded in `notes.md`.
- [ ] When a fresh checkout restores the same release, then the release fixtures pass and their temporary consumer is removed. Check: step 5 `run_tests.py test_release_install test_portable_flow` output and the step 8 restore plus parity output.
- [ ] When the adoption PR is checked, then no live reference to the local source remains and the app suite still passes. Check: the step 10 `git grep` prints nothing, and `fvm flutter test` passes.
- [ ] When the adoption PR is open, then the new consumer workflow restores the pinned release and passes parity on CI. Check: `gh pr checks <number> --repo alexaniko88/sport_timer` shows the `consumer` job of `plan-dispatcher` passing.
