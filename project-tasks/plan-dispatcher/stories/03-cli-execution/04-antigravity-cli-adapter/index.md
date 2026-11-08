---
id: PLD-03-04
status: ready
type: feat
complexity: medium
executor: orchestrator
depends-on: [PLD-01-02]
touches:
  - tool/plan_dispatcher/src/plan_dispatcher/adapters/antigravity.py
  - tool/plan_dispatcher/tests/test_antigravity.py
  - tool/plan_dispatcher/tests/fixtures/antigravity/**
skills: []
---

# Implement the Antigravity CLI stage adapter

Story: [CLI execution and reviewed publication](../index.md)

Epic: [PlanDispatcher](../../../index.md)

## Goal

Run one worker, reviewer, interview or cold stage through the installed `agy` CLI and return the normalized stage result. Antigravity reports soft denials and mode fallbacks on stderr with exit code 0, so the adapter must read those and never treat exit 0 as success on its own.

## Context

- Shared contracts: [Stage protocol](../../../contracts.md#stage-protocol-pld-01-02-validates-adapters-pld-03-04). The request (including `criterion_ids`), `permission_profile`, normalized result, role-to-validator mapping, error codes, redaction rule and the Antigravity row of the pinned CLI routes are fixed there and are not repeated here.
- Provided by PLD-01-02: `ports.CommandRunner`/`SubprocessRunner` (process-group kill on timeout), validators, `adapters/__init__.py: get_adapter`, `tests/support.py`.
- Reference only: `tool/dispatcher/tool_command.dart` (uses `--sandbox --mode … --model … --print-timeout … -p=<prompt>`).
- Facts checked on 2026-11-08 with `agy` 1.5.3 on the planning machine:
  - `agy --help` lists `--sandbox`, `--mode` (accept-edits, auto, plan), `--model`, `--effort` (low|medium|high|xhigh|max), `--output-format` (text, json, stream-json), `--json-schema` (string or file path), `--print-timeout`, `--add-dir`, `--settings` (session-only JSON of settings keys, inline or a file path), `-p/--print`, and the subcommand `agy models`. `agy --version` printed `1.5.3`.
  - `agy models` printed `Fetching available models...` then lines `<id>\t<name>`, for example `gemini-4-argon-medium\tGemini 4 Argon (Medium)`.
  - A plan-mode run with `--output-format json --json-schema <file> -p=<prompt>` printed one JSON object: `{"conversation_id":"…","status":"SUCCESS","response":"…","structured_output":{"answer":"ok"},"json_schema":{…},"usage":{…}, …}`.
  - `-p=-` does **not** read stdin: the CLI took `-` as the prompt, tried a tool and printed on stderr `jetski: no output produced — a tool required the "command" permission that headless mode cannot prompt for, so it was auto-denied. …`, while stdout still had `status: "SUCCESS"`, `structured_output: null` and exit code 0.
  - `--mode auto` printed on stderr `warning: --mode auto is not available for this account; continuing in the default mode.` and continued with exit 0.
  - `--settings '{"permissions":{"allow":["command(git status)"]}}'` let a headless run execute `git status --short` without a prompt.
- Requirements: R7, R9, R10.

## Contract

New here: `adapters/antigravity.py` with `class Adapter` (`name = "antigravity"`), conforming to the adapter API in the contracts.

- `__init__(runner, executable=None)`: `executable` or `shutil.which("agy")`.
- `describe(models)`: probes run through `runner.run` with no stdin and `timeout_seconds=30` (`agy models` gets 60, because it fetches the list). A non-zero exit or timeout of `--version` → `version: None, version_ok: False`; of `--help` → `flags_ok: False` with every flag missing.
  - `version`: first `\d+\.\d+\.\d+` in `agy --version`; `version_ok`: ≥ `1.5.3`.
  - `flags_ok`/`missing_flags`: `--sandbox --mode --model --effort --output-format --json-schema --print-timeout --add-dir --settings --print` must appear in `agy --help`.
  - `auth`: no documented probe → always `unknown`.
  - `models`: run `agy models`; skip lines without a tab; first column is the ID. Exit 0: given IDs in the list are `verified`, others `unavailable`. Non-zero or runner error: all `configured`.
- `invoke(request)`: validates the request with `contracts.validate_stage_request`, reads the prompt text from `request.prompt_path` (UTF-8), and runs once through `runner.run(argv, cwd=request.cwd, env={**os.environ, **request.env}, timeout_seconds=request.timeout_seconds, stdout_path=…, stderr_path=…)` with no stdin. `invoke` does not call `describe` or check versions and flags; the engine runs `doctor` before any stage.

Exact argv (`<prompt>` is the full text of `prompt_path` as one argv entry, `T = max(request.timeout_seconds - 30, 1)`):

- Common: `[agy, --sandbox, --model, <model>, --effort, <effort>, --output-format, json, --json-schema, <schema_path>, --print-timeout, <T>s]`.
- `mode == "write"`: common + `[--mode, accept-edits, --settings, <S>]` + `[--add-dir, <d>]` per `extra_write_dirs` entry + `[-p=<prompt>]`. `<S>` is compact JSON `{"permissions":{"allow":[…]}}` with `command(<pd_path> check)`, `command(git status)`, `command(git diff)`, `command(git log)`; the `pd_path` entry is left out when `pd_path` is None.
- `mode == "read"`: common + `[--mode, plan, --settings, <R>, -p=<prompt>]`, where `<R>` is compact JSON `{"permissions":{"allow":["command(git diff)","command(git log)","command(git show)"]}}`, so a reviewer can read the diff without an auto-denial. Never `--add-dir`.
- `permission_profile.network` has no argv effect (agy has no network switch in this route). It is not an error.
- Never `--dangerously-skip-permissions`, `--mode auto`, `--remote-agent` or `--continue`.

Result mapping. `denied_actions` is always collected first; then the first matching rule below sets `provider_error`, and later rules are not checked. `exit_code` is the runner's value (None on timeout).

- Denials: each stderr line containing `auto-denied` adds `{tool: <text inside the first pair of double quotes, else "unknown">, detail: line[:200]}`. They are collected even when a rule below fails the stage, and they never set `provider_error` by themselves.

1. Binary missing → `binary_missing`; nothing is run.
2. `timed_out` → `timed_out: True`, code `timeout`. Negative exit code → `interrupted: True`, code `interrupted`.
3. Any stderr line containing both `is not available` and `continuing in the default mode` → `capability_fallback`, even with exit 0, with that line as the message.
4. Stdout is not one JSON object → `provider_failed` with the stderr tail when the exit code ≠ 0, else `output_malformed`.
5. `status != "SUCCESS"` → `provider_failed`; message = `response` when it is a non-empty string, else the stderr tail.
6. Exit code ≠ 0 (with `status: "SUCCESS"`) → `provider_failed`; message = the stderr tail.
7. `structured_output` is not an object → `output_missing`. This is the soft-denial case: `SUCCESS` with null output.
8. The role validator from the contract (`worker` → `validate_worker_report(report, request["criterion_ids"])`, `reviewer` → `validate_reviewer_report`, `interview`/`cold` → `validate_review_verdict`) fails → `report_invalid`, `report: None` (the stage result validator requires it); the raw output stays in the stdout log for diagnostics.
   Before running, `invoke` deletes any stale file at `report_path`, so a report from an earlier attempt can never pass as this stage's report.
9. Otherwise `process_ok: True`, `report_valid: True`; write the report to `report_path`.

Redaction and message length follow the contracts.

Consumers: PLD-03-05, PLD-04-01, PLD-03-01 (`describe`).

Execution route: **orchestrator**, under the epic's runner boundary in [contracts](../../../contracts.md#runner-boundary-for-this-epic).

## Behavior

- The prompt is one argv entry `-p=<prompt>`; paths stay single entries; no shell. A prompt longer than 200 000 characters returns `provider_failed` with message `prompt too long for argv` without running (macOS `ARG_MAX` is 1 MiB; task prompts are far smaller).
- The CLI's own `--print-timeout` ends 30 s before the engine's process-group timeout, so the CLI normally exits by itself first.
- Plan mode is not an OS read-only guarantee; PLD-03-05 rejects reviewer tree changes.
- Model and effort are passed exactly; no fallback.

## Decisions

- Worker mode is `accept-edits` with session-only allow rules, not `auto`: on the planning machine `--mode auto` was not available and silently continued in default mode. The adapter still treats that warning as `capability_fallback` if it ever appears. This replaces "worker auto mode" in the earlier contract text.
- Prompts go in `-p=<prompt>` because `-p=-` was checked and does not read stdin.
- Minimum `agy` version is 1.5.3, the verified local version.

## Out of scope

- Live `agy` calls in tests; the Antigravity live smoke is optional and reported unverified unless run.
- Process-group killing (PLD-01-02) and reviewer-mutation detection (PLD-03-05).
- Changes to global Antigravity settings or credentials.

## Files and tests

- New `tool/plan_dispatcher/src/plan_dispatcher/adapters/antigravity.py`.
- New `tool/plan_dispatcher/tests/test_antigravity.py` and fixtures in `tool/plan_dispatcher/tests/fixtures/antigravity/`: `success.json` (real shape above), `soft_denied.json` (`status: "SUCCESS"`, `structured_output: null`) with `soft_denied.stderr` (the real `auto-denied` line), `fallback.stderr` (the real `--mode auto` warning), `error.json` (`status: "ERROR"`, `response: "model unavailable"`), `report_bad.json`, `models.txt` (the real `agy models` format), `help.txt`, `help_missing_flag.txt`.
- Cases (argv with `FakeRunner`; process cases with `SubprocessRunner` and `fake_executable`):
  1. Worker argv equals the write list, including the exact `--settings` JSON with `pd_path` and two `extra_write_dirs`; without `pd_path` the entry is absent.
  2. Reviewer, interview and cold argv equal the read list, including the exact read `--settings` JSON and no `--add-dir`.
  3. A prompt containing quotes, `$`, `;`, backticks and newlines is exactly one `-p=` entry; cwd with spaces is passed as cwd.
  4. `timeout_seconds = 2700` → `--print-timeout 2670s`; `timeout_seconds = 10` → `1s`.
  5. `success.json` → `process_ok`, `report_valid`, report written.
  6. `soft_denied.json` + `soft_denied.stderr`, exit 0 → `output_missing` and `denied_actions == [{tool: "command", detail: …}]`.
  7. `fallback.stderr` plus an `auto-denied` line, exit 0, valid `success.json` → `capability_fallback`, `process_ok` false, and `denied_actions` still has the denial.
  8. Failure codes:
     - `error.json` (with stderr `other`) → `provider_failed` with message `model unavailable`;
     - `success.json` with exit 1 and stderr `crash` → `provider_failed` with `crash`;
     - non-JSON stdout with exit 0 → `output_malformed`, and with exit 1 → `provider_failed`;
     - `report_bad.json` (worker report missing `A2`, request `criterion_ids: ["A1", "A2"]`) → `report_invalid`.
  9. Binary missing → `binary_missing`; prompt over the limit → `provider_failed`, runner not called.
  10. `describe`: `models.txt` marks a listed ID `verified` and an absent one `unavailable`; `agy models` exit 1 → `configured`; auth always `unknown`; version `1.5.2` → `version_ok` false; `--version` exiting 1 → `version: None`; missing `--settings` → `missing_flags`; `agy models` is called with `timeout_seconds=60` and the other probes with 30.
  11. Timeout with a fake that spawns a child and sleeps; `timeout_seconds = 2`; both PIDs gone when `invoke` returns; a `*_SECRET` value is redacted from the message.
- Commands, from the repository root:
  - `python3 tool/plan_dispatcher/tests/run_tests.py test_antigravity`
  - `fvm dart tool/agent_check.dart`
  - `fvm flutter test`

## Acceptance

- [ ] When a worker or a read-only stage is requested, then the argv equals the pinned list for its profile, with the prompt as one `-p=` entry and the print timeout 30 s below the stage timeout. Check: `python3 tool/plan_dispatcher/tests/run_tests.py test_antigravity` cases 1-4.
- [ ] When agy exits 0 but auto-denies a tool, falls back from the requested mode, returns null structured output, an error status or an invalid report, then the result keeps that failure. Check: `test_antigravity` cases 5-9.
- [ ] When models are listed or the CLI is old or missing a flag, then `describe` reports `verified`/`unavailable`/`configured` and the version or flag problem honestly. Check: `test_antigravity` case 10.
- [ ] When a stage times out, then the CLI and its child have exited before `invoke` returns. Check: `test_antigravity` case 11.
