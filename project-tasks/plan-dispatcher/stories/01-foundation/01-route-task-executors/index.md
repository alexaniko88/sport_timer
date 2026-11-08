---
id: PLD-01-01
status: draft
type: feat
complexity: medium
executor: legacy
depends-on: []
touches:
  - tool/dispatcher/task.dart
  - tool/dispatcher/task_selector.dart
  - tool/dispatcher.dart
  - test/tool/dispatcher/task_selector_test.dart
  - test/architecture/ai_setup_test.dart
  - .agents/rules/project-tasks-format.md
  - .agents/rules/git-commits.md
  - .agents/skills/skill-orchestrator/SKILL.md
  - .agents/skills/skill-orchestrator/roles/agent-implementer.md
skills: []
---

# Route planned tasks to a compatible executor

Story: [Foundation and task eligibility](../index.md)

Epic: [PlanDispatcher](../../../index.md)

## Goal

Let a task declare which executor may run it, make the current Dart dispatcher refuse every task that is not `legacy`, and make the orchestrator run planned local tasks on their canonical task branch with the task's own check commands. This is the gate that lets every later PLD task be routed safely.

## Context

- `tool/dispatcher/task.dart` (existing): `Task.tryParse` reads `id`, `status`, `type`, `complexity`, `depends-on`, `touches`, `skills`, and already builds `Task.slug` (folder name without its `NN-` prefix) and `Task.branch` (`<type>/<id-lowercase>-<slug>`). It ignores `executor`.
- `tool/dispatcher/task_selector.dart` (existing): `TaskSelector.blockReason` checks, in order, done, status, skipped, busy, unknown dependencies, waiting dependencies and overlap. `busyIds` already matches remote branches and open PR heads built like `Task.branch`.
- `tool/dispatcher.dart` (existing): `_launch` only checks `task.isReady`, so a named task bypasses `blockReason`.
- `.agents/skills/skill-orchestrator/SKILL.md` Stage 0 names branches `<prefix>/<short-summary>`; Stages 2, 3 and 5 always require `fvm dart format`, `fvm flutter analyze`, the full suite and `tool/agent_check.dart`. `roles/agent-implementer.md` always applies Dart, l10n and `fvm` rules.
- Shared requirements: R4, R8, R16. Executor values and the runner boundary: [contracts — Runner boundary for this epic](../../../contracts.md#runner-boundary-for-this-epic).

## Contract

- `Task.executor` (new here, `String`): read from the raw `front['executor']` map value, not through `_scalar` (which turns `''` into null). Rules, matching what the existing `frontMatter` parser returns:
  - key absent → `'legacy'`;
  - a `String` value → that string exactly (case-sensitive), so `executor: ""` → `''`;
  - a `List` value → `''`. The parser returns an empty list for a bare `executor:` line and for `executor: # note`, and a list for `executor: [a]` or a block list; all of these are unsupported.
- `Task.executorBlockReason` (new here, `String?` getter): `null` when `executor == 'legacy'`; otherwise `'executor <value> is not supported by the legacy dispatcher'`, where `<value>` is the raw value or `(empty)` for `''`. Example: `executor orchestrator is not supported by the legacy dispatcher`.
- `TaskSelector.launchRefusal(Task task)` (new here, static, `String?`): `null` when `task.executorBlockReason` is null, else `'${task.id}: ${task.executorBlockReason}'`.
- `TaskSelector.blockReason` (existing, changed): order becomes done → status → executor (`task.executorBlockReason`) → skipped → busy → unknown deps → waiting deps → overlap. So a draft task reports `status is draft` first; a ready `orchestrator` task reports the executor reason.
- `_launch` (existing, changed): after finding the task and before the `isReady` check, `if (TaskSelector.launchRefusal(task) case final refusal?) { stderr.writeln(refusal); return 1; }`. No pipeline is created.
- Task format (`.agents/rules/project-tasks-format.md`): add an optional `executor:` line to the front-matter example, values `legacy | orchestrator | plan-dispatcher-v1 | handoff`, default `legacy` when absent, and one sentence per value naming who runs it (legacy: current dispatcher; orchestrator: `skill-orchestrator` with the user present; plan-dispatcher-v1: the new engine once installed; handoff: an agent in the user's session, never a dispatcher).
- Branch rule (`.agents/rules/git-commits.md`, "Branch names"): add that a branch for a task under `project-tasks/` (epic tasks and standalone `BUG-`/`IMP-` tasks alike) is `<type>/<id-lowercase>-<slug>`, where `type` is the task's front-matter `type` and `slug` is the task folder name without its `NN-` prefix, for example `feat/pld-01-02-bootstrap-python-package`. Free-form requests keep `<prefix>/<short-summary>`.
- Orchestrator (`SKILL.md`), exact edits:
  - Stage 0, after its first sentence, add: `For a task under project-tasks/, use the task branch rule in .agents/rules/git-commits.md instead.`
  - Insert this paragraph as the last paragraph of Stage 0 (before `## Stage 1`), exactly:

    ```markdown
    **Local tasks with a non-legacy executor.** When the task's front matter has an executor other than `legacy`, the checks in Stages 2, 3 and 5 are exactly the task's own `## Files and tests` commands. Run the full Flutter suite only when that section lists it. `tool/agent_check.dart`, `fvm flutter analyze` and the Dart, l10n and `fvm` rules apply only when the change touches `.dart` or ARB files.
    ```
  - Prefix exactly these four existing bullets with `For legacy tasks and free-form requests: ` (keep the rest of each bullet unchanged):
    - Stage 2: the bullet that starts `Run \`fvm dart format\` and \`fvm flutter analyze\` on the touched files`.
    - Stage 3: the bullet that starts `Run focused tests by file path while working`.
    - Stage 5: the bullet that starts `` `fvm flutter analyze` reports no issues``.
    - Stage 5: the bullet that starts `` `fvm dart tool/agent_check.dart` passes``.
  - Stage 4, in the bullet that starts `**Fix Critical and General findings**`, replace `then re-run the Stage 3 tests and \`flutter analyze\`` with `then re-run the Stage 3 checks (for a non-legacy task, its own \`## Files and tests\` commands)`.
  - No other bullet changes. The Stage 3 golden and integration bullets are already conditional and stay as they are.
- `agent-implementer.md`: prefix its three bullets about `context.l10n`/ARB, `fvm` and `fvm dart format`/`fvm flutter analyze` with `When the change touches Dart or ARB files:`, and add this bullet after them, exactly:

  ```markdown
  - For other files, run exactly the commands the task's `## Files and tests` section names.
  ```

  No Python style guide is added.
- Consumers: every later PLD task (their `executor` values); PLD-01-03 keeps the same field and values in Python.

## Behavior

- A task with no `executor` key behaves exactly as today.
- A task with any other value, including `Legacy`, `''` or an unknown word, is never in `candidates()`/`next()` and is refused by `launch <ID>`.
- Dependency, overlap and busy behavior are unchanged. `busyIds` matching needs no code change; this task adds regression tests that prove an orchestrator branch built by the new rule (`Task.branch`) is detected.
- This task itself is `legacy` and keeps running under the current three-stage runner.

## Decisions

- `_launch` must use the same executor rule as selection, so a named task cannot bypass it (cold-read finding; the alternative left a named `orchestrator` task launchable).
- Absent means `legacy`; any present value other than exactly `legacy` is unsupported, so a typo can never run under the old runner.
- The canonical branch rule covers all local tasks, including `BUG-`/`IMP-` tasks, because busy detection uses the same pattern for all of them.
- Non-legacy tasks use their own listed commands, so Python tasks are not forced through Flutter-only checks.

## Out of scope

- Any Python code, application behavior/UI/localization change, global agent settings or helper tooling.
- Changing `busyIds` matching, overlap rules or the launch pipeline stages.

## Files and tests

Changed files are exactly the `touches` list.

Tests in `test/tool/dispatcher/task_selector_test.dart` (copy the structure of the existing cases there). Extend the existing `_task` helper with `String type = 'feat'` and `String? executor`: when `executor` is not null, add the line `executor: $executor` (so `executor: ''` writes a bare `executor:` line), and use `type` in the `type:` line.

1. `executor` absent → `executor == 'legacy'`, `executorBlockReason == null`, task is a candidate.
2. `executor: legacy` → candidate.
3. For each of `orchestrator`, `plan-dispatcher-v1`, `handoff`, `Legacy`, `foo`, a bare `executor:` line (helper value `''`), `'""'` (quoted empty) and `'[a]'`: `blockReason` equals `executor <value> is not supported by the legacy dispatcher`, with `(empty)` for the three empty/list forms; not in `candidates()`.
4. A draft task with `executor: orchestrator` → `blockReason == 'status is draft'` (order check).
5. `TaskSelector.launchRefusal` returns `null` for a legacy task and `'PLD-01-02: executor orchestrator is not supported by the legacy dispatcher'` for an orchestrator task with ID `PLD-01-02`.
6. `TaskSelector.busyIdsFromBranches(tasks: tasks, branches: [...])` returns both IDs for: a task at `project-tasks/e/stories/01-s/02-bootstrap-python-package/index.md` with ID `PLD-01-02` and branch `feat/pld-01-02-bootstrap-python-package`; and a task at `project-tasks/bugs/01-crash/index.md` with ID `BUG-01`, `type: fix` and branch `fix/bug-01-crash`. Each branch is asserted equal to that task's `Task.branch` first.

Test in `test/architecture/ai_setup_test.dart`, new case in the `documented paths` group (copy a neighbor's style): `.agents/skills/skill-orchestrator/SKILL.md` contains `Local tasks with a non-legacy executor` and `` `## Files and tests` commands``; `.agents/rules/git-commits.md` contains `<type>/<id-lowercase>-<slug>`; `.agents/skills/skill-orchestrator/roles/agent-implementer.md` contains `When the change touches Dart or ARB files:`.

Commands, from the repository root:

- `fvm dart format tool/dispatcher/task.dart tool/dispatcher/task_selector.dart tool/dispatcher.dart test/tool/dispatcher/task_selector_test.dart test/architecture/ai_setup_test.dart`
- `fvm flutter analyze --no-pub tool/dispatcher/task.dart tool/dispatcher/task_selector.dart tool/dispatcher.dart test/tool/dispatcher/task_selector_test.dart test/architecture/ai_setup_test.dart`
- `fvm flutter test test/tool/dispatcher/task_selector_test.dart test/architecture/ai_setup_test.dart test/tool/dispatcher`
- `fvm dart tool/agent_check.dart --skip-build`

These are the exact forms the legacy runner allowlist permits (`.agents/skills/skill-dispatcher/references/project-overrides.md`, Common): literal paths, `--no-pub`, no bare full-suite run. The full suite runs in CI on the PR (`.github/workflows/ci.yml`).

No app launch, device test, golden or ARB change.

## Acceptance

- [ ] When a task declares any executor other than `legacy` (including empty and list values), then `blockReason` returns `executor <value> is not supported by the legacy dispatcher` and the task is never a candidate. Check: `task_selector_test.dart` cases 1–4.
- [ ] When `launch <ID>` names a non-legacy task, then it prints `<ID>: executor <value> is not supported by the legacy dispatcher` and exits 1 without starting a pipeline. Check: `task_selector_test.dart` case 5, plus `grep -n "launchRefusal" tool/dispatcher.dart` printing the call inside `_launch`.
- [ ] When a local task runs through the orchestrator on its canonical branch, then existing busy detection recognizes it. Check: `task_selector_test.dart` case 6.
- [ ] When a non-legacy task is handed to the orchestrator, then the skill tells it to use the task's own `Files and tests` commands and limits Dart/l10n rules to Dart/ARB changes. Check: new `ai_setup_test.dart` case, plus `grep -n "For legacy tasks and free-form requests" .agents/skills/skill-orchestrator/SKILL.md` printing exactly four lines.
