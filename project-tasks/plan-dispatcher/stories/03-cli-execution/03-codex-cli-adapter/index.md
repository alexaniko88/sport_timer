---
id: PLD-03-03
status: draft
type: feat
complexity: medium
executor: orchestrator
depends-on: [PLD-01-02]
touches:
  - tool/plan_dispatcher/src/plan_dispatcher/adapters/codex.py
  - tool/plan_dispatcher/tests/test_codex.py
  - tool/plan_dispatcher/tests/fixtures/codex/**
skills: []
---

# Implement the Codex CLI stage adapter

Story: [CLI execution and reviewed publication](../index.md)

Epic: [PlanDispatcher](../../../index.md)

## Goal

Run one worker, reviewer, interview or cold stage through the installed `codex exec` and return the normalized stage result. The report comes from the last-message file, failures and denials come from the JSONL event stream, and a zero exit code alone never counts as success.

## Context

- Shared contracts: [Stage protocol](../../../contracts.md#stage-protocol-pld-01-02-validates-adapters-pld-03-04). The request (including `criterion_ids`), `permission_profile`, normalized result, role-to-validator mapping, error codes, redaction rule and the Codex row of the pinned CLI routes are fixed there and are not repeated here.
- Provided by PLD-01-02: `ports.CommandRunner`/`SubprocessRunner` (owns the process-group kill on timeout and the `stdin` parameter), the report validators, `adapters/__init__.py: get_adapter`, and `tests/support.py` (`FakeRunner`, `fake_executable`).
- Reference only: `tool/dispatcher/tool_command.dart`.
- Facts checked on 2026-11-08 with `codex-cli 0.167.0`: `codex exec --help` lists `-C/--cd`, `-m/--model`, `-c/--config key=value` (value parsed as TOML), `-s/--sandbox` (read-only|workspace-write|danger-full-access), `--add-dir`, `--ephemeral`, `--ignore-user-config` ("auth still uses CODEX_HOME"), `--output-schema <FILE>`, `-o/--output-last-message <FILE>`, `--json` (JSONL events on stdout), and `[PROMPT]` where `-` reads stdin. `codex login status` printed `Logged in using ChatGPT` with exit 0. A real read-only run with `--output-schema` and `-o` printed these events, one per line: `{"type":"thread.started","thread_id":"…"}`, `{"type":"turn.started"}`, `{"type":"item.completed","item":{"id":"item_0","type":"agent_message","text":"{\"answer\":\"ok\"}"}}`, `{"type":"turn.completed","usage":{…}}`; the `-o` file held `{"answer":"ok"}`.
- Requirements: R7, R9, R10.

## Contract

New here: `adapters/codex.py` with `class Adapter` (`name = "codex"`), conforming to the adapter API in the contracts.

- `__init__(runner, executable=None)`: `executable` or `shutil.which("codex")`.
- `describe(models)`: each probe runs through `runner.run` with `timeout_seconds=30` and no stdin. A non-zero exit or timeout of `--version` → `version: None, version_ok: False`; of `exec --help` → `flags_ok: False` with every flag missing.
  - `version`: first `\d+\.\d+\.\d+` in `codex --version` (`codex-cli 0.167.0`); `version_ok`: ≥ `0.167.0`.
  - `flags_ok`/`missing_flags`: `--ignore-user-config --ephemeral --output-schema --output-last-message --json --sandbox --add-dir --cd --model --config` must appear in `codex exec --help`.
  - `auth`: `codex login status` exit 0 → `ok`, non-zero → `missing`, runner error → `unknown`. Output is not stored.
  - `models`: no discovery command, so given IDs are `configured`.
  - Binary missing (`executable` is None or not executable): no probe runs and the result is exactly `{binary: None, version: None, version_ok: False, auth: "unknown", flags_ok: False, missing_flags: [all ten flags above, in that order], models: [{id, availability: "unavailable"} for each given ID]}`.
- `invoke(request)`: validates the request with `contracts.validate_stage_request`, reads the prompt text from `request.prompt_path` (UTF-8), and runs once through `runner.run(argv, cwd=request.cwd, env={**os.environ, **request.env}, timeout_seconds=request.timeout_seconds, stdin=<prompt text>, stdout_path=request.stdout_path, stderr_path=request.stderr_path)`. The full parent environment is passed, so `HOME` and any `CODEX_HOME` stay as they are; the adapter never sets `CODEX_HOME`. `invoke` does not call `describe`; the engine runs `doctor` first. Before running, `invoke` deletes any existing `report_path` and `<raw>` file left by an earlier attempt that reused the same path, so a stale file can never pass as this run's report.

Exact argv (`<raw>` is `request.report_path + ".raw"`):

- Common: `[codex, exec, --ignore-user-config, --ephemeral, -C, <cwd>, -m, <model>, -c, model_reasoning_effort="<effort>", -c, approval_policy="never", --output-schema, <schema_path>, -o, <raw>, --json]`.
- `mode == "write"`: common + `[-s, workspace-write]` + `[--add-dir, <d>]` for each `extra_write_dirs` entry + `[-c, sandbox_workspace_write.network_access=true]` only when `network` is true + `[-]`.
- `mode == "read"`: common + `[-s, read-only, -]`. Never `--add-dir` or network.
- Never `danger-full-access`, `--dangerously-bypass-approvals-and-sandbox`, `--approve-for-me`, `--profile` or `--worktree`.

Result mapping. Stdout is always parsed first for `denied_actions`; then the first matching rule below sets `provider_error`, and later rules are not checked. `exit_code` is the runner's value (None on timeout).

- Denials: parse stdout line by line, ignoring lines that are not JSON. Each `item.completed` event whose `item.type == "command_execution"` and `item.status == "declined"` adds `{tool: "command_execution", detail: item.command[:200]}`. Denials never set `provider_error` by themselves: a declined command with exit 0 and a valid report gives `process_ok: True`, `report_valid: True` and a non-empty `denied_actions`. The lifecycle decides.

1. Binary missing → `binary_missing`; nothing is run.
2. `timed_out` → `timed_out: True`, `provider_error.code = "timeout"`.
3. Negative exit code → `interrupted: True`, `provider_error.code = "interrupted"`.
4. An event `{"type":"turn.failed","error":{"message":…}}` or `{"type":"error","message":…}` → `provider_failed` with the first such message. A `<raw>` report next to it is ignored (`report: None`).
5. Exit code ≠ 0 with no failure event → `provider_failed` with the stderr tail.
6. `<raw>` missing or empty → `output_missing`; not a JSON object → `output_malformed` (even with exit 0).
7. The role validator from the contract (`worker` → `validate_worker_report(report, request["criterion_ids"])`, `reviewer` → `validate_reviewer_report`, `interview`/`cold` → `validate_review_verdict`) fails → `report_invalid`, `report: None` (the stage result validator requires `report` null unless `report_valid`); the validator message is the `provider_error.message`, and the parsed text stays in `<raw>` for diagnostics.
8. Otherwise `process_ok: True`, `report_valid: True`; write the report to `report_path`.

`<raw>` is deleted only on rule 8. On every failure it is kept next to `report_path` for diagnostics.

Redaction: the values to hide are those of every variable whose name contains `TOKEN`, `KEY` or `SECRET` in the env passed to the runner (`os.environ` merged with `request.env`). Each such non-empty value is replaced by `***` in every `provider_error.message`, whether it comes from a `turn.failed`/`error` event (rule 4) or the stderr tail (rule 5), and the message is then cut to its last 2000 characters. Log files at `stdout_path`/`stderr_path` are left as written.

Consumers: PLD-03-05, PLD-04-01, PLD-03-01 (`describe`). The live Codex smoke in PLD-05-03 confirms the `declined` event shape and the cache/network route; if the real output differs, that task changes this adapter before retirement.

Execution route: **orchestrator**, under the epic's runner boundary in [contracts](../../../contracts.md#runner-boundary-for-this-epic).

## Behavior

- The prompt is sent on stdin through the `-` argument; paths stay single argv entries, no shell.
- `extra_write_dirs` and `network` come only from `permission_profile`, which the engine builds from the frozen config. The adapter never adds directories on its own.
- Model and effort are passed exactly; no fallback.
- The adapter does not detect tree changes; PLD-03-05 does that after read-only stages.

## Decisions

- Minimum Codex CLI version is 0.167.0, the verified local version.
- `approval_policy="never"` makes an unavailable permission fail instead of waiting for a prompt.
- Interview and cold roles use the same read-only route as the reviewer.

## Out of scope

- Live Codex calls in tests (the live smoke is PLD-05-03).
- Process-group killing (PLD-01-02 runner) and reviewer-mutation detection (PLD-03-05).
- Changes to `~/.codex`, credentials or the CLI installation.

## Files and tests

- New `tool/plan_dispatcher/src/plan_dispatcher/adapters/codex.py`.
- New `tool/plan_dispatcher/tests/test_codex.py` and fixtures in `tool/plan_dispatcher/tests/fixtures/codex/`: `success.jsonl` (the four real event lines above), `turn_failed.jsonl` (`thread.started` then `{"type":"turn.failed","error":{"message":"model not found"}}`), `declined.jsonl` (adds `{"type":"item.completed","item":{"id":"item_1","type":"command_execution","command":"npm test","status":"declined"}}`), `report_ok.json`, `report_bad.json`, `help.txt`, `help_missing_flag.txt`.
- Cases (argv cases with `FakeRunner`; process cases with `SubprocessRunner` and `fake_executable`, where the fake writes the `-o` file it receives):
  1. Worker argv equals the write list with two `extra_write_dirs` and `network` true; again with `network` false (no network `-c` entry).
  2. Reviewer, interview and cold argv equal the read list.
  3. Paths and cwd containing `a b'$;\`` stay single entries; stdin equals the prompt text.
  4. `success.jsonl` + `report_ok.json`, exit 0 → `process_ok`, `report_valid`, report written, `.raw` removed.
  5. Exit 0 but no `-o` file → `output_missing`; `-o` file `not json` → `output_malformed`, and the `.raw` file is still there.
  6. `turn_failed.jsonl` with exit 0 and a valid `-o` file → `provider_failed` with message `model not found`, `report` None.
  7. `declined.jsonl` with exit 0 and `report_ok.json` → `denied_actions == [{tool: "command_execution", detail: "npm test"}]`, `provider_error` None, `report_valid` true.
  8. `report_bad.json` (worker report missing `A2`, request `criterion_ids: ["A1", "A2"]`) → `report_invalid`, `report` None, `.raw` kept. A stale `report_path` and `.raw` from an earlier attempt are deleted before the run, so a fake that writes no `-o` file gives `output_missing`.
  9. Exit 1 with no events → `provider_failed`; binary missing → `binary_missing`, runner not called; `describe` with a missing binary returns exactly the binary-missing shape above.
  10. `describe`: `codex-cli 0.166.9` → `version_ok` false; `--version` exiting 1 → `version: None`; every probe called with `timeout_seconds=30`; missing `--ephemeral` in help → `missing_flags`; login status exit 1 → `missing`; models `configured`.
  11. Timeout with a fake that spawns a child and sleeps; `timeout_seconds = 2`; both PIDs gone when `invoke` returns, `timed_out` true, `exit_code` None, code `timeout`. A fake that kills itself with SIGKILL → `interrupted` true, code `interrupted`.
  12. The runner receives an env that still contains the test's `HOME` and `CODEX_HOME` values unchanged. A `FAKE_TOKEN` value set in `os.environ` is redacted in a stderr-tail message, a `request.env` `API_KEY` value is redacted in a `turn.failed` message, and a 3000-character stderr tail is cut to 2000 characters.
- Commands, from the repository root:
  - `python3 tool/plan_dispatcher/tests/run_tests.py test_codex`
  - `fvm dart tool/agent_check.dart`
  - `fvm flutter test`

## Acceptance

- [ ] When a worker or a read-only stage is requested, then the argv equals the pinned list for its profile, the prompt goes on stdin and the environment keeps `HOME`/`CODEX_HOME`. Check: `python3 tool/plan_dispatcher/tests/run_tests.py test_codex` cases 1-3 and 12.
- [ ] When Codex exits 0 without a report, emits `turn.failed` or returns an invalid report, then the result keeps that failure code, has `report` None and is never `report_valid`; a stale earlier report is never used; a declined command is always listed in `denied_actions`. Check: `test_codex` cases 4-9.
- [ ] When the CLI is too old, lacks a flag or is logged out, then `describe` shows it. Check: `test_codex` case 10.
- [ ] When a stage times out, then the CLI and its child have exited before `invoke` returns. Check: `test_codex` case 11.
