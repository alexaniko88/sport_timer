# Project overrides for the runners

The rules of this app, by stage. Each role reads "Common" and its own section. They stand on their own: the shared global rules in `~/.claude/` were written for another codebase and are not available to the runners. `CLAUDE.md` and `.agents/rules/dart-style.md` are complete on their own.

## Common

- **Layered architecture.** Code is feature-first: `lib/features/<name>/{domain,data,presentation}` (only the layers a feature needs), shared UI in `lib/shared/presentation/`, pure helpers in `lib/core/`, composition in `lib/di/di.dart`, `main.dart` and `navigation.dart`. Domain imports only `dart:*`, `core/` and other domain files; presentation never imports `data/` or platform packages; data never imports presentation; contracts return app types, never platform types. Follow `CLAUDE.md` ("Project layout", "Architecture (MVVM and layers)", "Boundary check").
- **State management.** MVVM with `ValueNotifier` state. Follow `CLAUDE.md` ("State management"). No Bloc, no state management package, no `freezed`, no code generation. `go_router` stays.
- **No style guide file.** `docs/CodeStyleGuide.md` does not exist. The Dart rules that matter are in `.agents/rules/dart-style.md`.
- **Scope.** Do what the task asks. Mention an unrelated problem in one line and do not act on it.
- **Fixed task contract.** Read the task's Contract and linked parent agreements before implementing. Follow the specified inputs, outputs, failures, lifecycle, paths and dependencies. Do not redesign a public contract, invent missing product behavior or expand `touches`. A necessary deviation is an unforeseen blocker: report the precise mismatch for planner reconciliation. Routine private implementation choices follow existing patterns. Missing contracts/check plans in an older task require refinement before work, not improvisation.
- **Unwired building blocks.** A planned block can have only test callers until its named consumer/assembly task merges. This is intentional, not a reason to wire it early or remove it as unused. Verify the consumer and assembled-check owner are named. Shared UI still needs two actual users under `CLAUDE.md`; planned users alone do not qualify, so keep the block feature-local until an explicit reuse/promotion task supplies them.
- **Git.** Never run `git add`, `git commit`, `git push` or `git checkout`. The script does all git work.
- **Minimal tools.** Use file read/search/edit tools, local image viewing for goldens, and these shell commands only: read-only `git status`, `git diff`, `git log`, `git show`; `rg`, `grep`, `ls`, `cat`, `head`, `tail`, `wc`, `sort`, `diff`, `mkdir`; `fvm dart format`, `fvm flutter analyze`, `fvm flutter test` with literal `test/` paths, `fvm flutter gen-l10n`, `fvm flutter pub get`, and `fvm dart tool/agent_check.dart --skip-build`. Reviewers use only read-only tools/commands. The script's own clone/publish operations are outside this runner list.
- **No runtime/manual validation.** Do not launch the app, use emulators/devices, run integration tests, start servers, browse/automate a UI or call external connectors to validate a task. Do not use Python, shell-edit scripts or other interpreters as helper tooling, install extra tools, or add ad hoc helper scripts. Tasks must already provide sufficient repo context and test/static checks. Missing capabilities return to planning; a tool permission grant alone does not expand task scope.
- **Permission limits.** These boundaries apply to every provider. Claude also has command-prefix permissions; Codex/Antigravity sandboxes do not enforce this exact command list. Do not claim universal command-level enforcement. Record any denied command and never bypass a denial.
- **One simple command per check.** Run each check as its own command with literal file paths. Never use a variable (`F="..."`), `;`, `&&`, `||`, `|` or `$(...)`: one chained line can be denied as a whole. To check everything the change needs in one command, run `fvm dart tool/agent_check.dart --skip-build`.
- **Edit with your edit tools.** Change files with the edit and write tools, never with a `python3` or `sed` script. If a command is denied, do not retry it another way through the shell. Do the work with the edit tools, or report it under "Blocked" with the exact command you needed. A denied command does not stop the run, but the script lists it in the PR, so never skip a format, analyze or test run silently.

## Implementation

- **Layers.** Put every new file in the task's specified layer. Add use cases only for real business logic. If the location/layer requires an unresolved architecture choice, report the missing decision instead of choosing a new architecture.
- **Extensions, not helper functions.** A helper that works on one type (its first argument is the thing it works on, or it maps one type to another) is an extension in the `extensions/` folder of its layer (`core/extensions/`, `shared/presentation/extensions/`, `features/<name>/<layer>/extensions/`), one extension per file, named after the type it extends. Never add a top-level helper when an extension fits.
- **Styling.** The app has one shared look (`CLAUDE.md`, "Styling and theme"). Bordered tiles use `AppSurface`; radius and border width come from `AppRadius` and `AppBorderWidth`; button and dialog shapes come from `SportTheme`; text roles come from `AppTextThemeExtension` and `AppTextStyles`; colors come from the theme and alpha from `AppAlpha` or `TimerAlpha`. Never hand-build a tile with its own border, a raw radius, border width, alpha or color, or a repeated `copyWith(fontWeight: ...)`. A new shared token or widget needs two or more users. The goldens are the visual reference; do not run an emulator to check a style.
- **Strings.** The app uses `gen-l10n` (`l10n.yaml`, `lib/l10n/`). Every user-facing string (text, tooltips, semantic labels, snackbars) comes from `context.l10n`, and dates and numbers follow the locale. Add each new key to both `app_en.arb` and `app_es.arb` (with a `description` in the English one, ICU plural messages for counts) and run `fvm flutter gen-l10n`. Never hardcode English text and never add `FIXME-ALEX` blocks: the global rule that does so is for another codebase.
- **Format and analyze.** Run `fvm dart format` and `fvm flutter analyze --no-pub` only on the files you touched, by literal path. Never pass a directory.
- **Comments.** One or two short plain sentences explaining why, only where the code is not obvious.

## Tests

- Unit tests use hand-written fakes (no mocking package unless the task adds one). Not `patrol_finders`.
- Unit tests are the default for logic. Use the task's exact validation plan and relevant cases. Goldens verify appearance; they do not verify interaction/lifecycle. A behavioral widget test requires a written reason in the task naming what unit tests and goldens cannot prove. Do not add redundant unit tests for pure wiring or insist every block needs every test kind.
- The plan must name required fakes and harness changes. Existing infrastructure is reused; do not invent new infrastructure during the tests stage. A missing required capability is a planning blocker. A simple task-specific fake explicitly named in the task is normal test work.
- Test paths mirror `lib/`: `test/features/<name>/<layer>/<file>_test.dart`. Tests for `tool/` mirror it under `test/tool/`.
- `test/architecture/layer_boundaries_test.dart` enforces the layer rules. Fix the code instead of loosening it, and add a named exception there only with a written reason.
- UI snapshot goldens live in `test/snapshots/ui_snapshots_test.dart` (`test/snapshots/goldens/*.png` and `test/snapshots/README.md`) and use `alchemist` platform goldens on macOS.
- For an isolated visual widget, add its specified component scenarios to the existing snapshot harness when appearance needs verification; screen assembly owns its screen/flow snapshots separately. No app launch is needed. A ViewModel/state-only block needs no new golden merely because it lives in presentation.
- Integration tests are planned and executed independently through `.agents/skills/skill-integration-tests/SKILL.md`, outside ordinary dispatcher tasks. Do not read that skill, change `integration_test/` or run device tests merely because changed code is covered by an integration flow. A task requiring those activities must be routed to that separate workflow before dispatch.
- Write tests only for code the task changed. Run the named new/changed tests and required regressions by literal file path. The script also runs `tool/agent_check.dart --skip-build`, including architecture and regression snapshots when selected; the task's narrower test list does not waive those checks.

## Review checks

Flag these, with a file and a line:

- Files in the wrong layer, platform types in domain contracts, use cases that only forward a call.
- A new user-facing string that is not a `context.l10n` key in both ARB files (general).
- A new top-level helper function that should be an extension, or an extension outside an `extensions/` folder (general).
- A hand-built bordered tile, raw radius, border width, alpha or color literal, per-button shape, or repeated text style that a shared piece replaces, unless it is a documented exception in `CLAUDE.md` (general).
- Bloc, `freezed`, a state management package or generated code (critical).
- For UI changes: icon-only buttons without a label or tooltip, and text scaling pinned (general).
- An unapproved contract change, missing named wiring or an unmet acceptance check (critical). If a contract itself must change, require planner reconciliation rather than suggesting a private redesign.
- Out-of-scope integration tests/helper scripts, unplanned test infrastructure, or behavioral widget tests without the task's justification (general). Check the task's check plan and reported evidence; do not infer unobserved command execution from the diff.
- After a change that applies a rule across the app (a style sweep, a rename), run your own search for the pattern and check the matches by hand. Do not rely only on the diff.
