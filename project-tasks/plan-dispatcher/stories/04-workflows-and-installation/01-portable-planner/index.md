---
id: PLD-04-01
status: draft
type: feat
complexity: medium
executor: orchestrator
depends-on: [PLD-03-01, PLD-03-02, PLD-03-03, PLD-03-04]
touches:
  - tool/plan_dispatcher/src/plan_dispatcher/planning.py
  - tool/plan_dispatcher/src/plan_dispatcher/cli.py
  - tool/plan_dispatcher/src/plan_dispatcher/resources/skills/skill-planner/**
  - tool/plan_dispatcher/tests/test_planner.py
  - tool/plan_dispatcher/tests/support.py
  - tool/plan_dispatcher/tests/fixtures/planner/**
skills: []
---

# Package the portable planner and planning review commands

Story: [Portable workflows and project installation](../index.md)

Epic: [PlanDispatcher](../../../index.md)

## Goal

Ship a framework-neutral planner skill as package resources, plus `pd plan prepare` and `pd plan review`. The planner keeps today's interview, mockup, review and cold-read discipline, but reads project rules and checks from the project's confirmed configuration instead of hardcoding Flutter, Sport Timer or model names. The live Sport Timer skill is not replaced here; PLD-05-01 does that.

## Context

- Behavior source (read-only): `.agents/skills/skill-planner/SKILL.md`, its `references/` (questions, ui-questions, mockup, task-splitting, templates) and `roles/` (cold-reader, interview-reviewer), plus `.agents/rules/project-tasks-format.md`.
- Shared shapes (not restated here): [contracts](../../../contracts.md) headings "Planner support", "CLI", "Stage protocol", "Task model", "Configuration schema 1", "Workspace, runtime and doctor", "Models and coordinator".
- Prerequisites: [PLD-03-01](../../03-cli-execution/01-prepare-workspaces/index.md) (`workspace.clone_at`, `repository_key`), [PLD-03-02](../../03-cli-execution/02-claude-cli-adapter/index.md), [PLD-03-03](../../03-cli-execution/03-codex-cli-adapter/index.md), [PLD-03-04](../../03-cli-execution/04-antigravity-cli-adapter/index.md) (adapters). From PLD-01-02: `tasks.readiness_errors`, `load_config`, `gitutil.state_dir`, `get_adapter`, `review_verdict.schema.json`, `tests/support.py` (`make_git_repo`, `FakeRunner`).
- Requirements: R2, R7, R15 (story coverage table). R6 is not owned here.

## Contract

Cross-task shapes are in the contracts "Planner support" and "CLI" headings. Private to this task:

- **Where commands run.** Every `pd plan` command runs with the user's active project checkout as the current directory (root = `git rev-parse --show-toplevel` of cwd); the state folder is `gitutil.state_dir(root)`. The planning clone is passed by plan id, never found from the clone's own `.git`. The planner skill text tells the agent to run `pd` from the active checkout and to read and write plan files inside the printed clone path.
- **`prepare_plan`**:
  - `slug(topic)`: lowercase, every run of characters outside `[a-z0-9]` becomes `-`, trimmed of `-`, cut to 40 characters. Empty slug → `PdError("usage", exit 64)`.
  - Calls `workspace.clone_at(root, config, branch="feat/plan-<slug>", path=<cache_root>/planning/<repository_key>/<plan_id>/, runner)` from PLD-03-01. No reservation, no runtime, no setup commands.
  - Record `<state_dir>/plans/<plan_id>.json` = `{schema: 1, plan_id, topic, path, branch, base_sha, created_at}`, written atomically. A second call with the same topic returns the record when `path` still exists (status `reused` in the data); a record whose folder is missing raises `workspace_collision` (exit 2) naming the recorded path.
- **`pd plan review --plan PLAN_ID PATH --role interview|cold --provider P --model M [--effort E]`**:
  - `PATH` is relative to the planning clone and must exist there, else `usage` (exit 64). No record for `PLAN_ID` → `PdError("plan_missing", exit 2)`.
  - Review number `NN`: 1 + the highest two-digit prefix among all file names in `<state_dir>/plans/<plan_id>/reviews/` that match `^\d\d-` (any extension, so a failed review with no `.json` still takes its number), two digits, starting at `01`. Files for one review: `<NN>-<role>.prompt.md`, `<NN>-<role>.json` (report), `<NN>-<role>.stdout`, `<NN>-<role>.stderr`. Earlier reviews are never overwritten.
  - Prompt: the full text of the packaged `roles/interview-reviewer.md` (interview) or `roles/cold-reader.md` (cold), then one line `The input is <PATH>.` Nothing else.
  - Stage request: `run_id = plan_id`, `role`, `cwd` = clone path, `prompt_path`, `report_path`, `stdout_path`, `stderr_path` as above, `schema_path` = packaged `review_verdict.schema.json`, `provider` = `--provider`, `model`, `effort` (default `medium`), `timeout_seconds = 1800`, `permission_profile = {mode: "read", pd_path: None, extra_write_dirs: [], network: False}`, `env = {}`.
  - `--provider` must be in `integrations.tools`, else `usage`.
  - After the stage, `git status --porcelain=v1 --untracked-files=all` and `git rev-parse HEAD` of the clone must equal the values taken before it; otherwise the result's `provider_error` is `{code: "reviewer_mutated", message}` and `report_valid` is false.
  - Data: `{verdict, questions, report_path}`. Exit 0 when the report is valid (either verdict); 64 for usage. When the stage failed or the report is invalid: exit 1, `error.code` = the result's `provider_error.code` when set, else `report_invalid`; `error.message` = its message plus the stdout path; failure data `{report_path, stdout_path, stderr_path}` (contracts "CLI" lists `pd plan review` among commands that keep failure data).
- **`pd plan prepare TOPIC`** data: the `prepare_plan` result plus `status: created|reused`. Exit 2 for any PLD-03-01 blocker. `cache_root` comes from `ports["cache_root"]` when the test passes it, else the default `~/Library/Caches/PlanDispatcher` (the `cache_root` `ports` key in contracts "CLI"); no CLI flag.
- **Publishing the plan.** After the user's final approval, the skill commits, pushes and opens the PR from inside the planning clone with plain `git add`, `git commit`, `git push -u origin feat/plan-<slug>` and `gh pr create`, following the commit and PR rules in the project's `instructions.paths` files. It never commits in the active checkout. No `pd` command publishes a plan.
- Both commands call `load_config(root)` first, so a missing or unconfirmed config gives `needs_setup` (exit 2).
- Consumers: PLD-04-03 installs these assets; PLD-05-01 makes them Sport Timer's live planner; PLD-04-02 links `references/task-format.md`.

## Packaged assets

Exact files under `tool/plan_dispatcher/src/plan_dispatcher/resources/skills/skill-planner/`:

| File | Source and change |
| --- | --- |
| `SKILL.md` | From today's SKILL.md. Keep the steps and talking rules. Replace the model table with: "Pick the reviewer model with `pd recommend --role planner-review --complexity medium`; use its `recommended` entry, or let the user pick another configured candidate." Replace the sync and branch steps with `pd plan prepare <topic>` and "write all plan files inside the printed path". Replace the branch-and-PR handoff with the "Publishing the plan" steps above. Replace the per-tool cold-read block with `pd plan review --plan <plan_id> <path> --role cold --provider P --model M`, and the interview review with `--role interview`. Read project rules from every path in `instructions.paths` of `.plan-dispatcher/config.toml`. The backlog is `project.backlog`. Keep the final approval question for the planner's own PR. Add a `## Setup` section before the first step: when any `pd` command returns `needs_setup`, read `.plan-dispatcher/local/proposal.json` (`evidence` and `template`), propose concrete `setup`, `validation`, `policy`, `models` and `instructions` values from that evidence and the repository instructions, show them to the user once, and on one confirmation write them to a proposal file and run `pd install --proposal <file> --confirm`; never run a discovered command before that confirmation. `SKILL.md` links to at least one file under `references/` and one under `roles/` with relative Markdown links (for example `[task format](references/task-format.md)` and `[cold reader](roles/cold-reader.md)`). |
| `references/task-format.md` | Canonical portable task format (below). |
| `references/questions.md` | From today's file; Sport Timer or Flutter examples become neutral examples (a settings screen, a CLI flag). |
| `references/ui-questions.md` | From today's file. Golden or ARB references become "the project's visual reference images and localization files named in its instructions". |
| `references/mockup.md` | From today's file, framework-neutral. The mockup rule is kept: `mockup.html` sits beside the planning record until the split, then one approved copy moves into its owning story or standalone task. |
| `references/task-splitting.md` | From today's file. Validation commands come from `validation.checks` and `pd check`. "Golden files" become "visual reference images". |
| `references/templates.md` | Templates for the shorter layout below. Front matter blocks use real valid values (`status: draft`, `type: feat`, `complexity: low`, `executor: plan-dispatcher-v1`, `depends-on: []`, `touches: [path/to/file]`); placeholders appear only in the body text. Visual tasks keep a "visual reference images" line. |
| `roles/cold-reader.md` | From today's role. "Read first": the task, its parents, `references/task-format.md`, every `instructions.paths` file and the named files. Output: the `review_verdict` JSON (contracts "Stage protocol"). |
| `roles/interview-reviewer.md` | From today's role, same JSON output. |

### Portable task format (`references/task-format.md`)

- It is the full, standalone format: PLD-05-01 turns `.agents/rules/project-tasks-format.md` into a pointer to it, and `skill-project-tasks` and `skill-orchestrator` keep reading it there. So it must carry every section of today's rule, rewritten framework-neutral, under exactly these headings in this order: `## Layout`, `## Interview record`, `## IDs`, `## Task index.md`, `## Shared agreements and coverage`, `## When a task is ready`, `## Archiving into done/`, `## State is deduced`, `## Overlap`, `## Writing rules`.
- Layout, IDs, `done/` archiving, deduced state and overlap rules as in today's format rule, with root `project.backlog` (`docs/tasks/` by default), the interview record at `<backlog>/planning/<topic>/planning.md`, and the task branch `<type>/<id-lowercase>-<slug>`.
- Front matter: the subset in contracts "Front matter subset"; required keys `id, status, type, complexity, depends-on, touches`; optional `skills`, `executor` (new tasks write `plan-dispatcher-v1`).
- Required sections, in order: `# <Title>`, `## Goal`, `## Scope` (in and out), `## Behavior`, `## Files and checks` (exact paths, test cases, `pd check` and any named commands), `## Acceptance` (`- [ ] When …, then …. Check: …`).
- Conditional sections, required when they apply: `## Contract` (provides or consumes a shared interface), `## View spec` and `## Mockup` (changes a view), `## Tooling` (needs a capability, cache, network or command beyond `validation.checks`).
- Legacy long tasks stay valid.
- Ready checklist: `tasks.readiness_errors` returns nothing, the cold read passed, a visual task links an approved mockup, and every conditional section that applies is present. Only the first item is machine-checked; the rest are planner steps.

## Behavior

- Keep, as asset text: one question per message, saved interview record, coverage, duplicate-backlog search, mockup approval for visual work, interview completeness review, agreed split, criteria approval, per-task cold reads, whole-plan validation and the final approval for the planner PR.
- Never switch, clean or delete branches in the user's active checkout, and never sweep merged branches.
- Asset text never states Flutter, Sport Timer or provider model rules; it points to `instructions.paths` and the config.

## Decisions

- R6 moved to PLD-04-02 and PLD-03-05: the planner only reads `pd recommend` output.
- `pd plan` commands run from the active checkout and address the clone by plan id, because a clone's own `.git` is not the project's state folder.
- The packaged task format is standalone and complete, so pointing the project rule at it (PLD-05-01) loses no guidance.
- The planning clone gets no runtime: reviews run the provider CLIs from the project venv, and the planner never runs `pd check`.

## Out of scope

- Replacing the live `.agents/skills/skill-planner/` (PLD-05-01), the installer (PLD-04-03), model recommendation logic (PLD-04-02), any app code.

## Files and checks

- New: `planning.py`, the asset files above, `tests/test_planner.py`, `tests/fixtures/planner/backlog/` with three tasks: `stories/01-a/01-legacy/index.md` (long legacy layout, ready), `stories/01-a/02-short/index.md` (short layout, ready), `stories/01-a/03-no-check/index.md` (short layout, one acceptance line without `Check:`).
- Changed: `cli.py` (`pd plan prepare`, `pd plan review`); `tests/support.py` gains `FakeReviewAdapter(result: dict, mutate: Optional[callable] = None)` (its own name, so it never collides with PLD-03-05's `FakeAdapter`) that records each request in `.requests`, writes `result["report"]` to `report_path` when valid, and calls `mutate(cwd)` to simulate a mutation.
- `test_planner.py` cases:
  - `test_assets_exist_with_headings`: every file in the asset table exists; `SKILL.md` has `## Setup`, `## Talking to the user` and `## Cold read`, and at least one relative link into `references/` and one into `roles/` that resolve to packaged files; `task-format.md` has the ten headings listed under "Portable task format" in that order and names the six required task sections in order.
  - `test_assets_have_no_forbidden_strings` (case-insensitive). The test builds every word below from parts at runtime (for example `'f' + 'vm'`, `'flut' + 'ter'`), so `test_planner.py` itself never contains a word the package-boundary patterns of PLD-02-02 forbid: `fvm`, `flutter`, `sport timer`, `sport_timer`, `golden`, `.arb`, `project-tasks`, `agent_check`, `tool/dispatcher`, `opus 5.5`, `sonnet 5.5`, `claude-opus-5-5`, `claude-sonnet-5-5`, `gpt-6.1`, `gemini 4 argon`, `gemini-4-argon`.
  - `test_templates_front_matter_parses`: for each fenced front matter block in `templates.md`, write `<tmp>/backlog/stories/01-s/0N-t/index.md` = the block + `# T`, `## Goal`, `x`, `## Acceptance`, `- [ ] When a, then b. Check: c.`, then `load_tasks(tmp, "backlog")` loads every file without an exception. There is no separate public parser.
  - `test_fixture_readiness`: legacy and short tasks give no `readiness_errors`; `03-no-check` gives exactly `acceptance_without_check`.
  - `test_prepare_creates_clone_outside_repo`, `test_prepare_leaves_active_checkout_unchanged` (branch and `git status` equal before and after), `test_prepare_reuses_record`, `test_prepare_missing_folder_is_collision`, `test_prepare_empty_slug_usage`.
  - `test_review_request_shape` (role, cwd, profile, schema, provider, timeout, the four paths), `test_review_prompt_is_role_plus_input_line`, `test_review_numbering_does_not_overwrite` (including after a failed review that wrote no `.json`), `test_review_failure_code_and_paths` (adapter `timeout` → exit 1, `error.code` `timeout`, data has the three paths), `test_review_mutation_is_reviewer_mutated`, `test_review_invalid_report_exit_1`, `test_review_unknown_plan_exit_2`, `test_review_provider_not_in_tools_usage`.
  - `test_plan_commands_need_setup`: no config → both commands exit 2 `needs_setup`.
- Commands, from the repository root:
  - `python3 tool/plan_dispatcher/tests/run_tests.py test_planner test_tasks test_workspace`
  - `fvm dart tool/agent_check.dart --skip-build`
  - `fvm flutter test`

## Acceptance

- [ ] When `pd plan prepare TOPIC` runs in a configured repo, then a clone on `feat/plan-<slug>` is made outside the repo, the active checkout is unchanged, and a repeat call reuses it. Check: `test_planner` prepare cases.
- [ ] When the fixture backlog is read, then the legacy and short tasks have no readiness errors and the task without a check reports `acceptance_without_check`. Check: `test_fixture_readiness`.
- [ ] When `pd plan review --plan ID PATH --role cold` runs, then the adapter gets a read-only request whose prompt is only the role text plus the input line, files are numbered without overwriting, and a mutated clone gives `reviewer_mutated`. Check: `test_planner` review cases.
- [ ] When the packaged assets are scanned, then every listed file exists with its headings, templates parse, and no forbidden string appears. Check: `test_planner` asset cases.
- [ ] When the project has no confirmed `.plan-dispatcher/config.toml`, then both plan commands exit 2 with `needs_setup`. Check: `test_plan_commands_need_setup`.
