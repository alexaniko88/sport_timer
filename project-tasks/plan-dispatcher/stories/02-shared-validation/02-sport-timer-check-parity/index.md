---
id: PLD-02-02
status: draft
type: feat
complexity: medium
executor: orchestrator
depends-on: [PLD-02-01]
touches:
  - test/tool/fixtures/plan_dispatcher_boundary_patterns.txt
  - .plan-dispatcher/config.toml
  - test/tool/fixtures/plan_dispatcher_check_cases.json
  - test/tool/test_plan_dispatcher_parity.py
  - test/tool/agent_check_test.dart
  - .github/workflows/plan-dispatcher.yml
skills: []
---

# Configure and prove Sport Timer validator parity

Story: [Shared project validation](../index.md)

Epic: [PlanDispatcher](../../../index.md)

## Goal

Write Sport Timer's `.plan-dispatcher/config.toml` so the shared checker selects the same ordered commands and scan results as `tool/agent_check.dart`, and prove it with one case table that both the Dart tests and a new Python consumer test read. The old validator stays live.

## Context

- Behavior reference (read-only): `tool/agent_check.dart` (`ChangeSet.dartFiles`, `testFiles`, `plan`, `DiffReader`, `homePathMarker`, `openNotePattern`, `main`). Existing tests: `test/tool/agent_check_test.dart` (changed here only by adding a group).
- Checker and schema (owned by contracts, not restated): [Configuration schema 1](../../../contracts.md#configuration-schema-1-pld-01-02-loads-and-validates-owners-fill-values) (including the fixed and `source_must_exist` file-set forms) and [Checker](../../../contracts.md#checker-pld-02-01-checkspy-diffpy) (`build_check_plan`, `scan_lines`, `normalize_paths`, `changed_files`, `added_lines`). Consumer test loading: [Planned tests and invocation](../../../contracts.md#planned-tests-and-invocation).
- Shared requirements: R10, R11, R16. Prerequisite: [PLD-02-01](../01-configurable-checker/index.md).

## Contract

### `.plan-dispatcher/config.toml` (new here, exact content)

```toml
schema = 1

[project]
name = "sport_timer"
backlog = "project-tasks"
remote = "origin"
base_branch = "master"
github_repo = "alexaniko88/sport_timer"

[distribution]
source_kind = "local"
source = "tool/plan_dispatcher"
source_ref = ""
source_commit = ""
content_digest = "sha256:pending"
version = "0.1.0"

[integrations]
tools = ["claude", "codex", "antigravity"]

[instructions]
paths = ["CLAUDE.md", ".agents/rules/dart-style.md", ".agents/rules/git-commits.md", ".agents/rules/project-tasks-format.md"]

[[setup.commands]]
id = "fvm-install"
argv = ["fvm", "install", "--skip-pub-get"]
network = true
timeout_seconds = 900

[[setup.commands]]
id = "pub-get"
argv = ["fvm", "flutter", "pub", "get"]
network = true
timeout_seconds = 900

[[validation.file_sets]]
id = "dart_sources"
include = ["lib/**/*.dart", "test/**/*.dart", "tool/**/*.dart", "integration_test/**/*.dart"]
exclude = ["lib/l10n/**", "lib/firebase_options.dart"]
existing_only = true

[[validation.file_sets]]
id = "lib_dart"
include = ["lib/**/*.dart"]
exclude = ["lib/l10n/**", "lib/firebase_options.dart"]
existing_only = true

[[validation.file_sets]]
id = "changed_tests"
include = ["test/**/*_test.dart"]
existing_only = true

[[validation.file_sets]]
id = "lib_mirrored_tests"
include = ["lib/**/*.dart"]
exclude = ["lib/l10n/**", "lib/firebase_options.dart"]
source_prefix = "lib/"
source_suffix = ".dart"
target_prefix = "test/"
target_suffix = "_test.dart"
source_must_exist = true
existing_only = true

[[validation.file_sets]]
id = "tool_mirrored_tests"
include = ["tool/**/*.dart"]
source_prefix = "tool/"
source_suffix = ".dart"
target_prefix = "test/tool/"
target_suffix = "_test.dart"
source_must_exist = true
existing_only = true

[[validation.file_sets]]
id = "screens"
include = ["lib/**/presentation/**", "lib/navigation.dart", "**/*.arb"]

[[validation.file_sets]]
id = "ai_setup"
include = ["CLAUDE.md", ".agents/**", ".claude/**", ".codex/**"]

[[validation.file_sets]]
id = "arb"
include = ["**/*.arb"]

[[validation.file_sets]]
id = "android"
include = ["android/**", "pubspec.yaml"]

[[validation.file_sets]]
id = "ios"
include = ["ios/**"]

[[validation.file_sets]]
id = "layer_test"
fixed = ["test/architecture/layer_boundaries_test.dart"]
when_any = ["lib_dart"]
existing_only = true

[[validation.file_sets]]
id = "snapshot_test"
fixed = ["test/snapshots/ui_snapshots_test.dart"]
when_any = ["screens"]
existing_only = true

[[validation.file_sets]]
id = "ai_test"
fixed = ["test/architecture/ai_setup_test.dart"]
when_any = ["ai_setup"]
existing_only = true

[[validation.file_sets]]
id = "tests"
union = ["changed_tests", "lib_mirrored_tests", "tool_mirrored_tests", "layer_test", "snapshot_test", "ai_test"]

[[validation.checks]]
id = "gen-l10n"
argv = ["fvm", "flutter", "gen-l10n"]
trigger_any = ["arb"]
phases = ["worker", "final"]
needs = ["fvm", "pub-cache"]

[[validation.checks]]
id = "format"
argv = ["fvm", "dart", "format", "--output=none", "--set-exit-if-changed", "{files:dart_sources}"]
trigger_any = ["dart_sources"]
phases = ["worker", "final"]
needs = ["fvm"]

[[validation.checks]]
id = "analyze"
argv = ["fvm", "flutter", "analyze", "{files:dart_sources}"]
trigger_any = ["dart_sources"]
phases = ["worker", "final"]
needs = ["fvm", "pub-cache", "dart-server"]

[[validation.checks]]
id = "tests"
argv = ["fvm", "flutter", "test", "{files:tests}"]
trigger_any = ["tests"]
phases = ["worker", "final"]
needs = ["fvm", "pub-cache"]
timeout_seconds = 1800

[[validation.checks]]
id = "android-build"
argv = ["fvm", "flutter", "build", "apk", "--debug"]
trigger_any = ["android"]
group = "build"
phases = ["worker", "final"]
needs = ["fvm", "pub-cache", "gradle", "network"]
timeout_seconds = 1800

[[validation.checks]]
id = "ios-build"
argv = ["fvm", "flutter", "build", "ios", "--debug", "--no-codesign"]
trigger_any = ["ios"]
group = "build"
phases = ["worker", "final"]
needs = ["fvm", "pub-cache", "network"]
timeout_seconds = 1800

[[validation.scans]]
id = "local-path"
pattern = "/Users[/]"
severity = "failure"

[[validation.scans]]
id = "open-note"
pattern = "\\b(?:TO[D]O|FIX[M]E)\\b"
severity = "advisory"

[validation]
default_skipped_groups = []

[policy]
commit_subject_pattern = "^(feat|fix|refactor|chore|docs|style|perf|test|build): [a-z]"
attribution_template = "Co-Authored-By: {tool} {model}"
pr_title_template = "{type}: {title}"
required_email_suffix = "@users.noreply.github.com"
leak_scans = [{ id = "local-path", pattern = "/Users[/]" }]

[[policy.caches]]
id = "fvm"
path = "~/fvm"

[[policy.caches]]
id = "pub-cache"
path = "~/.pub-cache"

[[policy.caches]]
id = "dart-server"
path = "~/.dartServer"

[[policy.caches]]
id = "gradle"
path = "~/.gradle"

[[models.candidates]]
role = "worker"
complexity = "any"
provider = "claude"
model = "sonnet"
effort = "medium"
rank = 1

[[models.candidates]]
role = "worker"
complexity = "any"
provider = "codex"
model = "gpt-6.1-terra"
effort = "medium"
rank = 1

[[models.candidates]]
role = "worker"
complexity = "any"
provider = "antigravity"
model = "gemini-4-argon-medium"
effort = "medium"
rank = 1

[[models.candidates]]
role = "reviewer"
complexity = "any"
provider = "claude"
model = "opus"
effort = "medium"
rank = 1

[[models.candidates]]
role = "reviewer"
complexity = "any"
provider = "codex"
model = "gpt-6.1-sol"
effort = "medium"
rank = 1

[[models.candidates]]
role = "reviewer"
complexity = "any"
provider = "antigravity"
model = "gemini-4-argon-high"
effort = "high"
rank = 1

[[models.candidates]]
role = "planner-review"
complexity = "any"
provider = "claude"
model = "sonnet"
effort = "medium"
rank = 1

[[models.candidates]]
role = "planner-review"
complexity = "any"
provider = "codex"
model = "gpt-6.1-terra"
effort = "medium"
rank = 1

[[models.candidates]]
role = "planner-review"
complexity = "any"
provider = "antigravity"
model = "gemini-4-argon-medium"
effort = "medium"
rank = 1
```

The two scan patterns are written so that this file, the case table, the boundary-patterns file and `tool/agent_check.dart` never match themselves (`/Users[/]` does not contain the literal text it finds), so no scan `exclude` is needed. The same rule holds for this task file: every home-path pattern below is written with `[/]`. Model IDs are copied from `tool/dispatcher/role_models.dart` and the current planner table; they are Sport Timer configuration, not package defaults.

### Case table `test/tool/fixtures/plan_dispatcher_check_cases.json` (new here)

```json
{"schema": 1, "cases": [{
  "name": "presentation file",
  "explicit": false,
  "paths": ["lib/features/timer/presentation/timer_page.dart"],
  "existing": ["lib/features/timer/presentation/timer_page.dart", "test/features/timer/presentation/timer_page_test.dart", "test/architecture/layer_boundaries_test.dart", "test/snapshots/ui_snapshots_test.dart"],
  "skip_build": false,
  "expected_checks": [{"id": "format", "label": "Format (check only)", "argv": ["fvm", "dart", "format", "--output=none", "--set-exit-if-changed", "lib/features/timer/presentation/timer_page.dart"]}],
  "added_lines": [{"path": "lib/a.dart", "line": 2, "text": "…"}],
  "expected_scans": [{"scan_id": "local-path", "path": "lib/a.dart", "line": 2, "severity": "failure"}]
}]}
```

- `paths` are the changed (or explicit) paths, deleted ones included; `existing` is either the full list of paths that exist or the string `"all"`, which means every path exists (both consumers then use an `exists` that always returns true). `expected_checks` lists every planned (not skipped) check in order; `argv` includes the leading `fvm`; `label` is the Dart `CheckCommand.label` and `id` the Python check id. `added_lines` and `expected_scans` may be empty.
- Sample texts with a home path use the JSON escape `\u002F` for every `/`, and open notes escape their first letter (`\u0054ODO`), so the raw file never matches the scans. No real usernames, emails or secrets.

Required cases, with exact data. For a case named after an existing Dart test in `test/tool/agent_check_test.dart`, copy that test's input paths and its `skipBuild` value unchanged. For `existing`: when the test passes an explicit `exists` set, copy it; when it builds the `ChangeSet` with `existing: null` (the `_changes()` helper, meaning every path exists), write `"all"`. `expected_checks` is the full `ChangeSet.plan(skipBuild:)` result for that input, even when the source test only asserts `testFiles` or `dartFiles`: the runner obtains it by running the new Dart group once with an empty `expected_checks`, copying the printed plan into the table, and re-running until the group passes; `fvm` is prepended. Label to Python id: `Generate localizations` → `gen-l10n`, `Format (check only)` → `format`, `Analyze changed files` → `analyze`, `Tests` → `tests`, `Android debug build` → `android-build`, `iOS debug build` → `ios-build`. New cases have their data here (`existing` lists every path that exists; `expected` lists check ids in order, with the test-file argument list).

| Case | Source | `paths` | `existing` | `skip_build` | `expected` |
| --- | --- | --- | --- | --- | --- |
| documentation change | Dart test "a documentation change needs no check" | copy | copy | copy | none |
| presentation file | Dart test "a presentation file gets format, analyze and the matching tests" | copy | copy | copy | format, analyze, tests |
| data file | "a data file does not run the golden snapshots" | copy | copy | copy | copy |
| missing test | "a test that does not exist is not run" | copy | copy | copy | copy |
| changed test | "a changed test file runs itself" | copy | copy | copy | copy |
| tool file | "a tool file runs its mirrored test" | copy | copy | copy | copy |
| generated and deleted | "generated and deleted files are not analyzed" | copy | copy | copy | copy |
| ARB first | "an arb change generates localizations first" | copy | copy | copy | gen-l10n, …(copy) |
| AI setup | "a change in the AI setup runs the setup test" | copy | copy | copy | copy |
| android and skip | "android or pubspec changes build the apk, and skipBuild skips it" — four rows: `android/app/build.gradle` and `pubspec.yaml`, each with `skip_build` false and true | one path per row | copy | false / true | copy |
| ios | "an ios change builds ios" | copy | copy | copy | copy |
| normalized paths | "normalizes, removes duplicates and sorts the files" | copy (the raw unnormalized list) | copy | false | copy |
| deleted lib file | new | `lib/core/gone.dart` | `test/core/gone_test.dart`, `test/architecture/layer_boundaries_test.dart` | false | none (no mirrored test, no layer test) |
| AI setup each path | new — three rows | `CLAUDE.md` / `.agents/rules/dart-style.md` / `.codex/agents/x.toml` | `test/architecture/ai_setup_test.dart` | false | tests `[test/architecture/ai_setup_test.dart]` |
| mixed | new | `lib/features/timer/presentation/timer_page.dart`, `lib/l10n/app_en.arb`, `android/app/build.gradle`, `CLAUDE.md` | `lib/features/timer/presentation/timer_page.dart`, `test/features/timer/presentation/timer_page_test.dart`, `test/architecture/layer_boundaries_test.dart`, `test/snapshots/ui_snapshots_test.dart`, `test/architecture/ai_setup_test.dart`, `lib/l10n/app_en.arb` | false | gen-l10n; format and analyze `[timer_page.dart]`; tests `[test/architecture/ai_setup_test.dart, test/architecture/layer_boundaries_test.dart, test/features/timer/presentation/timer_page_test.dart, test/snapshots/ui_snapshots_test.dart]`; android-build |
| scan lines | new, `explicit: true` | `lib/a.dart` | `lib/a.dart` | false | format, analyze `[lib/a.dart]`, tests `[]` skipped; `added_lines` line 1 = a home path written as `\u002FUsers\u002Fme\u002Fx`, line 2 = `\u0054ODO later`; `expected_scans`: local-path failure line 1, open-note advisory line 2 |

The `explicit` field is metadata for readers only; neither suite branches on it. The "every line of an explicit file counts as added" rule is covered by PLD-02-01's `test_diff.py`, not here.

### Dart test addition (`test/tool/agent_check_test.dart`)

New group `shared plan_dispatcher cases` (when `expected_checks` is empty it prints the Dart plan as JSON and fails, which is how the runner fills the table) that reads the table with `File('test/tool/fixtures/plan_dispatcher_check_cases.json')`, and for each case builds `ChangeSet(paths, exists: existing == 'all' ? (_) => true : existing.contains)`, compares `plan(skipBuild:)` as `['fvm', ...args]` plus `label` to `expected_checks`, and applies `homePathMarker`/`openNotePattern` to `added_lines` to compare with `expected_scans` (`local-path` = failure, `open-note` = advisory). Existing groups stay unchanged.

### Python consumer test (`test/tool/test_plan_dispatcher_parity.py`, new here)

- CLI: exactly one of `--source <dir>` (inserts `<dir>` first on `sys.path`) or `--installed` (run with the system `python3`; globs `.plan-dispatcher/venv/lib/python*/site-packages` under the repository root, inserts the single match first on `sys.path`, and exits 2 with `installed runtime not found` when there is not exactly one match). Neither or both → print usage, exit 64. Runs `unittest` and exits 0 when all pass, 1 otherwise. Stdlib only. The repository root is the parent of the script's `test/tool/` folder.
- Case test: `load_config(repo_root)`, then for each case `build_check_plan(config, changes, {"phase": "developer", "skip_groups": ["build"] if skip_build else [], "include_groups": [], "exists": (lambda p: True) if existing == "all" else existing.__contains__})` where `changes` is `[{"path": p, "status": "modified"} for p in checks.normalize_paths(case["paths"])]`; planned entries' `(id, argv)` equal the expected `(id, argv)` in order; `scan_lines(config, added)` equals `expected_scans`.
- Git semantics test: in a temp repo created with `git init -b main` and committed with `git -c user.name=pd -c user.email=pd@example.invalid commit`, using `plan_dispatcher.ports.SubprocessRunner()` as the runner and the local branch name `main` as `base`: commit a base, create a branch with a modified file, a deleted file and an untracked file, then assert `diff.changed_files(root, base, runner)` returns them with statuses `modified`, `deleted`, `untracked` and that `added_lines` counts the untracked file's every line. This covers merge-base and untracked behavior; the Dart `main()` has no unit test, so this is not a Dart-vs-Python comparison.
- Package-boundary test: walk `tool/plan_dispatcher/` (skip `_vendor/`, `__pycache__/`, `dist/` and the `LICENSE` file, whose copyright line may name the owner) and fail, listing `path:line`, when any text line matches, case-insensitively, any regex in `test/tool/fixtures/plan_dispatcher_boundary_patterns.txt` (new here, one regex per line, no comments or blank lines, written so it is valid both as a Python `re` pattern and as a `git grep -E` pattern: no `\b`, and every `/` after `Users` or `home` written as `[/]` so the file never matches the `local-path` scan or the Dart `homePathMarker`): `/Users[/][^/ ]+/`, `/home[/][^/ ]+/`, `sport[_ -]?timer`, `(^|[^a-z])fvm([^a-z]|$)`, `flutter`, `\.dart([^a-z]|$)`, `lib/features`, `firebase`, `BEGIN [A-Z ]*PRIVATE KEY`, `ghp_|github_pat_|(^|[^a-z])sk-[A-Za-z0-9]{20}` (the `sk-` part needs a non-letter before it, so words like `task-…` never match). The owner name `alexaniko88` is allowed (the public repository URL is documented). PLD-06-01 reuses this file for its export scan. Rule for all package text (contracts "Package layout", PLD-01-02): no file under `tool/plan_dispatcher/` contains a forbidden word literally; a test that must check for one (PLD-04-01, PLD-04-02) builds it from parts at runtime (for example `'flut' + 'ter'`), as `tool/agent_check.dart` builds its home-path marker. There is no exemption list. The package files are owned by earlier tasks and are outside this task's `touches`: if the boundary test reports a hit there, the runner never narrows a pattern, adds an exemption or edits that file; it stops and records each `path:line` under `## Blocked` in `notes.md` for the planner.

### CI

Add a step to `.github/workflows/plan-dispatcher.yml`: `python test/tool/test_plan_dispatcher_parity.py --source tool/plan_dispatcher/src`.

Consumers: PLD-05-01 (installs over this config), PLD-05-03 (retires the Dart validator and keeps this table and test). Neither validator nor old dispatcher is removed here.

Execution route: **orchestrator** (see [Runner boundary](../../../contracts.md#runner-boundary-for-this-epic)).

## Behavior

- Every behavior in the Dart validator listed in Context has a matching case; the full-suite obligation stays in `CLAUDE.md` and is not part of the changed-file plan.
- Intentional differences, recorded here and not tested as parity: developer default base is `origin/master` instead of local `master`, and the flag is `--base REF` instead of `--base=REF`.
- The tests only plan commands; nothing runs `fvm`, builds or emulators.

## Decisions

- One table read by both suites, instead of a Dart dry-run API.
- `source_must_exist` and `fixed`/`when_any` file sets were added to the schema (PLD-02-01) because the old validator drops deleted sources before mapping and adds fixed test files on conditions; without them parity is impossible.
- The `content_digest = "sha256:pending"` placeholder is valid only for a local source; `pd doctor` reports `artifact_missing` until PLD-05-01 installs.

## Out of scope

- Removing `tool/agent_check.dart` or its tests (PLD-05-03); installing the package (PLD-05-01); any app change.

## Files and tests

Created or changed files are exactly `touches`. Commands, from the repository root:

- `python3 test/tool/test_plan_dispatcher_parity.py --source tool/plan_dispatcher/src`
- `python3 tool/plan_dispatcher/tests/run_tests.py`
- `fvm dart format test/tool/agent_check_test.dart`
- `fvm flutter analyze test/tool/agent_check_test.dart`
- `fvm flutter test test/tool/agent_check_test.dart`
- `fvm dart tool/agent_check.dart --skip-build`
- `fvm flutter test`

## Acceptance

- [ ] When each shared case is planned by `ChangeSet` and by `build_check_plan` with the Sport Timer config, then both give the same ordered checks and argv. Check: `fvm flutter test test/tool/agent_check_test.dart` and `python3 test/tool/test_plan_dispatcher_parity.py --source tool/plan_dispatcher/src`.
- [ ] When ARB, presentation, navigation, AI-setup, Android, iOS or deleted files change, with and without `skip_build`, then the trigger and skip results match the old validator. Check: the trigger cases in both suites.
- [ ] When added lines contain a home path or an open note, then both report the same failure and advisory scans. Check: scan cases in both suites.
- [ ] When the generic subtree is inspected, then no boundary pattern matches outside `_vendor/`, `__pycache__/`, `dist/` and `LICENSE`. Check: package-boundary test in `test_plan_dispatcher_parity.py`.
- [ ] When the new files are scanned by the old validator, then no local-path failure is reported for them. Check: `fvm dart tool/agent_check.dart --skip-build` exits 0.
- [ ] When this task merges, then `tool/agent_check.dart` and its existing tests are unchanged and still pass. Check: `fvm flutter test test/tool/agent_check_test.dart` and `git diff --stat master -- tool/agent_check.dart`.
