---
id: PLD-04-02
status: draft
type: feat
complexity: medium
executor: orchestrator
depends-on: [PLD-01-03, PLD-03-06, PLD-04-01]
touches:
  - tool/plan_dispatcher/src/plan_dispatcher/models.py
  - tool/plan_dispatcher/src/plan_dispatcher/coordinator.py
  - tool/plan_dispatcher/src/plan_dispatcher/cli.py
  - tool/plan_dispatcher/src/plan_dispatcher/resources/skills/skill-dispatcher/**
  - tool/plan_dispatcher/tests/test_models.py
  - tool/plan_dispatcher/tests/test_dispatcher_skill.py
skills: []
---

# Package the thin dispatcher and execution recommendations

Story: [Portable workflows and project installation](../index.md)

Epic: [PlanDispatcher](../../../index.md)

## Goal

Ship a short dispatcher skill that picks one task, recommends provider and models, asks for launch approval once and hands a validated launch request to `pd start`. Add `models.recommend`, `pd recommend` and `pd request` (which builds and validates the launch request). The engine (PLD-03-05/06) does all execution; the skill holds no stage logic.

## Context

- Today's `.agents/skills/skill-dispatcher/SKILL.md` has a tool-choice loop, a fixed model table, up to three background runners and its own role prompts. The engine and this thin skill replace all of it. Read-only here; PLD-05-01 replaces the live skill.
- Shared shapes (not restated here): [contracts](../../../contracts.md) headings "Models and coordinator", "Launch request and run record", "CLI", "Selection", "Configuration schema 1", "Stage protocol" (`describe`).
- Prerequisites: [PLD-01-03](../../01-foundation/03-select-and-reserve-tasks/index.md) (`pd next`, `pd status`, `pd release`), [PLD-03-06](../../03-cli-execution/06-publish-and-cleanup/index.md) (assembled `pd start`, `pd resume`, `pd cleanup`), [PLD-04-01](../01-portable-planner/index.md) (`references/task-format.md`; same `cli.py`).
- Requirements: R4, R5, R6, R7, R9.

## Contract

Cross-task shapes are in the contracts. Private to this task:

- **`recommend` inputs.** `pd recommend` builds `catalogs` by calling `get_adapter(provider, runner).describe(models)` for each provider in `integrations.tools`, where `models` are the unique `models.candidates` IDs of that provider. A provider whose adapter raises (`adapter_unavailable`, or any `PdError`) is left out of `catalogs`; its candidates get `availability: unavailable` and `reason: "adapter unavailable: <code>"`.
- **Ordering and ties**: as in the contracts. When several candidates share the best rank, a provider equal to `host.json` `default_cli` comes first; otherwise the contracts provider order applies.
- **`pd recommend --task ID`** reads the task from disk (`load_tasks(root, project.backlog)`), unknown ID → `usage` (exit 64). **`pd recommend --role planner-review --complexity low|medium|high`** (used by the planner) skips the task and returns only that role. `--role` without `--complexity`, `--complexity` without `--role`, or `--role` together with `--task` → `usage` (exit 64). Data: the `recommend` output; for `--role planner-review` it is `{"planner-review": [candidates], recommended: {"planner-review": first available|None}}` (no `worker` or `reviewer` keys), and `models.recommend(..., roles=("planner-review",))` returns that shape.
- **`pd request`** (new command, added to `cli.py`; builds the launch request so the skill never writes JSON by hand):
  - `pd request --task ID --worker PROVIDER:MODEL:EFFORT --reviewer PROVIDER:MODEL:EFFORT --selection recommended|override|named [--auto-model] [--invocation TOKEN] [--host-kind KIND] [--thread-id ID] [--save-default-cli PROVIDER] --out PATH`.
  - `--save-default-cli PROVIDER` (provider must be in `integrations.tools`, else `usage`) also writes `.plan-dispatcher/local/host.json` = `{"default_cli": PROVIDER}` atomically. It is the only writer of that file.
  - `--invocation` absent → a new token from `coordinator.new_invocation(host_kind, thread_id)` (`t3:<thread-id>` when kind is `t3` and a thread ID is given, else `inv-` + 16 hex).
  - It always sets `approved: true`, because the skill runs it only after the user's yes (or after a named run request). It validates with `contracts.validate_launch` and checks each provider is in `integrations.tools` and each effort is one of `low|medium|high|xhigh|max`. Failure → `launch_invalid` (exit 64). Data: `{request, path}`; the file is written atomically.
  - `coordinator.build_request(task_id, worker, reviewer, selection, auto_model, invocation, host) -> dict` and `coordinator.new_invocation(host_kind, thread_id) -> str` hold that logic; there is no event state machine, because Python cannot see the user's answer.
- **Host.** The skill sets `--host-kind t3` with the thread ID when T3 tools are present, else the CLI it runs in (`claude`, `codex`, `antigravity`), else `unknown`. `.plan-dispatcher/local/host.json` `{default_cli}` is written by `pd request --save-default-cli` when the host is `unknown` and the user picks a CLI; it only breaks recommendation ties and never stores approvals or tokens. `pd recommend` ignores a missing file, and a malformed one (bad JSON or an unknown provider) with the warning `host.json ignored: <reason>` in `warnings`.
- **Testing seam.** `cli.main(argv=None, ports=None)`; `ports` may provide `runner` and `get_adapter` (tests pass fakes). This is the PLD-01-02 entry point; this task adds no other seam.

## Packaged assets

Exactly one file: `tool/plan_dispatcher/src/plan_dispatcher/resources/skills/skill-dispatcher/SKILL.md`. Engine stage prompts belong to PLD-03-05. Required headings and steps:

- `## Before you start`: run `pd doctor --json`; on blockers say them and stop. A `needs_setup` result (from any `pd` command) is not a stop: follow the `## Setup` section of the packaged planner skill (`../skill-planner/SKILL.md#setup`, PLD-04-01) to confirm the project commands once, then start again. Decide the host kind (above).
- `## Pick the task`: a named task → `pd next --task ID --json`; not eligible → show its reasons and stop. Otherwise `pd next --json`; no eligible task → explain `waiting` in one or two lines and stop.
- `## Settings and approval`: run `pd recommend --task ID --json`. Show the task and the recommended worker and reviewer with their reasons. If a role has no recommendation, say which and offer the configured candidates for that role or stopping. Ask one question: launch with these settings, change a model, or "pick models automatically for this run" (same settings, no further model questions in this conversation). A named "run task X" request skips this question but still shows the settings.
- `## Launch`: `pd request … --out .plan-dispatcher/local/requests/<invocation>.json` (selection `named`, `override` or `recommended`), then `pd start --request <that path> --json`. Run it with the host's longest command timeout or as the host's background command when it has one.
- `## If pd start refuses`: show the error code and message. For `model_unavailable` or `launch_invalid`, offer to re-run `pd recommend` and pick other models; the new settings need a new launch approval (the earlier yes covered the old settings only). For `needs_setup`, `task_not_eligible`, `reservation_conflict` or a doctor blocker, explain it and stop. Never retry with a model the user did not approve.
- `## After the run`: `done` → PR link and minor findings. `blocked` → the blocker message plus `pd resume RUN --invocation T` and `pd release RUN --invocation T`. A host timeout or interruption → the run ID and `pd status RUN --json`, then `pd resume RUN --invocation T`. Never launch a second task in the same conversation.
- `## Never`: no queues, background runners, native host sub-agents, extra scripts or permission workarounds; never swap an unavailable explicit model; never reuse an approval or the automatic choice in a new thread or for another task.
- Links `../skill-planner/references/task-format.md` as the one task-format reference.

## Behavior

- Ask before launch exactly once per task, except for a named run request.
- After launch, no routine questions about commits, pushes or PRs; only blockers are reported.

## Decisions

- One asset file; stage prompts belong to the engine so one source defines what workers are told.
- `pd request` replaces the earlier coordinator event validator: approvals happen in the conversation, so Python only builds and validates the request.
- R6 is owned here (recommendation, automatic choice recorded per run) and in PLD-03-05 (unavailable model refused).

## Out of scope

- Execution, publication and resume (PLD-03-05/06), installation (PLD-04-03), replacing the live skill (PLD-05-01).

## Files and checks

- New: `models.py`, `coordinator.py`, `resources/skills/skill-dispatcher/SKILL.md`, `tests/test_models.py`, `tests/test_dispatcher_skill.py`. Changed: `cli.py` (`pd recommend`, `pd request`).
- `test_models.py`: `test_orders_by_rank_complexity_provider`, `test_any_complexity_fallback`, `test_provider_not_in_tools_excluded`, `test_unavailable_listed_not_recommended`, `test_no_candidate_gives_none_and_reason`, `test_adapter_error_marks_unavailable`, `test_default_cli_breaks_ties`, `test_cli_recommend_envelope` (fake `get_adapter` via `ports`), `test_cli_recommend_unknown_task_64`, `test_cli_recommend_planner_role` (shape above), `test_cli_recommend_role_flag_usage` (each invalid flag combination → 64), `test_host_json_missing_or_malformed_ignored`.
- `test_dispatcher_skill.py`: `test_request_recommended_valid`, `test_request_named`, `test_request_override`, `test_request_auto_model_keeps_models` (`auto_model: true` with both models present), `test_request_new_invocation_formats` (`inv-` + 16 hex; `t3:<id>`), `test_request_unknown_provider_launch_invalid`, `test_request_bad_effort_launch_invalid`, `test_request_writes_file_atomically`, `test_request_save_default_cli_writes_host_json`, `test_request_save_default_cli_unknown_provider_usage`; asset cases `test_skill_headings` (including `## If pd start refuses`), `test_skill_links_task_format`, `test_skill_names_commands` (`pd doctor`, `pd next`, `pd recommend`, `pd request`, `pd start --request`, `pd resume`, `pd release`, `pd status`), `test_skill_forbidden_strings` (case-insensitive; the test builds each word from parts at runtime, for example `'flut' + 'ter'`, so `test_dispatcher_skill.py` never contains a word the PLD-02-02 package-boundary patterns forbid): `fvm`, `flutter`, `sport timer`, `tool/dispatcher`, `--allow=`, `opus 5.5`, `sonnet 5.5`, `gpt-6.1`, `gemini 4 argon`, `gemini-4-argon`, `claude-opus-5-5`, `claude-sonnet-5-5`.
- Commands, from the repository root:
  - `python3 tool/plan_dispatcher/tests/run_tests.py test_models test_dispatcher_skill`
  - `fvm dart tool/agent_check.dart --skip-build`
  - `fvm flutter test`

## Acceptance

- [ ] When candidates are configured, then `recommend` orders them by rank, complexity, `default_cli` tie-break and provider order, and never recommends an unavailable model or one whose adapter failed. Check: `test_models`.
- [ ] When the skill builds a launch request, then `pd request` writes a request that `validate_launch` accepts with both models, the chosen selection and `approved: true`, and rejects unknown providers or efforts with `launch_invalid`. Check: `test_dispatcher_skill` request cases.
- [ ] When the user picks automatic models, then the request has `auto_model: true` and still names both models, and a new conversation gets a new invocation token. Check: `test_request_auto_model_keeps_models`, `test_request_new_invocation_formats`.
- [ ] When the packaged skill is scanned, then it has the required headings and commands, links the one task-format reference and contains no forbidden string. Check: `test_dispatcher_skill` asset cases.
