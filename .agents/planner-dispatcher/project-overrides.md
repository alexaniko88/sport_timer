# Project overrides for the runners

The rules of Sport Timer, by stage. Each role reads "Common" and its own section, after the generic `.agents/skills/skill-dispatcher/references/runner-rules.md` and the rules of the stacks listed in `planner_dispatcher.yaml`. Where they differ, this file wins. `CLAUDE.md` and `.agents/rules/dart-style.md` are complete on their own; the shared global rules in `~/.claude/` were written for another codebase and do not apply here.

## Common

Facts every stage needs.

- **Per-file commands.** Format with `fvm dart format <path>`, analyze with `fvm flutter analyze --no-pub <path>` and test with `fvm flutter test <path>`, always with a literal path, never a directory. Regenerate strings with `fvm flutter gen-l10n`. To run every check the change needs in one command, run `fvm dart tool/agent_check.dart --skip-build`.
- **Layers.** Feature-first: `lib/features/<name>/{domain,data,presentation}` (only the layers a feature needs), shared UI in `lib/shared/presentation/`, pure helpers in `lib/core/`, composition in `lib/di/di.dart`, `main.dart` and `navigation.dart`. Domain imports only platform-free `dart:*`, `core/` and other domain files; presentation never imports `data/` or platform packages; data never imports presentation; contracts return app types, never platform types. Follow `CLAUDE.md` ("Project layout", "Architecture (MVVM and layers)", "Boundary check").
- **State management.** MVVM with `ValueNotifier` state, one ViewModel per screen or feature, created and disposed by its page. Repositories return the sealed `Result`; the ViewModel turns it into state. No Bloc, no state management package, no `freezed`. `go_router` and `get_it` (registered by hand) stay.
- **Strings.** `gen-l10n` (`l10n.yaml`, `lib/l10n/`). Every user-facing string comes from `context.l10n`. Add each new key to both `app_en.arb` and `app_es.arb` (with a `description` in the English one, ICU plural messages for counts) and run `fvm flutter gen-l10n`. Never hardcode English text and never add `FIXME-ALEX` blocks: the global rule that does so is for another codebase. Exception: the debug-only Developer tools page in `lib/features/developer/` and its drawer entry label in `lib/features/home/presentation/home_page.dart` use hardcoded English text and no ARB keys; they never ship in release builds.
- **Generated code.** Only the localization output in `lib/l10n/` (`fvm flutter gen-l10n`). No other code generation, no `part` files, no barrel libraries.
- **No style guide file.** `docs/CodeStyleGuide.md` does not exist. The Dart rules that matter are in `.agents/rules/dart-style.md`, which wins over the stack where they differ (for example: a two-case `Result` uses `if-case` or `fold`, never a `switch`).

## Implementation

Where new code goes and how it is written in this project.

- **New code.** Put every new file in the task's layer: pages, widgets, ViewModel and state in `features/<name>/presentation/`, models and contracts in `domain/`, implementations of platform packages in `data/`. Add a use case only for real business logic. If the location needs an unresolved architecture choice, report the missing decision instead of choosing.
- **Extensions.** A helper that works on one type is an extension in the `extensions/` folder of its layer (`core/extensions/`, `shared/presentation/extensions/`, `features/<name>/<layer>/extensions/`), one per file, named after the type it extends. Never a top-level helper when an extension fits.
- **Shared UI.** One shared look (`CLAUDE.md`, "Styling and theme"). Bordered tiles use `AppSurface`; buttons use `AppButton`; radius and border width come from `AppRadius` and `AppBorderWidth`; spacing from `AppSpacing` (with `Gap` for spacing between widgets); button and dialog shapes from `SportTheme`; text roles from `AppTextThemeExtension` and `AppTextStyles`; colors from the theme, alpha from `AppAlpha` or `TimerAlpha`. A new shared token or widget needs two or more real users. The goldens are the visual reference; do not run an emulator to check a style.
- **Dependencies.** A task adds a package only when it says so, pinned to an exact version in `pubspec.yaml` (no `^`).

## Tests

Where tests go, how they are named and which fakes to use.

- **Location.** Test paths mirror `lib/`: `test/features/<name>/<layer>/<file>_test.dart`. Tests for `tool/` mirror it under `test/tool/`.
- **Test doubles.** Hand-written fakes. `mocktail` is in the project but new tests use fakes unless the task says otherwise. Not `patrol_finders`.
- **Test kinds.** Unit tests are the default for logic. Goldens verify appearance, not interaction or lifecycle. A behavioral widget test needs a written reason in the task.
- **Boundary test.** `test/architecture/layer_boundaries_test.dart` enforces the layer rules. Fix the code instead of loosening it, and add a named exception there only with a written reason.
- **Visual snapshots.** `alchemist` platform goldens on macOS in `test/snapshots/ui_snapshots_test.dart`, images in `test/snapshots/goldens/*.png`, flow index `test/snapshots/README.md`. Update with `fvm flutter test --update-goldens test/snapshots/ui_snapshots_test.dart` and keep only the images the task lists; update the flow links when a screen or route changes. An isolated visual widget gets its component scenarios in the existing harness; screen assembly owns its screen and flow snapshots.
- **Integration tests.** Planned and run separately through `.agents/skills/skill-integration-tests/SKILL.md`, outside dispatcher tasks. Do not read that skill, change `integration_test/` or run device tests in a dispatcher task.

## Review checks

What the reviewer flags in this project, each with a severity.

- A file in the wrong layer, a platform type in a domain contract, or a use case that only forwards a call (general).
- A new user-facing string that is not a `context.l10n` key in both ARB files, outside the Developer tools exception in Common (general).
- A new top-level helper that should be an extension, or an extension outside an `extensions/` folder (general).
- A hand-built bordered tile, raw radius, border width, alpha or color, a per-button shape or a repeated text style that a shared piece replaces, unless `CLAUDE.md` documents the exception (general).
- Bloc, `freezed`, a state management package or generated code other than `gen-l10n` (critical).
- A `switch` over the two cases of `Result`, or a cast after an `if-case` on it (minor).
- After a change that applies a rule across the app (a style sweep, a rename), search for the pattern yourself and check the matches by hand; do not rely only on the diff.
