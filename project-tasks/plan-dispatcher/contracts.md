# PlanDispatcher shared contracts

Authoritative shared implementation contracts for this epic after split and acceptance approval. All new commands, modules and interfaces are explicitly planned outputs, not claims about existing code. Read the epic and owning story with this file. The saved interview is historical evidence; changes to these contracts require reconciliation of affected pending tasks.

## Delivery boundary

Build a self-contained Python package in `tool/plan_dispatcher/` inside Sport Timer first. It has its own `pyproject.toml`, `src/plan_dispatcher/`, packaged skill/reference assets and `tests/`. No package module imports the Flutter application or assumes its layout, commands, default branch, Git identity or model names. The eventual extraction copies this subtree to the root of `alexaniko88/plan-dispatcher`; package-relative imports/resources continue working unchanged.

Keep Sport Timer's current tools usable until equivalent Python paths pass their tests. Preserve its existing configuration and unrelated skills. The eventual cutover updates consumers and removes replaced code/tests in the same bounded changes. Add Python verification to Sport Timer CI while the package lives here; retain Flutter checks.

The current legacy dispatcher cannot execute Python/tool-installation/cross-repository tasks under its existing role boundaries. Bootstrap work must therefore have an explicit compatible runner boundary, rather than relying on `--allow` exceptions. A first legacy-compatible task adds executor metadata to the task format and loading/selection. Values are `legacy` (default for existing tasks), `orchestrator`, `plan-dispatcher-v1`, and `handoff`. All later tasks depend transitively on that gate; bootstrap and package work declare `orchestrator` (no task in this epic uses `plan-dispatcher-v1`; existing Sport Timer tasks switch to it at cutover, D56), and extraction declares `handoff`. Each dispatcher selects only its supported executor. The first task also makes the orchestrator use canonical task-ID branches for planned local tasks and the task's explicit language-appropriate check commands. This keeps orchestrated tasks visible to busy detection without repeatedly broadening old role allowlists.

Repository creation/extraction is a planned agent-operated `handoff`, not work selected by either dispatcher. Its checklist names the source subtree, destination, MIT notices, fresh initial commit (D47), verification and consumer reinstall. A Sport Timer completion PR archives the handoff task with the new repository, release tag and immutable commit as evidence; only its merge satisfies the following adoption task's dependency. No application implementation or repository creation occurs during this planning session.

## Installation and runtime

Support macOS and Python 3.9+ without external runtime/test dependencies. Use stdlib `tomllib` where available and a vendored MIT-licensed `tomli` fallback for older Python, preserving its source/version/notice. Define the supported flat scalar/string-list front-matter subset explicitly; reject unsupported constructs instead of pretending to implement all YAML. Use stdlib `unittest` with a planned local test entry point so bootstrap source tests run offline before installation. Build/release tooling is separately pinned and prepared; it is not a worker improvisation. Validate supported Python versions in CI. Do not install Python, provider applications or credentials automatically.

The release contains an installation entry point that can be invoked from the documented downloaded/cloned release with one setup command. A small optional shell bootstrap can fetch a pinned release and call that entry point; it is installer tooling, never an improvised dispatcher helper. Do not require publishing to PyPI.

Install into the following consumer paths:

- `.plan-dispatcher/config.toml`: committed project settings, schema version, selected package release and resolved source commit, selected agent integration targets, setup/check definitions and project policy.
- `.plan-dispatcher/venv/`: ignored project-local runtime and package dependencies.
- `.plan-dispatcher/local/`: ignored machine-specific host choices and prepared local package artifacts; no authoritative reservations in per-worktree copies.
- `.agents/skills/skill-planner/` and `.agents/skills/skill-dispatcher/`: committed managed skill assets.
- `.claude/skills/skill-planner` and `.claude/skills/skill-dispatcher`: relative per-skill links to canonical assets when Claude integration is selected. Never replace the entire `.claude/skills` directory.
- `docs/tasks/`: project-owned backlog and interview records, never overwritten by installation or upgrade.

Codex and Antigravity discover the canonical `.agents/skills` paths directly. Defaults show all three integrations selected, with an explicit subset override. Record checksums/ownership for managed assets. Reinstallation is idempotent; upgrades do not silently overwrite user-modified or unrelated files. Local state is never committed. Track no local machine paths in shared files.

Use a project launcher and runtime path directly; no manual environment activation. The source release/commit is fixed until an explicit update. Support two explicit installation sources: a local source subtree during bootstrap and an immutable GitHub release/commit after extraction. Both produce the same installed package/assets and ownership manifest. Fresh-clone restoration recreates the ignored runtime and leaves existing task/configuration content intact. Doctor diagnoses a stale local installation when its recorded source differs from the current source tree; it never silently updates a running version.

The installer/preparer caches the installed wheel locally; no external runtime dependencies need resolving. Before launching an agent in a fresh task clone, the engine creates that clone's runtime from the prepared artifact outside the agent process. Workers never discover a missing runtime and improvise a network install. No absolute path to the original checkout is committed or required in skill text. Failure to prepare the runtime is a setup failure before coding, not permission to switch installation designs.

An update does not mutate active run snapshots. Preserve the old runtime/artifacts while runs using that version remain active or blocked; refuse an incompatible update before changing managed files. Atomic staging/rollback keeps the previously working installation if update fails.

## Project discovery and confirmed configuration

An agent doing setup reads repository instructions, build files and existing check tooling, then proposes structured setup/check commands. The user confirms the proposal once. Python validates and persists it; it does not pretend to understand every project's framework automatically or execute arbitrary commands found in prose. Subsequent planner sessions use this configuration and repository instructions as their evidence.

Separate setup commands from checks. Setup runs in the engine-owned preparation phase and can use the network when authorized by the project configuration. Worker checks use only confirmed commands/capabilities. Package/provider availability, GitHub authentication, remote identity and project Git identity are checked before coding. Permission preflight is adapter-specific and reports limits; it is not a promise that future policy/network/service state cannot change.

Command definitions are executable plus argument arrays, never shell text. Expand file placeholders into separate argv entries. Do not pass task content through shell evaluation or allow an arbitrary executable override in a worker check request. Capture exit code, output, timeout and any known permission-denial evidence.

Policy is consumer-owned: base branch/remote, commit title conventions, optional attribution, identity requirements, leak-scan patterns, required instructions and check capabilities. Sport Timer retains its noreply identity and attribution rules in its configuration/instructions. The generic package contains no company-specific email pattern or personal account assumptions.

## Shared checker

Provide one `pd check` entry point, used by workers and by the engine's independent final verification. Run only command definitions from the approved base-commit configuration and task check plan captured before coding. Config changes in the worktree cannot broaden the commands authorized for that run. Checks for intentionally changed configuration/tooling are explicit fixture tests in that task, not automatic adoption of new privileges.

The same command also has an explicit developer mode for use outside dispatcher runs: current working-tree changes against a merge base, optional explicit paths, `--base`, and `--skip-build`. Developer mode uses the project's current confirmed configuration and is never callable as a privilege-expanding substitute for run-bound checks by a worker. A declared run context forces frozen run mode; conflicting mode/config arguments are rejected. The developer route replaces the orchestrator and human-facing `agent_check` usages as well as the dispatcher's use.

Keep the rule vocabulary bounded: named file sets with include/exclude globs, optional prefix/suffix mapping and existing-file filtering; explicitly ordered checks with any-changed-path triggers, argv file-set expansion, declared capabilities, optional groups (including builds), and explicit check/fix variants where required. Added-line scans have a pattern and failure/advisory severity; explicit paths treat every readable text line as added. No embedded Python, arbitrary expressions or general-purpose workflow language.

For Sport Timer, preserve the existing validator's observable behavior before retiring it: tracked/untracked and explicit-file input modes, merge-base comparison, generated-file exclusions, formatting and targeted analysis, mirrored tests, architecture tests, screen/ARB/AI-setup trigger checks, localization ordering, optional Android/iOS debug builds, added-line local-path failure, open-note reporting and meaningful exit codes. Preserve the documented full-suite obligation separately; changed-file checks do not replace the full suite. The mapping rules are Sport Timer configuration, not Flutter branches in Python.

Keep Sport Timer configuration and parity fixtures outside the extractable `tool/plan_dispatcher/` subtree. A shared consumer-owned case table at `test/tool/fixtures/plan_dispatcher_check_cases.json` records changed/explicit paths, existing files, build options, expected ordered checks/arguments and scan outcomes. Before retirement, the Dart tests and Python parity tests both consume it. Preserve this table and Python consumer tests after removing the Dart validator/tests. Generic package tests use synthetic framework-neutral paths.

The stable worker command is the installed local `pd check` path. Adapter setup grants/supports that entry point and normal read/edit tools rather than repeatedly adding project command prefixes. The engine's trusted final check uses its own runtime and frozen plan; worker-reported results alone cannot pass a task. This protocol reduces permission maintenance but is not an OS sandbox: configured scripts/tests execute project code and platform restrictions remain in force.

## Task contract and eligibility

Continue project-owned epic/story/task folders and stable IDs, `draft`/`ready` authoring states, dependencies, complexity, `touches`, optional skills and own-folder archiving into `done/`. New tasks use the agreed shorter required sections. Optional contracts/UI/tooling sections become required when applicable. Recognize the existing longer Sport Timer section layout without rewriting its requirements. Missing readiness evidence is a blocker to dispatch, not automatic proof that a legacy ready flag is valid.

Use `docs/tasks/` as the standard. A configured backlog path permits the temporary pre-cutover `project-tasks/` source; new setup writes the standard. Rename Sport Timer's existing tree and repair code/docs/relative links atomically, preserving IDs, statuses, archived evidence and attachments. The move does not approve existing draft work or silently change contracts.

Load candidates from the configured remote base snapshot. Resolve the default branch from origin rather than assuming `master`/`main`. Fail visibly on failed Git/GitHub lookups; never turn an unknown remote state into an empty backlog or permission to launch.

An eligible task is ready, structurally valid, has all known dependencies completed on the base branch, needs no unresolved capability, has no active/open-PR/blocked reservation, and overlaps no reserved task's declared files. Unknown dependency IDs, cycles, duplicate task IDs, missing/invalid scopes and uncheckable acceptance are explained explicitly. Preserve deterministic repository-path order among eligible tasks; do not invent an opaque priority algorithm.

No task argument: return a recommendation and reasons and obtain launch approval. Specific run request: validate the named task without repeating selection approval. An ineligible named task is never forced through. Show provider/model recommendations and allow a manual override or thread/run-scoped automatic selection before execution. Do not launch another task in the same conversation.

## One run and one lifecycle

All implementation, repair and review agents are headless provider CLI subprocesses, even when the coordinator is T3. T3 host capabilities are optional recommendation input, not an alternate executor or requirement. Use the selected provider's actually launchable CLI/model options. A host-only model is not automatically available through that provider's CLI. Unknown invocation environments select a supported CLI once, locally saved for the project.

Command boundary: see the CLI table under Fixed package interfaces (there is no `pd run`; `pd start` and `pd resume` drive the run). Expose structured JSON for skill use. One resumable Python state machine owns task execution; CLI adapters translate a stage request to a subprocess and normalize its result. Planner reviews use the same adapters read-only in the planning checkout and require neither a task clone nor task publication. Do not add a second per-stage state machine in T3 skill prose.

State progression: approved selection/model settings -> atomic reservation -> workspace/runtime preparation -> initial worker and preliminary checks -> archive/notes preparation -> candidate commit -> independent final checks -> fresh reviewer -> publish that exact candidate -> cleanup. Prepare every tracked change, including task archiving, notes and link repair, before the final check/review gate. Major errors retain local workspace/results and the reservation. Resume restarts the failed phase in that workspace under the same recorded task scope and approved settings, not a new selection. Revalidate remote/identity/auth/capabilities and any external-state changes before continuing; never silently reuse a stale review for changed code.

Use a run ID for persistence, plus an invocation/thread token kept by the coordinator. Where the host exposes a thread ID, include it. Where it does not, generate a conversation token supplied on subsequent calls; do not depend on providers' session-resume APIs. Persist launch authorization and automatic model-selection preference in that run only. A different conversation does not inherit model-selection approval merely by knowing the run ID. Reusing the project-local default CLI does not reuse task authorization.

If the original conversation is lost, a new thread can explicitly adopt a saved blocked run after verifying no stage is active and obtaining new handover/model approval (D48-D49). Preserve code and stage evidence, issue a new invocation token and do not reconstruct old conversations. `release` only releases ownership/reservation and keeps saved work; `cleanup` is the distinct deletion action. Neither can silently remove an actively executing run.

Keep an explicit repair budget: at most two fresh worker repair invocations after the initial worker, shared across failed checks and actionable review findings. Each receives only the task, preserved workspace and concrete failures/findings. Any change invalidates prior final checks/review. Each re-review is fresh. Exhausted major failures retain work and explain the blocker; minor review findings go into the PR without stopping. This proposed bound must be visible in acceptance review.

The engine validates structured reports. Worker evidence covers each acceptance criterion, with passed/failed/not-verified and a concrete check/result. A missing criterion or malformed report is not success. Reviewer results identify severity, location and evidence. Review the exact base/head commit pair. Required checks, nonempty meaningful task change, allowed scope, valid evidence and no outstanding major findings gate publication; none of these mechanically proves all semantics without review. Versioned notes contain worker/preliminary-check evidence available when the candidate is prepared. Final checker/reviewer results and minor findings live in local reports and the PR description, so recording them does not mutate the reviewed commit. Require no tracked change after final checks; generation that changes tracked files needs a new candidate and repeated checks/review within the repair policy. Publication refuses a head/tree different from the verified candidate.

## Workspace, reservation and Git ownership

Use an engine-owned clean clone for each task, at a fetched and captured base SHA, with an explicit task branch. Clone directories live outside every repository tree under the macOS per-user cache `~/Library/Caches/PlanDispatcher/workspaces/REPOSITORY_KEY/RUN/`. Only local state records their absolute paths; committed data uses no local username. Both worker and fresh reviewer receive that same clone as cwd; review is read-only by provider capability plus instructions, not a mistaken claim that a prompt universally enforces it. No T3-managed child checkout is involved. Parent-directory instructions and IDE/analyzer traversal of nested clones cannot contaminate the active checkout. The user's active checkout and branch are unchanged.

Store authoritative local run records, frozen run context, reports and reservations under `<git-common-dir>/plan-dispatcher/`, with a repository-wide lock so linked worktrees share them. Stage bindings resolve this trusted context outside the worker clone; a worker cannot substitute its edited project configuration for the frozen run configuration. Project-local metadata points to this canonical location at runtime without committing an absolute path. Atomically reserve against task ID and overlapping normalized paths; reserve after rechecking eligibility and remote state. Keep blocked reservations. Never reclaim solely because a coordinator PID vanished or a lease aged out. Status shows owner/age/reason; explicit release is a separate deliberate command. Independent clones/machines do not share local locks; remote branch/PR checks remain an additional guard. Document the first-version same-checkout/single-machine limit rather than claiming distributed locking.

Only the engine performs Git writes and GitHub publication. Prepare/commit the candidate after initial work/repair and engine-owned archive changes, before SHA-pinned final checks/review; workers/reviewers never commit/push. Validate task scope against declared `touches`, plus explicitly engine-owned task notes/archive/link edits. Scan before publication. Archive only this task, with evidence, into its parent's `done/`; on the base branch, the task counts as completed only after merge. Use a saved immutable task snapshot for subsequent checks/repair instructions when the working task file has moved. Never merge PRs, force-push, delete remote branches or push to the base branch.

Push to the canonical task branch. Before pushing, recheck the remote head; an unexpected concurrent head is a blocker, not permission to overwrite it. Save publication steps durably. PR creation is idempotent: discover an existing PR by repository/head/base, reuse it when appropriate, and do not create duplicates after an interrupted reply. GitHub description summarizes behavior, evidence, unresolved minor notes and task identity. No comments are posted.

Only remove the execution clone after the push and PR existence are confirmed and no agents are active. Keep compact local reports/publication metadata. Successful cleanup releases the reservation; the remote branch/PR continues to mark the task busy. If removal fails after publishing, return success with a cleanup warning and tracked cleanup record; `pd cleanup RUN` retries automatically managed cleanup without republishing. Major prepublication failures retain the clone and reservation, without a WIP push.

## Adapter contracts and verification

Stage request fields: run ID, role (worker/reviewer/planner reviewer), cwd, task and prompt paths, requested model/options, timeout, report schema, report destination, frozen check context and execution-policy profile. Result fields: process outcome, structured final report, stdout/stderr paths, timed-out/interrupted flag, permission denials when available and provider-specific error details. A zero exit code alone never counts as completed work.

Maintain separate Claude/Codex/Antigravity translators; pin supported CLI flag contracts in tests and fail before work when an installed version lacks required flags. Use existing user authentication, without logging credentials, changing global settings or installing providers. All invocations use argv arrays. Never use full-access/bypass flags merely to get past a denied operation. If supported unattended permissions cannot run required prepared checks, explain the mismatch before coding. Recommend only available CLI-launchable models; never silently replace an unavailable explicit model/provider.

Automated tests use fake executables/report fixtures to verify CLI arguments, parsed denials (including exit-zero soft denials), timeout/cancellation, missing executable/auth, malformed output, unavailable models and correct worker/reviewer permissions. These do not constitute live provider verification. Define a documented opt-in smoke command per installed provider; missing Claude/Antigravity CLIs on the planning machine must be reported honestly, not bypassed via native host delegates.

Use a tiny sample Git fixture consumer with Python or shell-free portable test commands, fake worker/reviewer executables, a real local bare Git remote and a fake GitHub boundary. Prove selection, reservations, changed-file checks, fix budget, staged publishing, local failure/resume and successful cleanup with no paid model or network requirement. Assert archive/link changes are included in the checked/reviewed SHA and that the pushed SHA is exactly that candidate; inject a post-check tracked change and ensure publication is refused until it is rechecked/reviewed. Test fresh-clone installation from a locally built release artifact and explicit updates, including unrelated-file protection. Separately test Sport Timer check-plan parity against existing `agent_check` fixtures before retirement. CI runs deterministic Python tests without provider credentials or live GitHub writes.

## Planner portability

Retain one-question-at-a-time interview, saved evidence/decisions, scope coverage, approved visual mockups when applicable, independent completeness review, agreed task split, explicit acceptance approval, per-task cold reads and whole-plan validation. Replace hardcoded Flutter/model/CLI command blocks with confirmed project configuration and the shared execution interface. Repository instructions remain authoritative for code conventions. The planner cannot guarantee future runtime service/permission state; readiness means settled scope, prepared capabilities and feasible named checks, not infallibility.

The reusable planner does not switch/delete the user's active branches as a prerequisite. `pd plan prepare TOPIC` prepares a dedicated external planning clone/branch with the same safe fetch/base/identity/runtime preparation, or reuses its recorded planning checkout on resume. The planner session receives that path explicitly; no native host checkout rebinding is implied. It does not sweep merged branches (D46). Publishing the completed plan still requires final user approval; dispatcher launch authorization does not apply to the planner's own PR. Preserve the distinction between draft planning and implementation authorization.

The package owns the canonical portable task-format reference. On cutover, `.agents/rules/project-tasks-format.md` becomes a thin project-owned pointer to that installed asset, so local orchestrator/project-tasks skills use the same contract. Move Sport Timer-specific planner/dispatcher guidance into project-owned configuration/references outside managed skill directories. Atomically replace live skills, retire obsolete Dart dispatcher/synchronizer/model files and update corresponding AI-setup tests; keep unrelated setup tests. The validator remains live until its separately gated parity/retirement step.

Backlog-root migration is explicitly orchestrator-run with no active or blocked task runs. It updates the root/config/readers/relative links and pending PLD task scopes in one change; archive its own task at the new `docs/tasks/` location. Neither dispatcher should try to archive that self-moving task using an old frozen root.

## Extraction and adoption proof

After the in-repo package and consumer cutover pass, the agent-operated extraction creates the approved public MIT repository with a fresh initial commit, transfers only generic sources/tests/resources plus required notices, establishes Python CI, and creates a tagged initial release from a verified commit. Do not transfer Sport Timer history or export its tasks, Firebase files, personal paths, runtime caches, local settings or project-specific policy. A Sport Timer completion PR records the immutable released commit/tag and archives the handoff task before adoption can depend on it.

Reinstall Sport Timer from that exact released source, preserving its configuration and skills not owned by PlanDispatcher. Only then remove the temporary in-repo package source and replace its CI tests with package/consumer configuration checks appropriate to the pinned release. Prove a temporary sample fixture consumer can install, plan/load tasks and execute the lifecycle fixture with the same release, then remove it (D50). Keep an executable rollback path to the last working local package/consumer configuration if adoption fails; never discard the existing backlog.

Include one explicitly planned live Codex worker/reviewer fixture smoke before consumer retirement, with local bare Git and fake GitHub. Exercise the real stable checker entry point and required cache-write/network policy in the selected sandbox; supplement deterministic adapter tests rather than claiming they prove this route. If a required capability cannot run, do not call cutover verified. Claude/Antigravity live smoke is optional and stays reported unverified unless it is run. No real GitHub fixture PR or permanent second repository is created.


## Fixed package interfaces and schemas

All symbols below are new, planned outputs fixed by this plan. P is `tool/plan_dispatcher/src/plan_dispatcher/`, T is `tool/plan_dispatcher/tests/`. Each module uses stdlib only, plain dictionaries and lists validated at boundaries, and `pathlib.Path`. Where an earlier summary in this file differs from this section, this section wins.

**Ownership rule.** This section owns every shape that more than one task produces or consumes: CLI commands, flags, exit codes and JSON data; configuration schema; state files; stage request, result and report shapes; launch request and run record; port protocols; error codes; and the public functions listed here that another task calls. A task restates none of these; it links to the heading here and adds only what is private to it (internal helpers, exact step order, messages, test names and fixtures). If a task needs a cross-task shape that differs from this section, the plan changes this section first and every affected task is reconciled; a task never silently diverges. Functions that only one task uses are that task's choice and need not appear here.

### Runner boundary for this epic

- `executor: legacy` tasks run under the current dispatcher and its project overrides (`.agents/skills/skill-dispatcher/references/project-overrides.md`, removed by PLD-05-01). Only PLD-01-01 is `legacy`.
- `executor: orchestrator` tasks are run by `skill-orchestrator` in the user's checkout, with the user present. The dispatcher's runner allowlist does not apply to them. Their allowed commands are exactly the ones named in the task's `Behavior` or `Files and tests` sections plus read-only Git (`git status`, `git diff`, `git log`, `git show`), file reads and edits inside `touches`. `python3` running `T/run_tests.py`, consumer test scripts named in the task, and `pd` from a path named in the task are allowed for these tasks.
- `executor: plan-dispatcher-v1` tasks are run by the new engine once PLD-05-01 has merged. `executor: handoff` is run by an agent in the user's session, never by a dispatcher.
- No task installs software globally, edits global provider settings or uses bypass or full-access flags.

### Package layout (PLD-01-02)

```text
tool/plan_dispatcher/
  pyproject.toml            # name "plan-dispatcher", version "0.1.0", requires-python ">=3.9", script pd = plan_dispatcher.cli:main
  README.md
  LICENSE                   # MIT, see PLD-06-01 for holder
  install.py                # bootstrap entry point, provided by PLD-04-03 (PLD-01-02 creates a stub that exits 64 "not implemented")
  build_backend/pd_build.py # in-tree PEP 517 backend: build_wheel/build_sdist using plan_dispatcher.wheel
  src/plan_dispatcher/
    __init__.py  __main__.py  cli.py  config.py  tasks.py  contracts.py  ports.py  errors.py  wheel.py  gitutil.py
    _vendor/__init__.py
    _vendor/tomli/...       # tomli 2.0.1, unmodified, with LICENSE and PROVENANCE.md
    resources/              # packaged skill assets (PLD-04-01, PLD-04-02)
    adapters/__init__.py    # registry (PLD-01-02), adapter modules added by PLD-03-02..04
  tests/
    run_tests.py  support.py  __init__.py
    fixtures/               # synthetic, framework-neutral fixture data
```

- **Build:** no third-party build tool. `wheel.py: build_wheel(project_root: Path, out_dir: Path) -> Path` (`project_root` holds `pyproject.toml` and `src/`) writes a deterministic `plan_dispatcher-<version>-py3-none-any.whl` (fixed zip timestamps 1980-01-01, sorted entries, `METADATA`, `WHEEL`, `entry_points.txt`, `RECORD` with SHA256). It includes every file under `src/plan_dispatcher/`, including `resources/**` and `_vendor/**`. `pyproject.toml` declares `build-backend = "pd_build"` with `backend-path = ["build_backend"]`, so `pip wheel`/`pip install .` work offline too. The same input tree always gives a byte-identical wheel.
- **Install of a wheel:** `python3 -m venv <dir>` then `<dir>/bin/python -m pip install --no-index --no-deps <wheel>`. Both are offline and stdlib/ensurepip only.
- **TOML:** `config.py` does `try: import tomllib` / `except ImportError: from plan_dispatcher._vendor import tomli as tomllib`. The vendored copy is tomli 2.0.1 from the PyPI sdist `tomli-2.0.1.tar.gz`; `PROVENANCE.md` records the URL, version, the sdist SHA256 shown on PyPI, and that files are unmodified. PLD-01-02 is `orchestrator`, so the user's session may download that one file; the runner verifies its SHA256 against PyPI before copying.
- **Errors:** `errors.py: class PdError(Exception)` with `code: str`, `message: str`, `exit_code: int` (1, 2 or 64). `ContractError(PdError)` always uses exit 64 (`front_matter_invalid`, `config_invalid` and every `*_invalid`).
- **Test entry:** `python3 tool/plan_dispatcher/tests/run_tests.py [module ...]` puts `src/` and `tests/` on `sys.path`, runs the named `unittest` modules (no names: discovers `test_*.py`), and exits 0 only when all pass. No installation and no network.
- **`.gitignore`:** PLD-01-02 adds `tool/plan_dispatcher/**/__pycache__/`, `tool/plan_dispatcher/dist/`, `.plan-dispatcher/venv/` and `.plan-dispatcher/local/` to the repository `.gitignore`.
- **CI:** `.github/workflows/plan-dispatcher.yml` (PLD-01-02) runs on `pull_request` and on `push` to the default branch, with paths `tool/plan_dispatcher/**`, `test/tool/test_plan_dispatcher_parity.py`, `test/tool/fixtures/plan_dispatcher_check_cases.json`, `.plan-dispatcher/**` and the workflow itself. Matrix: `macos-latest` with Python `3.9` and `3.13` (`actions/setup-python`). Steps: checkout, `python -m tests.run_tests` equivalent `python tool/plan_dispatcher/tests/run_tests.py`, and from PLD-02-02 on, the parity test. No secrets, no network beyond checkout and setup-python.

### Front matter subset (PLD-01-02, `tasks.py`)

The block between the first two `---` lines. Each non-blank line is either `key: value`, or a block list item `  - item` under a key whose value is empty. Allowed values:

- bare scalar (`ready`), single- or double-quoted string (no escapes other than `\"` and `\\` inside double quotes);
- inline list `[a, b]` or `[]` of bare or quoted scalars, no nesting;
- block list: `key:` followed by one or more `  - item` lines (any indent of at least one space).

A `#` that follows whitespace outside quotes starts a comment. Everything else is rejected with `ContractError("front_matter_invalid", "<path>:<line>: <reason>")`: duplicate keys, nested mappings, anchors, multi-line scalars, tabs as indent, a list item without a key. Unknown keys are kept in `extra` and ignored.

### Task model (PLD-01-02, `tasks.py`)

```python
load_tasks(root: Path, backlog: str, ref: Optional[str] = None, runner: Optional[CommandRunner] = None) -> list[dict]
readiness_errors(task: dict) -> list[dict]   # [{code, detail}]
task_slug(task: dict) -> str                 # folder name without its "NN-" prefix
task_branch(task: dict) -> str               # f"{type}/{id.lower()}-{slug}"
```

- A task is any `index.md` under `<backlog>/` whose front matter has `id`, except under `<backlog>/planning/`. Epic and story indexes (no `id`) are skipped. Results are sorted by repository path.
- `ref=None` reads the disk. A ref uses `git ls-tree -r --name-only <ref> -- <backlog>` and `git show <ref>:<path>` through `runner` (required when `ref` is set). A Git failure raises `PdError("git_failed", …, exit 2)`.
- Task dict: `id, title` (first `# ` line, else ""), `status` (draft|ready|done), `type` (feat|fix|improve), `complexity` (low|medium|high), `depends_on` (list), `touches` (list), `skills` (list, default []), `executor` (legacy|orchestrator|plan-dispatcher-v1|handoff, default `legacy` when absent), `path` (repo-relative path of `index.md`), `body` (text after front matter), `acceptance` (list of `{id: "A1".., text, check}` from `- [ ]`/`- [x]` lines under the `## Acceptance` heading; `check` is the text after `Check:` on that line or the next indented line, else None), `archived` (true when the task folder's parent folder is named `done`), `extra`.
- Required keys: `id, status, type, complexity, depends-on, touches`. A missing required key or a value outside its enum raises `front_matter_invalid`. Keys are matched exactly (`depends-on` in the file, `depends_on` in the dict).
- `readiness_errors` codes, all returned together: `missing_goal` (no `## Goal`), `no_acceptance`, `acceptance_without_check` (detail lists the IDs), `empty_touches`, `invalid_scope` (an entry that is empty, absolute, contains `..` or a backslash). Both the long legacy layout and the shorter layout pass if these hold; section names are not otherwise checked.

### Paths and overlap (PLD-01-03, `selection.py`)

- Normalize a scope by stripping a leading `./` and a trailing `/`. An entry that `readiness_errors` calls invalid is unsafe: the task is not eligible.
- The static prefix of a scope is the part before the first `*`, `?` or `[`, cut back to the last `/` when a wildcard follows inside a segment. A scope with no wildcard is its own static prefix and also covers everything below it.
- Two scopes overlap when one static prefix equals the other or is a directory prefix of it (`a/b` and `a/b/c.py` overlap; `a/b` and `a/bc` do not). A pattern that starts with a wildcard overlaps everything. This is deliberately conservative; it mirrors the current `task_selector.dart` intent.

### Selection (PLD-01-03)

```python
select_tasks(tasks: list[dict], done_ids: set[str], busy: list[dict], executor: str) -> dict
```

- `done_ids`: IDs of tasks that are `archived` in the base-branch snapshot (`load_tasks(root, backlog, ref="<remote>/<base>")`).
- `busy`: `[{task_id, touches, reason}]`, reason `reserved|blocked|remote_branch|open_pr`. Reservations map by `run_state`: `active`, `running`, `interrupted` and `pending_publication` → `reserved`; `blocked` → `blocked`; `done` and `released` are ignored. Reservation `touches` come from the `reservations.json` item. A busy entry never causes `scope_overlap` with its own task ID. Open PRs count only when their base is the resolved base branch. The CLI builds it from the reservations, `git ls-remote --heads <remote>` and `GitHubPort.open_prs`. A branch or PR head counts for a task when it starts with `f"{t}/{id.lower()}-"` for any `t` in `feat`, `fix`, `improve`; heads that match no task in the base snapshot are ignored.
- `selection.snapshot(root, config, runner, github) -> dict` returns `{tasks, done_ids, busy}`: the fetch, base resolution, base snapshot, `done_ids` and `busy` that `pd next` builds. `pd start` reuses it.
- `selection.check_task(snapshot, task_id, executor) -> dict` (this signature is authoritative) returns `{task, eligible, reasons}` for `pd next --task` and `pd start`; it adds the codes `archived` and `unknown_task`.
- Output: `{next: summary|None, also_ready: [summary], waiting: [{id, path, reasons: [{code, detail}]}]}`; `summary = {id, title, path, executor, complexity, type}`. Archived tasks are left out. `next` is the first eligible task in path order.
- Reason codes, all collected per task: `not_ready`, `invalid` (detail joins readiness codes), `executor_unsupported`, `duplicate_id`, `dependency_unknown`, `dependency_cycle`, `dependency_pending`, `busy_reserved`, `busy_blocked`, `busy_remote_branch`, `busy_open_pr`, `scope_overlap` (detail names the other task). Detail is plain English naming the ids or paths involved.

### Local state and reservations (PLD-01-03, PLD-03-05)

`gitutil.py: state_dir(root: Path, runner) -> Path` returns `<git rev-parse --git-common-dir>/plan-dispatcher/` of the project checkout, created on first use. Code running inside a task clone never derives the state folder from the clone: it reads the `PLAN_DISPATCHER_STATE` environment variable, which the engine sets for every stage together with `PLAN_DISPATCHER_RUN`. All files below live there.

```text
lock                        # fcntl.flock(LOCK_EX) held for every read-modify-write
reservations.json           # {"schema":1,"items":[...]}
runs/<RUN>/run.json         # run record (PLD-03-05)
runs/<RUN>/context/config.toml  task.md  plan.json   # frozen at launch by workspace.freeze_context (PLD-03-01)
runs/<RUN>/reports/<NN>-<stage>.json         # normalized stage result
runs/<RUN>/reports/<NN>-<stage>.report.json  # the adapter's parsed report (report_path)
runs/<RUN>/logs/<NN>-<stage>.stdout|.stderr
```

- Writes go to `<file>.tmp` in the same folder, `fsync`, then `os.replace`. Readers under the lock delete leftover `*.tmp` files. A corrupt JSON file raises `PdError("state_corrupt", exit 2)` and is never overwritten automatically.
- Run ID: `f"{task_id.lower()}-{UTC %Y%m%d%H%M%S}-{4 hex}"`. Invocation token: `"inv-" + 16 hex`, or `"t3:<thread-id>"` when the host gives a thread ID.
- Reservation item: `{run_id, task_id, touches, state: active|blocked, invocation, created_at, updated_at, reason}` (ISO 8601 UTC).
- `reservations.py`:
  - `reserve(root, run_id, task, invocation, busy) -> dict`: under the lock, re-runs the conflict part of selection for this one task against current reservations plus `busy`. Conflict raises `PdError("reservation_conflict", detail, exit 2)`; nothing is written.
  - `mark(root, run_id, state, reason) -> dict`: active↔blocked; marking the state the run already has is a no-op.
  - `release(root, run_id, invocation, adopt=False) -> dict`: removes the reservation, keeps the run folder and clone. Wrong invocation raises `invocation_mismatch` (exit 2) unless `adopt=True`. A run with a live `active_stage` raises `run_active` (exit 2).
  - `transfer(root, run_id, new_invocation) -> dict`: under the lock, replaces the reservation's invocation (used only by `pd resume --adopt`).
  - `list_runs(root) -> list[dict]`: `{run_id, task_id, state, phase, invocation, age_seconds, reason, workspace}`. It reads only `phase`, `workspace` and `active_stage` from `run.json` and ignores other keys.
  - `run_state(record: Optional[dict], reservation: Optional[dict]) -> str`, used by `list_runs`, `pd resume`, `pd release`, `pd cleanup` and `pd update` (PLD-03-05 reuses it and does not redefine it). First rule that matches: live `active_stage` → `active`; an `active_stage` recorded on a different host → `active` (it cannot be proven dead); dead `active_stage` → `interrupted`; phase `done`, `released` or `pending_publication` → that phase; reservation `blocked` → `blocked`; reservation `active` → `running`; otherwise `released`.
  - `reserve`, `mark`, `release`, `transfer` and `list_runs` take a keyword `runner=None` (default `SubprocessRunner()`, used only for `state_dir`). Extra codes: `task_not_eligible`, `checks_failed`, `checks_blocked`.
  - `release`, `mark` and `transfer` of a run with no reservation raise `unknown_run` (exit 2). `reserve` rechecks only conflicts (same task ID, a `busy` entry, scope overlap) and always uses the single code `reservation_conflict`.
- `gitutil.resolve_base(root, remote, base_branch, runner) -> str` (PLD-01-03): a configured name is returned as is. For `auto`, try `git symbolic-ref --short refs/remotes/<remote>/HEAD` (strip `<remote>/`), then the `ref: refs/heads/<name>\tHEAD` line of `git ls-remote --symref <remote> HEAD`. If both fail, raise `base_branch_unknown` (exit 2) telling the user to set `project.base_branch`. PLD-02-01, PLD-03-01 and PLD-04-01 use it.
- Frozen `plan.json`: `{schema: 1, run_id, workspace, base_sha, skip_groups, include_groups, allowed_scope, caches: [ids], network: bool}`. `pd check --run` computes the check plan itself from the frozen config and the current workspace diff; `plan.json` only fixes the options and scope.
- "Active" means `run.json.active_stage` is set and its `pid` or its child process group `pgid` is alive on the same `host` (`socket.gethostname()`). `active_stage` is `{name, pid, pgid, host, started_at}`; `pgid` is the provider CLI's process group, so a killed `pd` with a still-running provider stays `active`. A set `active_stage` with a dead PID is `interrupted`; it is never released or cleaned automatically.

### GitHub boundary (PLD-01-03 read, PLD-03-06 write; `github.py`, `ports.py`)

```python
class GitHubPort(Protocol):
    def open_prs(self, repo: str) -> list[dict]          # [{number, head, base, url, head_sha}]
    def find_pr(self, repo: str, head: str, base: str) -> Optional[dict]
    def create_pr(self, repo: str, head: str, base: str, title: str, body: str) -> dict  # {number, url}
```

`github.GhCli(runner)` implements it (PLD-01-03 provides `open_prs` and `find_pr`; PLD-03-06 adds `create_pr`) with `gh pr list --repo R --state open --json number,headRefName,baseRefName,url,headRefOid --limit 1000` (exactly 1000 rows raises `github_unavailable`, "open PR list may be cut off") and `gh pr create --repo R --head H --base B --title T --body-file F`. `repo` is `project.github_repo` (`owner/name`). Any non-zero `gh` exit raises `PdError("github_unavailable", exit 2)`. PRs are never drafts. Pushes use `git push <remote> <sha>:refs/heads/<branch>` through `CommandRunner`, not `GitHubPort`.

### Command runner (PLD-01-02, `ports.py`)

```python
class CommandRunner(Protocol):
    def run(self, argv: list[str], cwd: Path, env: Optional[dict] = None, timeout_seconds: Optional[int] = None,
            stdin: Optional[str] = None, stdout_path: Optional[Path] = None, stderr_path: Optional[Path] = None,
            on_start: Optional[Callable[[int], None]] = None) -> dict
```

Result `{exit_code, stdout, stderr, timed_out}` (a child ended by a signal reports a negative `exit_code`, as `subprocess` does) (stdout/stderr are the text, also written to the paths when given). `SubprocessRunner` starts the child with `start_new_session=True`; on timeout it sends SIGTERM to the process group, waits 10 s, then SIGKILL, and waits for exit before returning `timed_out: true, exit_code: None`. `env=None` inherits the parent environment. `on_start(child_pid)` is called right after the child starts; because of `start_new_session` the PID is also the process group ID (`FakeRunner` calls `on_start(99999)` when given). `SubprocessRunner.run` raises `PdError("executable_not_found", argv[0], 2)` when `argv[0]` cannot be started. `FakeRunner` script entries may raise an exception instead of returning a result. `T/support.py` provides `FakeRunner(script)`: each entry is `(matcher, result_or_exception)`; `matcher` is an argv-prefix list or a callable `argv -> bool`. Each call searches forward from the first unused entry for the first match, marks it used, and returns `{"exit_code": 0, "stdout": "", "stderr": "", "timed_out": False}` updated with the entry's dict (or raises the entry's exception), writing `stdout`/`stderr` to `stdout_path`/`stderr_path` when given. No match raises `AssertionError("unexpected call: <argv>")`; leftover entries are not a failure. Calls are recorded in `.calls` as `{argv, cwd, env, timeout_seconds, stdin}`. `FakeGitHub(prs=None, fail=None, remote=None, lose_create_reply=False)` (PLD-01-02; PLD-03-06 adds the last two): with `remote` set, `head_sha` is read from that bare remote; `lose_create_reply` creates the PR but raises on the reply, to test idempotent retries. `prs` is a list of `{number, head, base, url, head_sha}`; `fail` maps a method name to an exception raised on every call to it; `.calls` records `(method, args)`; `create_pr` appends a PR numbered after the existing ones, with `url = "https://example.invalid/pr/<n>"` and `head_sha` from `set_head(branch, sha)` (`""` when unset); `set_head` also updates existing PRs with that head. It also provides `make_git_repo(tmp) -> Path` (initialized repo with one commit on `main` and a bare remote `origin`) and `fake_executable(dir, name, script_text) -> Path` (writes an executable `/usr/bin/env python3` script).

### CLI (PLD-01-02 envelope; each command's owner adds it)

`cli.py: main(argv=None, ports=None) -> int`, also `python -m plan_dispatcher`. `ports` is an optional dict with the lifecycle `ports` keys (`runner`, `github`, `adapters`, `get_adapter`, `clock`, `cache_root` — optional `Path`, default `~/Library/Caches/PlanDispatcher`, used by `pd plan prepare` and `pd start` — …); missing keys get production defaults (`SubprocessRunner()`, `GhCli(runner)`, the adapter registry). Success output goes to stdout. Failure output goes to stderr as `error <code>: <message>` (plain) or to stdout as the envelope (`--json`). `data` on failure is `null`, except for commands that document failure data (`pd check` report, `pd next --task` result, `pd plan review` result, `pd start`/`pd resume` run summary), which keep it. Command registry: `cli.COMMANDS: dict[str, Command]` with `Command(name, add_arguments(parser), run(args, ports) -> dict)`; `run` returns `data` or raises `PdError`. Each owner task replaces its stub entry in that dict. `json_mode` is `"--json" in argv` (any position); `--json` is removed before parsing, so REMAINDER stubs and `usage` errors still produce the envelope. Default `ports["github"]` is resolved lazily by `cli.ports_github(ports)`, which raises `not_implemented` (64) until `plan_dispatcher.github` exists. Every command accepts `--json`. JSON envelope: `{schema: 1, ok, data, warnings: [], error?: {code, message}}`. Without `--json` the same content is printed as short plain English. Exit codes: 0 success (also "no eligible task"), 1 failed check or operation, 2 blocked prerequisite or refusal, 64 invalid usage. Argparse errors are caught and returned as exit 64 with code `usage`. A command whose owner has not merged returns exit 64, code `not_implemented`.

| Command | Owner | Data on success |
| --- | --- | --- |
| `pd doctor [--provider P ...]` | PLD-03-01 | doctor result below; exit 2 when `blockers` is not empty |
| `pd next [--task ID]` | PLD-01-03 | selection output; with `--task`, `{task, eligible, reasons}` and exit 2 when not eligible |
| `pd status [RUN]` | PLD-01-03 | `{runs: list_runs()}` or one run |
| `pd release RUN --invocation T [--adopt]` | PLD-01-03 | `{run_id, released: true}` |
| `pd check …` | PLD-02-01 | check report below |
| `pd start --request PATH\|-` | PLD-03-05 | run summary `{run_id, phase, outcome, blocker?, pr_url?}` |
| `pd resume RUN --invocation T [--adopt --request PATH] [--answer TEXT]` | PLD-03-05 | run summary; a `worker_blocked` run without `--answer` fails with exit 64, code `answer_required`. `candidate_changed`, `leak_detected` and `pending_publication` restart at `candidate` |
| `pd cleanup RUN` | PLD-03-06 | `{run_id, removed, warning?}` |
| `pd recommend --task ID` or `pd recommend --role planner-review --complexity C` | PLD-04-02 | recommendation below |
| `pd request --task ID --worker P:M:E --reviewer P:M:E --selection S [--auto-model] [--invocation T] [--host-kind K] [--thread-id X] --out PATH` | PLD-04-02 | `{request, path}` |
| `pd plan prepare TOPIC` / `pd plan review --plan PLAN_ID PATH --role interview\|cold --provider P --model M [--effort E]` | PLD-04-01 | see planner section |
| `pd install`, `pd restore` | PLD-04-03 | see installer section |
| `pd update --source …` | PLD-04-04 | see update section |

There is no `pd run` command: `pd start` runs a new launch to a terminal phase and `pd resume` continues a saved run.

### Configuration schema 1 (PLD-01-02 loads and validates; owners fill values)

File: `<root>/.plan-dispatcher/config.toml`. `config.load_config(root) -> dict` validates all of it and raises `ContractError("config_invalid", "<key path>: <reason>")` (exit 64) for: missing required table or key, wrong type, unknown enum value, duplicate id, unknown file-set reference, cyclic `union`, an invalid regex, an absolute or `..` path, or an argv that is not a non-empty list of strings. Unknown keys are errors. Missing file raises `PdError("needs_setup", exit 2)`.

```toml
schema = 1

[project]
name = "example"              # free text
backlog = "docs/tasks"        # repo-relative
remote = "origin"
base_branch = "auto"          # "auto" = origin HEAD, else a branch name
github_repo = "owner/name"    # identity check and gh --repo

[distribution]
source_kind = "local"         # local | git
source = "tool/plan_dispatcher"   # local: repo-relative path; git: https clone URL
source_ref = ""               # git: tag; local: ""
source_commit = ""            # git: 40-hex commit; local: ""
content_digest = "sha256:…"   # digest of the source tree that was installed
version = "0.1.0"

[integrations]
tools = ["claude", "codex", "antigravity"]   # non-empty subset

[instructions]
paths = ["AGENTS.md"]         # repo-relative files the planner and workers must read

[[setup.commands]]            # zero or more, run in order by the engine before the worker
id = "deps"
argv = ["npm", "ci"]
network = false
timeout_seconds = 900

[[validation.file_sets]]
id = "py"
include = ["src/**/*.py"]     # globs: * within a segment, ** any segments, ?
exclude = []
source_prefix = ""            # mapping: all four optional; when source_prefix is set, only
target_prefix = ""            # paths starting with it and ending with source_suffix map to
source_suffix = ""            # target_prefix + middle + target_suffix; others are dropped
target_suffix = ""
existing_only = false         # drop paths that do not exist after mapping
source_must_exist = false     # drop changed paths that no longer exist, before mapping
# fixed-set form (instead of include/mapping): fixed = [paths], when_any = [set ids]; the set is `fixed` when any listed set is non-empty
union = []                    # ids of other sets; a set with union has no include/exclude/mapping

[[validation.checks]]
id = "tests"
argv = ["python3", "-m", "pytest", "{files:py_tests}"]
trigger_any = ["py"]          # run when any listed set is non-empty; [] = always
run_without_files = false     # when argv has {files:…} tokens and all are empty, skip unless true
group = ""                    # optional group name, e.g. "build"
phases = ["worker", "final"]  # subset of worker|final
variant = "check"             # check | fix; fix is only allowed with phases = ["worker"]
needs = []                    # capability ids from policy.caches plus "network"
timeout_seconds = 900

[[validation.scans]]
id = "local-path"
pattern = "…"                 # Python re, compiled at load
severity = "failure"          # failure | advisory
include = ["**"]
exclude = []

[validation]
default_skipped_groups = []

[policy]
commit_subject_pattern = "^(feat|fix|refactor|chore|docs|style|perf|test|build): \\S"
attribution_template = ""     # optional trailer, placeholders {tool} {model}
pr_title_template = "{type}: {title}"
required_email_suffix = ""    # "" = no requirement
leak_scans = []               # [{id, pattern}] applied to the whole candidate diff before push

[[policy.caches]]             # writable paths a worker sandbox may need, home-relative
id = "pub-cache"
path = "~/.pub-cache"

[[models.candidates]]
role = "worker"               # worker | reviewer | planner-review
complexity = "any"            # low | medium | high | any
provider = "codex"            # claude | codex | antigravity
model = "gpt-6.1-terra"
effort = "medium"
rank = 1
```

- `config.py` defines `SCHEMA_VERSION = 1` as a plain top-level line (PLD-04-04 reads it as text). `config.load_config` raises `PdError("needs_setup", exit 2)` when the file's first line is `# needs_setup: commands not confirmed` (written by an unconfirmed install). `config.load_config_file(path)` loads a frozen copy. `content_digest = "sha256:pending"` is accepted only with `source_kind = "local"` before the first install.

**Required and optional keys.** R = required; O = optional, default shown. Unknown keys are errors.

| Table / item | Keys |
| --- | --- |
| top level | `schema` R, must equal 1 |
| `[project]` R | `name` R; `github_repo` R (`owner/name`, or `local/<name>` for fixtures); `backlog` O `"docs/tasks"`; `remote` O `"origin"`; `base_branch` O `"auto"` |
| `[distribution]` R | `source_kind` R (`local`\|`git`); `source` R; `version` R; `content_digest` R (`sha256:` + 64 hex, or `sha256:pending` only with `local`); `source_ref` O `""` (non-empty for `git`); `source_commit` O `""` (40 lowercase hex for `git`, `""` for `local`) |
| `[integrations]` R | `tools` R, non-empty, unique, subset of `claude`, `codex`, `antigravity` |
| `[instructions]` R | `paths` R, list (may be empty) of repo-relative files |
| `[[setup.commands]]` O | `id` R; `argv` R; `network` O false; `timeout_seconds` O 900 (int 1..86400) |
| `[validation]` R | `file_sets` O []; `checks` O []; `scans` O []; `default_skipped_groups` O [] |
| file set, pattern form | `id` R; `include` R non-empty; `exclude` O []; `source_prefix`, `target_prefix`, `source_suffix`, `target_suffix` O `""`; `source_must_exist` O false; `existing_only` O false |
| file set, union form | `id` R; `union` R non-empty; `existing_only` O false; no other keys |
| file set, fixed form | `id` R; `fixed` R non-empty list of repo-relative paths; `when_any` R non-empty; `existing_only` O false; no other keys |
| check | `id` R; `argv` R; `trigger_any` O []; `run_without_files` O false; `group` O `""`; `phases` O `["worker", "final"]` (non-empty subset); `variant` O `"check"`; `needs` O []; `timeout_seconds` O 900 |
| scan | `id` R; `pattern` R; `severity` R; `include` O `["**"]`; `exclude` O [] |
| `[policy]` R | `commit_subject_pattern` R (regex); `attribution_template` O `""`; `pr_title_template` O `"{type}: {title}"`; `required_email_suffix` O `""`; `leak_scans` O [] (each `{id R, pattern R}`, regex); `caches` O [] (each `{id R, path R}`, path starts with `~/`) |
| `[models]` R | `candidates` O []; each `role` R (`worker`\|`reviewer`\|`planner-review`), `complexity` R (`low`\|`medium`\|`high`\|`any`), `provider` R, `model` R, `effort` R (`low`\|`medium`\|`high`\|`xhigh`\|`max`), `rank` R (int ≥ 1) |

**Cross-reference rules.** IDs are unique within each list (setup commands, file sets, checks, scans, caches, leak scans). `trigger_any`, `union`, `when_any` and `{files:NAME}` name existing file sets; cycles through `union` or `when_any` are invalid. `{files:NAME}` must be a whole argv token. `needs` entries are `network` or a `policy.caches` id. `default_skipped_groups` entries name a group some check uses. A candidate's `provider` must be in `integrations.tools`. A `fix` variant requires `phases = ["worker"]`. String values are non-empty unless their default is `""`. Paths are repo-relative with no `..`, absolute form or backslash. Validation stops at the first error, in file order.

- File set evaluation: input is the change list. `include`/`exclude` match the original path; mapping follows; then `existing_only` uses `options["exists"]` (default: file exists under root). Output is sorted and de-duplicated. A `union` set is the sorted, de-duplicated union of its members.
- `{files:NAME}` must be a whole argv token and expands into one argv entry per path.
- Scans run on added lines of text files only (a file with a NUL byte in its first 8 KB is binary and skipped). Explicit paths treat every line as added. Evidence is `{scan_id, path, line}`; the matched text is never printed.

### Checker (PLD-02-01, `checks.py`, `diff.py`)

```python
diff.changed_files(root, base: str, runner) -> list[dict]     # [{path, status: added|modified|deleted|renamed|untracked, old_path?}]
diff.added_lines(root, base: str, paths, runner) -> dict[str, list[tuple[int, str]]]
checks.build_check_plan(config: dict, changes: list[dict], options: dict) -> list[dict]
checks.run_checks(context: dict, runner) -> dict
```

- Developer changes: `git merge-base HEAD <base>` (default base: `<remote>/<base_branch>`), then tracked changes from `git diff --name-status -M <merge-base>` plus untracked files from `git ls-files --others --exclude-standard`. Explicit paths replace the change list with `{path, status: "modified"}` entries.
- Run-mode changes: diff of the workspace against the run's `base_sha`, same commands.
- `options`: `{phase: "worker"|"final"|"developer", skip_groups: [..], include_groups: [..], exists: callable}`. Developer phase runs checks whose `phases` include `worker`. Skipped groups = `default_skipped_groups` + `skip_groups` − `include_groups`.
- Explicit paths are normalized before use: trim, `\` to `/`, strip a leading `./`, de-duplicate, sort. `checks.scan_lines(config, added) -> list[dict]` applies the scans to an added-lines map and is shared by `run_checks` and publication leak scans.
- Plan entry: `{id, argv, status: "planned"|"skipped", skip_reason?}`; plan order = config order. Final phase drops `variant = "fix"` checks.
- `run_checks` runs planned entries in order and does not stop at a failure. Each result: `{id, argv, status: passed|failed|skipped|blocked|timed_out, exit_code, duration_ms, stdout_path, stderr_path}`. An executable that cannot be found gives `blocked`. Report: `{ok, mode, phase, checks, scans: [{scan_id, path, line, severity}], blocked: bool, generated_changes: [paths]}`. `ok` is true only when no check failed, timed out or was blocked, and no failure-severity scan matched.
- Final phase snapshots `git status --porcelain=v1 --untracked-files=all` and `git rev-parse HEAD` before and after; any difference fills `generated_changes` and sets `ok` false.
- `pd check` developer form: `pd check [--base REF] [--skip-build] [--skip-group G ...] [--include-group G ...] [PATH ...]`. `--skip-build` means `--skip-group build`.
- `checks.normalize_paths(paths) -> list[str]` implements the explicit-path normalization above and is used by consumer parity tests.
- The report adds `logs_dir`; log files are `<NN>-<check id>.stdout|.stderr` (two-digit plan position); skipped checks have `None` log paths. Skip-reason precedence: `fix_in_final`, `phase`, `group_skipped`, `not_triggered`, `no_files`.
- `added_lines` uses one whole-tree `git diff -U0 -M`, so a rename counts only changed lines; file sets see only the new path.
- Run-mode logs: the engine's own `checking` and `final_checks` write to `runs/<RUN>/logs/`. A worker's `pd check --run` (detected by `PLAN_DISPATCHER_RUN` in its environment) only reads the frozen context and writes its logs to `<workspace>/.plan-dispatcher/local/check-logs/`, which is inside the sandbox and excluded from Git. The state folder is never writable by a worker. Engine-run checks (`checking`, `final_checks`) do not set `PLAN_DISPATCHER_RUN` in the check environment; only a worker's environment has it.
- Run form: `pd check --run RUN [--phase worker|final]` (default worker). It reads the frozen `context/config.toml` and `context/plan.json` from the state dir, never the workspace config. When the environment has `PLAN_DISPATCHER_RUN`, run mode is forced with that run ID; `--base`, `--include-group`, explicit paths or a different `--run` then fail with exit 64, code `mode_conflict`. `--skip-build`/`--skip-group` are accepted in run mode only if the frozen plan lists that group as skipped already.
- Exit precedence: 2 when any check is blocked or the run context is missing; else 1 when a check failed or timed out, a failure scan matched or `generated_changes` is non-empty; else 0. 64 usage.

### Workspace, runtime and doctor (PLD-03-01)

```python
workspace.repository_key(remote_url: str) -> str    # "<repo-name>-" + first 12 hex of sha256(remote_url)
workspace.prepare_workspace(root, task, run_id, config, artifact, runner, cache_root=None) -> dict
runtime.prepare_runtime(workspace_path, artifact, runner) -> dict
preflight.doctor(root, config, adapters, runner) -> dict
workspace.parse_github_repo(remote_url: str) -> str     # "owner/name", "local/<folder name>" for a local path remote, "" otherwise
workspace.workspace_path(root, config, run_id, cache_root=None) -> Path   # used by resume to delete a partial clone after a preparation failure
workspace.clone_at(root, config, branch, path, runner) -> dict   # identity check, fetch, base, clone, `checkout -b branch` at base_sha, exclude entries, clone identity; returns {path, base_sha, base_branch, branch, git_identity}. prepare_workspace calls it with task_branch(task); the planner calls it with the plan branch
workspace.freeze_context(root, run_id, config_path, task, base_sha, workspace, options, runner) -> Path   # `workspace` = the clone path written into plan.json
runtime.content_digest(tree: Path) -> str ; runtime.load_artifact(root) -> dict
```

- `cache_root` default `~/Library/Caches/PlanDispatcher`; tests pass a temp folder. Clone path `<cache_root>/workspaces/<key>/<run_id>/`. An existing folder there that is not this run's recorded workspace raises `workspace_collision` (exit 2); `pd resume` reuses the recorded one.
- Steps: `git fetch <remote>`; resolve base with `gitutil.resolve_base`; capture `base_sha`; `git clone --no-hardlinks <remote-url> <path>`; `git checkout -b <task_branch(task)> <base_sha>`; write `.plan-dispatcher/venv/` and `.plan-dispatcher/local/` into the clone's `.git/info/exclude`; set `user.name`/`user.email` in the clone from the active checkout's `git config user.name/user.email`.
- Identity check: `parse_github_repo(remote URL)` must equal `project.github_repo` (https, ssh or, for fixtures, a local path whose `github_repo` is `local/<folder name>`) else `remote_mismatch`; the email must end with `policy.required_email_suffix` when that is set, else `identity_mismatch`.
- Return: `{path, base_sha, base_branch, branch, git_identity: {name, email}, runtime_path, pd_path}`. `pd doctor` lists only providers whose adapter module imports; a provider without an adapter yet gives a warning, not a blocker.
- `prepare_workspace` is the only preparation entry point: it calls `clone_at`, then `freeze_context(root, run_id, ".plan-dispatcher/config.toml", task, base_sha, path, {}, runner)`, then `prepare_runtime`, then the setup commands from the frozen config, in that order. The lifecycle calls only the `workspace` port. `clone_at` itself does the `workspace_unsafe` and `workspace_collision` checks and reads the remote URL, so the planner gets them too. If preparation fails after the clone, resume deletes that run's partial clone and frozen context (both engine-owned, no worker work exists yet) and runs `prepare_workspace` again. The clone path must not be inside root, and root must not be inside it (`workspace_unsafe`); being under the home folder is fine. `prepare_workspace` runs only for new runs; `pd resume` reuses the recorded workspace. `plan.json` `caches` is the union of every check's `needs` minus `network`; `network` is whether any check needs it. Extra codes: `workspace_unsafe`, `context_missing`, `context_exists`.
- Artifact manifest `.plan-dispatcher/local/artifact.json`: `{schema: 1, version, source_kind, source, source_commit, content_digest, wheel_path, wheel_sha256}`. `wheel_path` is absolute (the file is local-only). Wheels live in `.plan-dispatcher/local/artifacts/<version>-<first 12 hex of content_digest>/`, so two builds with the same version never share a folder. `prepare_runtime` verifies the wheel SHA256, creates `<workspace>/.plan-dispatcher/venv`, installs the wheel offline, and returns `{runtime_path, pd_path}`. Failure raises `runtime_failed` (exit 2) and is a setup failure, not a worker failure.
- Setup commands run after the runtime, in order, with `cwd` = workspace. Logs go to `runs/<RUN>/logs/00-setup-<id>.*`. A failure raises `setup_failed` (exit 2) naming the command id. A command with `network = false` runs normally; the flag is a declaration that is shown to the user at setup approval, not an OS sandbox.
- Doctor result: `{providers: {name: describe()}, git: {remote_url, github_repo_ok, email, identity_ok}, gh: {installed, authenticated}, runtime: {artifact_ok, stale}, caches: {id: writable}, blockers: [{code, message}]}`. Blocker codes: `binary_missing`, `auth_missing`, `version_unsupported`, `flag_unsupported`, `model_unavailable`, `gh_missing`, `gh_auth_missing`, `remote_mismatch`, `identity_mismatch`, `artifact_missing`, `artifact_stale` (for `source_kind = "local"`, `runtime.content_digest` over `<root>/<distribution.source>` differs from the manifest; a local `source` must therefore be the package tree itself, the folder with `pyproject.toml`, never the consumer root), `cache_not_writable`, `needs_setup`.

### Stage protocol (PLD-01-02 validates; adapters PLD-03-02..04)

Request (`contracts.validate_stage_request`): `{schema: 1, run_id, role: worker|reviewer|interview|cold, cwd, prompt_path, report_path, schema_path, provider, model, effort, timeout_seconds (default 2700), permission_profile, env: {}, stdout_path, stderr_path, criterion_ids: [..]}`. `criterion_ids` is the task's acceptance IDs in order: required and non-empty for `worker`, `[]` for other roles.

`permission_profile` is a dict: `{mode: "write"|"read", pd_path: str|None, extra_write_dirs: [absolute paths], network: bool}`. Workers get `write`; reviewer, interview and cold get `read` with no extra dirs. `extra_write_dirs` come only from the frozen config `policy.caches` that a planned check `needs`; `network` is true only when a planned check needs `network`.

Adapter API (`adapters/<name>.py`, resolved by `adapters/__init__.py: get_adapter(name, runner, executable=None)`, which imports `plan_dispatcher.adapters.<name>` by name, so adapter tasks never edit `__init__.py`; an import failure raises `PdError("adapter_unavailable", exit 2)` and an unknown provider name raises `PdError("unknown_provider", exit 64)`):

```python
class Adapter:
    name: str
    def __init__(self, runner: CommandRunner, executable: Optional[str] = None): ...
    def describe(self, models: list[str]) -> dict
    def invoke(self, request: dict) -> dict
```

`describe` result: `{binary: path|None, version: str|None, version_ok: bool, auth: "ok"|"missing"|"unknown", flags_ok: bool, missing_flags: [..], models: [{id, availability: verified|configured|unavailable}]}`. Prompts go on stdin for Claude and Codex. Antigravity does not read stdin (probed with agy 1.5.3), so its prompt is one `-p=<prompt>` argv entry. Antigravity `--mode auto` is not available on the planning account (it falls back silently), so its worker uses `accept-edits` with a session-only `--settings` allow list. The adapter writes the parsed report JSON to `report_path` when valid.

Normalized result: `{schema: 1, process_ok, report_valid, report, exit_code, timed_out, interrupted, stdout_path, stderr_path, denied_actions: [{tool, detail}], provider_error: None | {code, message}}`. `interrupted` is true when the child ended by a signal the engine did not send. Error codes: `binary_missing`, `version_unsupported`, `flag_unsupported`, `timeout`, `interrupted`, `output_missing`, `output_malformed`, `report_invalid`, `provider_failed`, `capability_fallback`, `reviewer_mutated` (set by the caller of a read-only stage when `git status` or HEAD changed). `process_ok` is true only for exit 0, not timed out, and no provider error. `report_valid` is true only when the report passes the role validator in `contracts.py`. Messages keep at most the last 2000 characters of stderr, with any value of an environment variable whose name contains `TOKEN`, `KEY` or `SECRET` replaced by `***`.

Reports (`contracts.validate_worker_report`, `validate_reviewer_report`, `validate_review_verdict`):

- Worker: `{summary, evidence: [{criterion_id, status: passed|failed|not_verified, check_ids: [..], details}], open_notes: [..], blocked: None | {code, details, question}, commit_subject}`. Every task criterion ID must appear exactly once.
- Reviewer: `{summary, findings: [{severity: critical|general|minor, file, line: int|None, summary, fix}]}`. `critical` and `general` are major; `minor` is not.
- Interview/cold: `{verdict: ready|not_ready, questions: [{location, question}]}`.
- Role to validator: `worker` → `validate_worker_report(report, request["criterion_ids"])`, `reviewer` → `validate_reviewer_report`, `interview` and `cold` → `validate_review_verdict`.
- Adapters read the prompt from `prompt_path`. The first matching failure rule sets `provider_error`. `denied_actions` is always collected and never sets `provider_error` on its own; the lifecycle decides whether a denial blocks. `exit_code` is None on timeout. `invoke` never calls `describe`; the engine runs `doctor` before any stage.

**Validator rules (`contracts.py`).** Every validator rejects unknown and missing keys, checks types, and raises `ContractError("<kind>_invalid", "<key path>: <reason>")` (exit 64). Kinds: `launch`, `stage_request`, `stage_result`, `worker_report`, `reviewer_report`, `review_verdict`.

- Launch: all keys required. `schema` 1; `task_id` non-empty; `invocation` matches `^(inv-[0-9a-f]{16}|t3:.+)$`; `approved` must be `true`; `selection` `recommended`|`override`|`named`; `auto_model` bool; `worker` and `reviewer` each `{provider: claude|codex|antigravity, model: non-empty, effort: low|medium|high|xhigh|max}`; `host` `{kind: t3|claude|codex|antigravity|unknown, thread_id: string or null}`.
- Stage request: all keys required. `role` as above; `cwd`, `prompt_path`, `report_path`, `schema_path`, `stdout_path`, `stderr_path` absolute; `timeout_seconds` int 1..86400; `env` string→string; `effort` as above; `permission_profile` `{mode: write|read, pd_path: absolute or null, extra_write_dirs: [absolute], network: bool}`; mode `read` requires empty `extra_write_dirs` and `network: false`; role `worker` requires mode `write`, other roles mode `read`.
- Stage result: all keys required; `report` is null unless `report_valid`; `provider_error` null or `{code, message}` with a code from the adapter list; `process_ok` is false whenever `provider_error` is set.
- Worker report: `evidence` covers each expected criterion ID exactly once and no other; `check_ids` list of strings (may be empty); `open_notes` list of strings; `blocked` null or `{code, details, question}` (non-empty strings); `commit_subject` non-empty when `blocked` is null, may be `""` when blocked.
- Reviewer report: `findings` may be empty; `file` non-empty; `line` int ≥ 1 or null.
- Review verdict: `verdict` `ready`|`not_ready`; `questions` is empty when `ready`.
- The JSON Schema files for these live in `P/resources/schemas/{worker,reviewer,review_verdict}.schema.json` (PLD-01-02) and are passed to the CLIs.

Pinned CLI routes, checked by `describe` from `--help` text and `--version`:

| Provider | Minimum | Worker argv (prompt on stdin) | Read-only argv | Result source |
| --- | --- | --- | --- | --- |
| Claude | 2.1.319 | `claude -p --output-format json --json-schema <schema text> --model M --effort E --setting-sources project --no-session-persistence --permission-mode acceptEdits --allowedTools Read Edit Write Glob Grep "Bash(<pd_path> check:*)" "Bash(git status:*)" "Bash(git diff:*)" "Bash(git log:*)" [--add-dir D ...]` | same base with `--permission-mode plan --allowedTools Read Glob Grep "Bash(git diff:*)" "Bash(git log:*)" "Bash(git show:*)"` | stdout JSON: `type == "result"`, `is_error`, `structured_output`, `permission_denials[{tool_name, tool_input}]` |
| Codex | 0.167.0 | `codex exec --ignore-user-config --ephemeral -C <cwd> -m M -c model_reasoning_effort="E" -s workspace-write -c approval_policy="never" --output-schema <schema_path> -o <report_tmp> --json [--add-dir D ...] [-c sandbox_workspace_write.network_access=true] -` | same with `-s read-only` and no `--add-dir`/network | `-o` file is the report; stdout JSONL events `turn.failed`/`error` → `provider_failed`; `item.completed` with `item.type == "command_execution"` and `item.status == "declined"` → denial |
| Antigravity | 1.5.3 | `agy --sandbox --mode accept-edits --settings '{"permissions":{"allow":["command(<pd_path> check)","command(git status)","command(git diff)","command(git log)"]}}' --model M --effort E --output-format json --json-schema <schema_path> --print-timeout <max(timeout_seconds-30,1)>s [--add-dir D ...] -p=<prompt>` | same with `--mode plan --settings '{"permissions":{"allow":["command(git diff)","command(git log)","command(git show)"]}}'` and no `--add-dir` | stdout JSON: `status` (`SUCCESS` else failure), `structured_output` (`null` → `output_missing`); stderr line with `is not available` and `continuing in the default mode` → `capability_fallback`; stderr lines containing `auto-denied` → denial |

- Auth probes: `claude auth status` (JSON `loggedIn`), `codex login status` (exit 0), Antigravity has none (`unknown`).
- Model discovery: Antigravity `agy models` (first column) gives `verified`; Claude and Codex have no discovery command, so configured IDs are `configured`.
- The Codex and Antigravity worker routes are the ones the live Codex smoke (PLD-05-03) confirms. If real output differs from these fixtures, the adapter is fixed before retirement; tests are not loosened.
- The engine owns the CLI's own timeout (`--print-timeout`) at `timeout_seconds - 30`, and the process-group timeout at `timeout_seconds`.

### Launch request and run record (PLD-03-05)

Launch request (`contracts.validate_launch`), passed to `pd start --request`:

```json
{"schema": 1, "task_id": "PLD-01-03", "invocation": "inv-…", "approved": true,
 "selection": "recommended", "auto_model": false,
 "worker": {"provider": "codex", "model": "…", "effort": "medium"},
 "reviewer": {"provider": "claude", "model": "…", "effort": "high"},
 "host": {"kind": "t3|claude|codex|antigravity|unknown", "thread_id": null}}
```

`approved` must be true. `worker` and `reviewer` are always present: the dispatcher skill fills them from `pd recommend` when the user accepts the recommendation or enables automatic selection. `auto_model` is only recorded (it lets the skill skip asking for this run); the engine never picks or changes a model. An explicit model that `describe` marks unavailable is refused with `model_unavailable` before any reservation; there is no fallback.

Run record `runs/<RUN>/run.json`: `{schema: 1, run_id, task_id, task_path, task: {id, title, type, touches, path, criterion_ids} (written by `state.new_run` from the base snapshot task; stages, candidate and publication read it, never the working tree), invocation, launch (the validated request), workspace (prepare_workspace result), base_sha, candidate: None|{sha, base_sha, tree_digest, task_archive_path} (saved right after the candidate phase; publication verifies against it), artifact: {version, wheel_sha256}, phase, outcome, blocker: None|{code, message, phase}, repairs_used, stage_seq, active_stage: None|{name, pid, host, started_at}, reports: [paths], publication: {steps: [..], branch, head_sha, pr_url}, cleanup: {state: pending|done|failed, warning}}`.

```python
lifecycle.drive(run: dict, ports: dict) -> dict     # runs phases until a terminal phase, saving after each
lifecycle.step(run: dict, ports: dict) -> dict      # runs exactly one phase
state.load_run(root, run_id) -> dict ; state.save_run(root, record) -> None ; state.new_run(root, launch, task) -> dict
```

`ports` keys: `runner`, `github`, `adapters` (`{provider: Adapter}`), `workspace` (`prepare_workspace`), `runtime` (`prepare_runtime`), `checks` (`run_checks`), `candidate` (`prepare_candidate`), `publish` (`publish_candidate`), `cleanup` (`cleanup_run`), `clock`. Tests pass fakes for each.

Phases in order: `preparing → working → checking → (repairing → checking)* → candidate → final_checks → reviewing → (repairing → checking → candidate → final_checks → reviewing)* → publishing → cleaning → done`. Terminal phases: `done`, `blocked`, `released`, `pending_publication`. Until PLD-03-06 merges, `candidate`/`publish`/`cleanup` ports are `None` and `drive` stops at `pending_publication` with blocker code `publication_unavailable` (exit 2).

- Repair budget: `repairs_used` ≤ 2 across failed or timed-out checks, failure scans, `generated_changes`, failed criteria, invalid worker reports, scope violations, invalid reviewer reports (one reviewer rerun counts as a repair) and major findings. Blocked checks, provider errors, timeouts, worker blocks, permission denials and reviewer mutations block without a repair. Exact precedence: PLD-03-05 "Stage outcome rules". Each repair is a fresh worker invocation with the task snapshot, the workspace and a findings file. Any repair discards prior final check and review results.
- Blocker codes: `check_blocked` (a check with status `blocked`; no repair), `task_not_eligible`, `base_moved`, `run_done`, `run_released`, `launch_invalid`, `model_unavailable`, `publication_unavailable`, `interrupted`, `candidate_changed`, `leak_detected`, `base_branch_push`, `remote_head_unexpected`, `run_not_published`, `workspace_outside_cache`, `checks_failed`, `review_major`, `report_invalid`, `worker_blocked` (worker report `blocked`), `permission_denied` (denied_actions non-empty and the stage then failed), `reviewer_mutated` (status or HEAD changed after a read-only stage; no repair), `no_change` (no diff from base), `scope_violation` (a changed path outside `touches` and engine-owned archive paths), `provider_error` (with the adapter code), plus every workspace/runtime/setup code. A blocked run marks its reservation `blocked` and keeps the clone.
- `pd resume RUN --invocation T`: refuses `run_active`; refuses another invocation (`invocation_mismatch`) unless `--adopt --request PATH` gives a new approved request with a new invocation (adoption replaces `invocation` and `launch`, keeps workspace and reports). Before continuing it re-runs `doctor` for the run's providers, `git fetch` and checks that the base branch still contains `base_sha` and that the remote task branch is absent or equals the recorded `publication.head_sha`. It restarts the blocked or interrupted phase.

### Candidate, publication and cleanup (PLD-03-06)

```python
archive.prepare_candidate(root, run, runner) -> dict       # {sha, base_sha, tree_digest, task_archive_path}
publication.publish_candidate(root, run, candidate, runner, github) -> dict   # {branch, head_sha, pr_url, confirmed}; root = project checkout; inputs come only from the frozen context/config.toml and the run record (task, workspace, base_sha, launch, reports)
cleanup.cleanup_run(root, run_id, runner, cache_root=None) -> dict    # {removed: bool, warning: str|None}; the workspace must resolve inside the passed or default cache_root, never a value read from the record
```

- Archive: in the workspace, `git mv <task folder> <parent>/done/<task folder>`, set `status: done` in its front matter, write `notes.md` (worker summary, per-criterion evidence, open notes), add one `../` to every relative link inside the moved `index.md`/`notes.md` that leaves the task folder, and rewrite every link target to this task in the parent index (story, `bugs/` or `improvements/` index) and, for epic tasks, in the epic index `<backlog>/<epic>/index.md` to the `done/` path; nothing else changes. The archived `index.md` and the parent index are rendered from their `base_sha` versions on every candidate, so repeating the step is idempotent. Engine-owned paths for the scope check: the task folder (original and `done/`), the parent index file and the epic index file. Then `git add -A` and commit with the worker's `commit_subject` (must match `policy.commit_subject_pattern`, else `report_invalid`) plus `attribution_template` when set. `tree_digest` = `git rev-parse <sha>^{tree}`.
- The candidate always starts with `git reset --soft <base_sha>`, so the published branch has exactly one commit on top of base.
- Publication steps, saved after each: `verify` (HEAD and tree equal the candidate), `leak_scan`, `remote_check`, `pushed`, `pr_found_or_created`, `confirmed`. Remote check: `git ls-remote <remote> refs/heads/<branch>`; absent or equal to the candidate continues; anything else is `remote_head_unexpected` (exit 2). Push `<sha>:refs/heads/<branch>` without force. PR: `find_pr` first, else `create_pr` with title from `pr_title_template` (`{type}` = task type, `{title}` = task title) and a body with task id/path, worker summary, criterion evidence, final check summary and minor findings. Retries skip steps already saved.
- Cleanup: only when publication `confirmed`, the run has no live `active_stage`, and the path is inside `cache_root/workspaces/`. Removes the clone, removes the reservation, keeps `runs/<RUN>/`. A removal error returns `{removed: false, warning}` and the run stays `done` with `cleanup.state = failed`; `pd cleanup RUN` retries. `pd cleanup` on a run that is not `done` refuses with `run_not_published` (exit 2).

### Planner support (PLD-04-01, `planning.py`)

```python
planning.prepare_plan(root, topic, config, runner, cache_root=None) -> dict   # {path, branch, base_sha, plan_id, status: created|reused}
planning.review_plan(root, plan_id, input_path, role, adapter, model, effort, runner) -> dict  # normalized stage result
```

- All `pd plan` commands run from the active project checkout; the planning clone is addressed by plan id (unknown id → `plan_missing`, exit 2).
- `plan_id = "plan-" + slug(topic)`; clone via `workspace.clone_at` at `<cache_root>/planning/<key>/<plan_id>/`, branch `feat/plan-<slug>`; no runtime, reservation or setup; record `<state_dir>/plans/<plan_id>.json`.
- The planner commits, pushes and opens its PR from the planning clone with plain `git` and `gh`, following the project's `instructions.paths` rules, only after the user's final approval.
- `pd plan review` builds a stage request with role `interview` or `cold`, `permission_profile.mode = "read"`, schema `review_verdict.schema.json`, report under `<state_dir>/plans/<plan_id>/reviews/`, `run_id = plan_id`.

### Models and coordinator (PLD-04-02)

```python
models.recommend(task, config, catalogs, roles=("worker", "reviewer"), preferred_provider=None) -> dict
coordinator.new_invocation(host_kind, thread_id) -> str
coordinator.build_request(task_id, worker, reviewer, selection, auto_model, invocation, host) -> dict
```

- `catalogs`: `{provider: describe()["models"]}`. For each role (`worker`, `reviewer`), candidates whose role matches and complexity equals the task's or `any`, whose provider is in `integrations.tools`, ordered by `rank`, then exact-complexity before `any`, then provider order claude, codex, antigravity. Output: `{worker: [{provider, model, effort, availability, reason}], reviewer: [...], recommended: {worker: first available|None, reviewer: …}}`. No available candidate for a role gives `None` and a reason.
- Engine stage prompts are package resources `P/resources/prompts/{worker,repair,reviewer}.md`, owned by PLD-03-05; the dispatcher skill does not contain them.
- `pd request --save-default-cli PROVIDER` is the only writer of `host.json`. `recommend(..., roles=("planner-review",))` returns `{"planner-review": [...], recommended: {"planner-review": …}}`.
- There is no coordinator event state machine: Python cannot observe the user's approval, so the skill asks, and `pd request` builds and validates the launch request (`launch_invalid`, exit 64). A provider whose adapter fails is left out of catalogs; its candidates are `unavailable` with a reason. `host.json` `default_cli` breaks ties among equal-rank candidates (`preferred_provider`).
- The local host choice file `.plan-dispatcher/local/host.json` is `{default_cli: provider}`; it never stores approvals.

### Installer and update (PLD-04-03, PLD-04-04)

```python
sources.materialize(source: dict, work_dir: Path, runner) -> dict    # {tree_path, content_digest, source_commit}
install.install_project(root, source, tools, proposal, confirmed, runner) -> dict
updates.update_project(root, source, runner) -> dict
ownership.load(root) / ownership.write(root, entries) / ownership.diff(root, entries) -> dict
```

- `source`: `{kind: "local", path: repo-relative}` or `{kind: "git", url, ref, commit}`. Digest (`runtime.content_digest`, the only implementation; materialize, doctor and update all call it): SHA256 over sorted `relative-path\0sha256(file)\n` lines of the files Git tracks under the source folder (`git ls-files -z -- <folder>` in the repository that holds it, content read from the working tree). Untracked files such as `.git/`, `__pycache__/`, `dist/`, `build/` or `.DS_Store` never count, so every clone of the same commit gives the same digest.
- The installer appends `.plan-dispatcher/venv/` and `.plan-dispatcher/local/` to the consumer's tracked `.gitignore` only when missing (idempotent with PLD-01-02's lines).
- Ownership manifest `.plan-dispatcher/managed.json` (committed): `{schema: 1, version, files: {repo-relative path: sha256}, links: {path: target}}`.

- Bootstrap and CLI use one flag style: `python3 install.py install|restore` and `pd install|restore|update` take `[--root PATH]`. Install and update also take `--source local --path P` or `--source git --url U --ref R --commit C`; install also takes `--tools LIST [--proposal PATH] [--confirm]`. `restore` takes only `[--root PATH]`, reads `[distribution]`, and rejects source flags with `usage`. `--root` defaults to the Git top level of cwd. A git tag that does not resolve to the commit fails with `source_mismatch`.
- `.plan-dispatcher/config.toml` and `.gitignore` are project-owned: never listed in `managed.json` and never staged as new files. An existing valid config counts as the confirmed proposal; the installer edits it in place (`install.rewrite_tables`) and rewrites only `[distribution]` and `[integrations]`. Without a config, it writes one (unconfirmed, or from `--proposal`).
- Shared install helpers (PLD-04-03; recovery by PLD-04-04): `install.stage/commit/rollback/rewrite_tables`, `ownership.diff` (→ `{added, changed, removed, edited, unowned, foreign_links, escapes}`) and `install.recover_interrupted_update(root)`.
- Extra installer/update codes: `unsupported_os`, `unsupported_python`, `git_missing`, `not_a_repo`, `source_mismatch`, `ownership_conflict`, `runs_active`, `incompatible`, `update_incomplete`, `github_remote_missing`.
- Install result: `{status: installed|needs_setup|unchanged, version, managed: [paths], warnings}`. Collision with an unowned existing path, an edited managed file, or a link that points elsewhere raises `ownership_conflict` (exit 2) listing every path; nothing is written (staging in `.plan-dispatcher/local/staging/`, then rename).
- `proposal`: `{setup: [command], validation: {...}, policy: {...}, models: [...], instructions: [...]}` with the same shapes as the config tables. Without confirmation, install writes the managed skills, links, venv and a config whose first line is the `needs_setup` marker, plus `.plan-dispatcher/local/proposal.json` `{evidence, template}`; it runs no discovered command. `pd install --proposal PATH --confirm` writes the confirmed tables.
- `unchanged` is judged by `content_digest` (plus `source_commit` for git); a change of `source_kind` or `source_commit` always counts as `updated`; a `sha256:pending` config digest is compared through `artifact.json`. `to_version` is read from the materialized tree's `pyproject.toml`. Update uses the install staging and backup only: `install.commit(staged, phase_hook=None)` calls `phase_hook(name)` on entering `replace`, `venv` and `manifest`, which is where the update journals and where tests inject faults. Phases: `replace` (backs up `config.toml`, `managed.json`, `artifact.json`, `.gitignore` and changed or removed targets; places files and links; deletes removed paths and empty parents), `venv`, `manifest` (`artifact.json`, then `managed.json`). Update journal: `{schema, from_version, to_version, from_digest, to_digest, staging_dir, phase}`; it has no separate backup folder, and rollback is `install.rollback(staging_dir)`.
- Update result: `{status: updated|unchanged, from_version, to_version}`; refuses `runs_active` when any run's `run_state` is `active` (`interrupted` does not block), and `incompatible` when the new `schema` differs and no migration exists. It changes only `[distribution]` and managed files, journals in `.plan-dispatcher/local/update-journal.json` (phases from `install.commit`; the old venv is moved aside, not copied). While a journal exists, every command except `update`, `install`, `restore`, `status`, `--help` and `--version` fails with `update_incomplete`; `pd update` then rolls back first.
- Blocked runs keep working after an update: each clone has its own venv installed from the wheel recorded in its run, and old wheels stay in `.plan-dispatcher/local/artifacts/<version>-<digest12>/` until no run record references them; `pd cleanup` deletes an unreferenced old wheel.

### Planned tests and invocation

P contains no Sport Timer configuration, parity case data or app-specific test paths. T/run_tests.py inserts P from its own location and runs stdlib unittest modules named on the command line (no installation/network required). Example: `python3 tool/plan_dispatcher/tests/run_tests.py test_config test_tasks`. No arguments runs the package suite. T/support.py supplies deterministic subprocess/Git/fake-GitHub utilities as specified by the owning test task. These are planned test infrastructure, not ad hoc dispatcher scripts.

Package-edit rule: any task that changes files under `tool/plan_dispatcher/` after PLD-05-01 has installed it runs `.plan-dispatcher/venv/bin/pd update --source local --path tool/plan_dispatcher` as its last step and lists `.plan-dispatcher/config.toml` and `.plan-dispatcher/managed.json` in `touches`, so `doctor` never reports `artifact_stale` on master.

Public source test modules: test_cli, test_wheel, test_contracts, test_ports, test_gitutil, test_config, test_tasks, test_selection, test_reservations, test_checks, test_diff, test_workspace, test_preflight, test_claude, test_codex, test_antigravity, test_lifecycle, test_publication, test_cleanup, test_portable_flow, test_planner, test_models, test_dispatcher_skill, test_install, test_update, test_release_install. Each task owns its named modules and narrowly scoped shared harness additions. Runtime caches, fixtures and paid/live provider credentials never enter the package.

Consumer parity files: .plan-dispatcher/config.toml, test/tool/fixtures/plan_dispatcher_check_cases.json, test/tool/test_plan_dispatcher_parity.py. Consumer backlog check: `test/tool/test_backlog_integrity.py` (PLD-05-02; `--source` / `--installed` / `--check-ready`), run in CI and by PLD-05-03. Consumer Python tests load the package from the installed runtime or an explicitly passed local source during bootstrap; their CLI takes `--source tool/plan_dispatcher/src` before extraction and `--installed` after adoption. They use stdlib only. Keep instructions/file names portable when this backlog moves to docs/tasks. With `--installed`, the system `python3` adds the single `.plan-dispatcher/venv/lib/python*/site-packages` folder to `sys.path`. The package-boundary denylist (PLD-02-02) and the export scan (PLD-06-01) use one shared pattern list, kept in `test/tool/fixtures/plan_dispatcher_boundary_patterns.txt`; `LICENSE` and `_vendor/` are exempt. Release fixtures (`test_release_install`, `test_portable_flow`) run from a clone of the release pinned to its commit, because the wheel does not contain `tests/`.

### Scope and evidence limits

CLI messages and documentation are English tooling output, not Flutter application text, so ARB/goldens are not required for this epic. No lib, Android, iOS, Firebase, dependency manifest or app UI changes are authorized. Framework-specific content required by future app tasks remains in consumer instructions/config. Existing app architecture/full-suite checks remain required at cutover; no tests are weakened merely to pass. State/readiness docs must include local blocked reservations and explicit handoff executor completion.

Claude 2.1.319, Codex 0.167.0 and Antigravity 1.5.3 were installed on the planning machine on 2026-11-08 and their JSON output shapes were sampled for the adapter fixtures. Only the live Codex smoke is a required gate; Claude and Antigravity live smokes stay optional and are reported unverified unless run. The live Codex fixture (local bare remote and fake GitHub; no permanent repository) must exercise a real worker/check/reviewer before validator retirement. If the actual cache/permission route fails, retirement is not ready to complete until the approved configuration/implementation resolves it.

