---
id: PLD-03-02
status: ready
type: feat
complexity: medium
executor: orchestrator
depends-on: [PLD-01-02]
touches:
  - tool/plan_dispatcher/src/plan_dispatcher/adapters/claude.py
  - tool/plan_dispatcher/tests/test_claude.py
  - tool/plan_dispatcher/tests/fixtures/claude/**
skills: []
---

# Implement the Claude CLI stage adapter

Story: [CLI execution and reviewed publication](../index.md)

Epic: [PlanDispatcher](../../../index.md)

## Goal

Run one worker, reviewer, interview or cold stage through the installed `claude` CLI and return the normalized stage result. The adapter builds an exact argv, sends the prompt on stdin, and never reports a provider failure, denial or invalid report as success.

## Context

- Shared contracts: [Stage protocol](../../../contracts.md#stage-protocol-pld-01-02-validates-adapters-pld-03-04). The request (including `criterion_ids`), `permission_profile`, normalized result, role-to-validator mapping, error codes, redaction rule and the Claude row of the pinned CLI routes are fixed there and are not repeated here.
- Provided by PLD-01-02: `ports.CommandRunner`/`SubprocessRunner` (owns the process-group kill on timeout), `contracts.validate_worker_report`, `validate_reviewer_report`, `validate_review_verdict`, `adapters/__init__.py: get_adapter(name, runner, executable=None)`, and `tests/support.py` (`FakeRunner`, `fake_executable`).
- Reference only: `tool/dispatcher/tool_command.dart` (today's Claude argv). It is not a permission guarantee.
- Facts checked on 2026-11-08 with Claude Code 2.1.319: `claude --help` lists `-p/--print`, `--output-format` (text|json|stream-json), `--json-schema <schema>`, `--setting-sources` (user, project, local), `--no-session-persistence`, `--permission-mode` (acceptEdits, auto, bypassPermissions, manual, dontAsk, plan), `--allowedTools <tools...>`, `--add-dir <directories...>`, `--model`, `--effort` (low|medium|high|xhigh|max). `claude --version` prints `2.1.319 (Claude Code)`. `claude auth status` prints JSON with `"loggedIn": true`. A real `-p --output-format json --json-schema …` run printed one JSON object with `type: "result"`, `subtype: "success"`, `is_error: false`, `result: "{\"answer\":\"ok\"}"`, `structured_output: {"answer": "ok"}`, `permission_denials: []` and many other keys.
- Requirements: R7, R9, R10.

## Contract

New here: `adapters/claude.py` with `class Adapter` (`name = "claude"`), conforming to the adapter API in the contracts.

- `__init__(runner, executable=None)`: `executable` or `shutil.which("claude")`; None means missing.
- `describe(models: list[str]) -> dict`: the contract's describe shape. Each probe runs through `runner.run` with `timeout_seconds=30` and no stdin.
  - `binary`: resolved path or None. When None, every other field is `version: None, version_ok: False, auth: "unknown", flags_ok: False, missing_flags: [all required], models: [{id, availability: "unavailable"}]`.
  - `version`: first `\d+\.\d+\.\d+` in `claude --version` stdout. `version_ok`: that version ≥ `2.1.319` (tuple compare). A non-zero exit, a timeout or no match → `version: None, version_ok: False`.
  - `flags_ok`/`missing_flags`: each of `--print --output-format --json-schema --setting-sources --no-session-persistence --permission-mode --allowedTools --add-dir --model --effort` must appear in `claude --help` stdout. A non-zero exit or a timeout → `flags_ok: False` and every flag in `missing_flags`.
  - `auth`: run `claude auth status`; exit 0 with JSON `loggedIn: true` → `ok`; JSON `loggedIn: false` → `missing`; anything else (non-JSON, non-zero exit, timeout) → `unknown`. Never print or store its other fields.
  - `models`: Claude has no discovery command, so every given ID is `configured` (when the binary exists).
- `invoke(request: dict) -> dict`: validates the request with `contracts.validate_stage_request`, reads the prompt text from `request.prompt_path` (UTF-8), runs the CLI once through `runner.run(argv, cwd=request.cwd, env={**os.environ, **request.env}, timeout_seconds=request.timeout_seconds, stdin=<prompt text>, stdout_path=request.stdout_path, stderr_path=request.stderr_path)`, and returns the normalized result. On a valid report it writes the report JSON to `request.report_path`. `invoke` does not call `describe`; the engine runs `doctor` before any stage, so a too-old CLI or a missing flag shows up as a provider failure here at most.

Exact argv (each item is one argv entry; `<schema>` is `json.dumps(json.load(open(schema_path)), separators=(",", ":"))`, which keeps the file's key order):

- Common prefix: `[claude, -p, --output-format, json, --json-schema, <schema>, --model, <model>, --effort, <effort>, --setting-sources, project, --no-session-persistence]`.
- `permission_profile.mode == "write"` (worker): prefix + `[--permission-mode, acceptEdits, --allowedTools, Read, Edit, Write, Glob, Grep, Bash(<pd_path> check:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*)]`, then `[--add-dir, <d1>, <d2>, …]` only when `extra_write_dirs` is non-empty. When `pd_path` is None the `Bash(<pd_path> check:*)` entry is left out.
- `mode == "read"` (reviewer, interview, cold): prefix + `[--permission-mode, plan, --allowedTools, Read, Glob, Grep, Bash(git diff:*), Bash(git log:*), Bash(git show:*)]`. Never `--add-dir`.
- `permission_profile.network` has no argv effect for Claude (this route does not sandbox network). It is not an error.
- Never `bypassPermissions`, `dontAsk`, `--dangerously-skip-permissions` or `--permission-prompts`.

Result mapping. The first matching rule sets `provider_error`; later rules are not checked. `exit_code` is the runner's value (None on timeout).

1. Binary missing → `process_ok: False`, `provider_error: {code: "binary_missing", message: "claude not found"}`; nothing is run.
2. `timed_out` from the runner → `timed_out: True`, `provider_error.code = "timeout"`.
3. Exit code negative (killed by a signal the runner did not send) → `interrupted: True`, `provider_error.code = "interrupted"`.
4. Exit code ≠ 0 and stdout is not a JSON object with `type: "result"` → `provider_failed`, message = stderr tail.
5. Exit code 0 and stdout is not a JSON object with `type: "result"` → `output_malformed`.
6. `is_error: true` or exit code ≠ 0 → `provider_failed`, message = `result` when it is a non-empty string, else the stderr tail.
7. Report = `structured_output` when it is an object; else `result` parsed as a JSON object; else `output_missing`.
8. The role validator from the contract (`worker` → `validate_worker_report(report, request["criterion_ids"])`, `reviewer` → `validate_reviewer_report`, `interview`/`cold` → `validate_review_verdict`) fails → `report_valid: False`, `provider_error.code = "report_invalid"`, `report: None` (the stage result validator requires it); the raw output stays in the stdout log for diagnostics.
   Before running, `invoke` deletes any stale file at `report_path`, so a report from an earlier attempt can never pass as this stage's report.
9. Otherwise `process_ok: True`, `report_valid: True`, `provider_error: None`.

`denied_actions` = one `{tool: tool_name, detail: json.dumps(tool_input)[:200]}` per `permission_denials` entry, filled whenever stdout parsed (also on success). Denials never set `provider_error` by themselves; the lifecycle decides whether a denial blocks the run.

Redaction: messages and `detail` replace the value of any environment variable whose name contains `TOKEN`, `KEY` or `SECRET` with `***`, and keep at most the last 2000 characters of stderr.

Consumers: PLD-03-05 (lifecycle stages), PLD-04-01 (`pd plan review`), PLD-03-01 (`pd doctor` via `describe`). `get_adapter("claude", …)` imports this module by name (contract), so no registry file changes here.

Execution route: **orchestrator**, under the epic's runner boundary in [contracts](../../../contracts.md#runner-boundary-for-this-epic).

## Behavior

- The prompt text is read from `prompt_path` and sent on stdin; paths with spaces, quotes, `$`, `;` or backticks stay one argv entry. No shell is used.
- Model and effort are passed exactly as requested; the adapter never changes or falls back to another model or provider.
- The adapter does not detect tree changes; the lifecycle (PLD-03-05) compares status and HEAD after read-only stages.
- Raw stdout/stderr stay in the requested local paths; the result holds only paths and redacted short messages.

## Decisions

- Minimum Claude Code version is 2.1.319, the version verified on the planning machine; the earlier 2.1.259 note is replaced because its flags were not checked.
- Prompts go on stdin so long task text never hits argv limits or shell quoting.
- Read-only roles use `plan` mode plus read tools only; plan mode is not claimed to be an OS-level read-only guarantee.

## Out of scope

- Live calls to Claude in tests; the opt-in live smoke is not part of this task.
- Process-group killing (owned by `SubprocessRunner`, PLD-01-02) and reviewer-mutation detection (PLD-03-05).
- Any change to global Claude settings, credentials or the CLI installation.

## Files and tests

- New `tool/plan_dispatcher/src/plan_dispatcher/adapters/claude.py`.
- New `tool/plan_dispatcher/tests/test_claude.py` and fixture bodies in `tool/plan_dispatcher/tests/fixtures/claude/` (`success.json`, `is_error.json`, `denied.json`, `no_structured.json`, `bad_report.json`, `auth_logged_in.json`, `auth_logged_out.json`, `help.txt`, `help_missing_flag.txt`). Each JSON body copies the real sampled shape above, trimmed to the keys used.
- Cases (argv cases use `FakeRunner`; process cases use `SubprocessRunner` with `fake_executable`):
  1. Worker argv equals the exact list above, with `pd_path` and two `extra_write_dirs`; stdin equals the prompt file text; cwd equals `request.cwd`.
  2. Reviewer, interview and cold argv each equal the read list; no `--add-dir`, no `Edit`/`Write`.
  3. A prompt path and cwd containing `a b'$;\``; argv entries unchanged.
  4. `success.json` → `process_ok` and `report_valid` true, report written to `report_path`.
  5. `is_error.json` with exit 0 → `provider_failed`.
  6. `denied.json` (`permission_denials: [{tool_name: "Bash", tool_use_id: "x", tool_input: {command: "npm test"}}]`) → `denied_actions == [{tool: "Bash", detail: …}]`.
  7. `no_structured.json` with `result: "plain text"` → `output_missing`; non-JSON stdout with exit 0 → `output_malformed`; empty stdout with exit 1 and stderr `boom` → `provider_failed` with message containing `boom`.
  8. `bad_report.json` (worker report missing criterion `A2` while the request has `criterion_ids: ["A1", "A2"]`) → `report_invalid`, `report_valid` false. A valid reviewer report with role `reviewer` and a valid verdict with role `cold` → `report_valid` true.
  9. Binary missing → `binary_missing`, runner not called.
  10. `describe`: version `2.1.318` → `version_ok` false; `--version` exiting 1 → `version: None`; `help_missing_flag.txt` → `missing_flags == ["--json-schema"]`; logged in/out/garbled auth → ok/missing/unknown; models are `configured`; every probe is called with `timeout_seconds=30`.
  11. Timeout: a fake `claude` that starts a child (`sleep 60`, writing its PID to a file) and sleeps; request `timeout_seconds = 2`; result `timed_out` true, and both PIDs are gone when `invoke` returns.
  12. Redaction: env `MY_TOKEN=abc123` and stderr containing `abc123` → message contains `***`, not `abc123`.
- Commands, from the repository root:
  - `python3 tool/plan_dispatcher/tests/run_tests.py test_claude`
  - `fvm dart tool/agent_check.dart`
  - `fvm flutter test`

## Acceptance

- [ ] When a worker or a read-only stage is requested, then the argv equals the pinned list for its profile, the prompt is sent on stdin and cwd is the request cwd. Check: `python3 tool/plan_dispatcher/tests/run_tests.py test_claude` cases 1-3.
- [ ] When Claude returns `is_error`, permission denials, no structured output, malformed JSON or a report that fails validation, then the result keeps that failure code and never `report_valid` true. Check: `test_claude` cases 4-9.
- [ ] When the installed CLI is too old, lacks a required flag or is not logged in, then `describe` reports it in `version_ok`, `missing_flags` or `auth`. Check: `test_claude` case 10.
- [ ] When a stage times out, then the CLI and its child process have exited before `invoke` returns, and secrets are redacted from messages. Check: `test_claude` cases 11-12.
