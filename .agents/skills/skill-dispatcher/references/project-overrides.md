# Project overrides for the runners

The rules of this app, by stage. Each role reads "Common" and its own section. They stand on their own: the shared global rules in `~/.claude/` were written for another codebase and are not available to the runners. `CLAUDE.md` and `.agents/rules/dart-style.md` are complete on their own.

## Common

- **Layered architecture.** Code is feature-first: `lib/features/<name>/{domain,data,presentation}` (only the layers a feature needs), shared UI in `lib/shared/presentation/`, pure helpers in `lib/core/`, composition in `lib/di/di.dart`, `main.dart` and `navigation.dart`. Domain imports only `dart:*`, `core/` and other domain files; presentation never imports `data/` or platform packages; data never imports presentation; contracts return app types, never platform types. Follow `CLAUDE.md` ("Project layout", "Architecture (MVVM and layers)", "Boundary check").
- **State management.** MVVM with `ValueNotifier` state. Follow `CLAUDE.md` ("State management"). No Bloc, no state management package, no `freezed`, no code generation. `go_router` stays.
- **No style guide file.** `docs/CodeStyleGuide.md` does not exist. The Dart rules that matter are in `.agents/rules/dart-style.md`.
- **Scope.** Do what the task asks. Mention an unrelated problem in one line and do not act on it.
- **Git.** Never run `git add`, `git commit`, `git push` or `git checkout`. The script does all git work.

## Implementation

- **Layers.** Put every new file in the right layer. Add use cases only for real business logic. The task names the layer of what it creates; if it does not, decide from `CLAUDE.md`.
- **Extensions, not helper functions.** A helper that works on one type (its first argument is the thing it works on, or it maps one type to another) is an extension in the `extensions/` folder of its layer (`core/extensions/`, `shared/presentation/extensions/`, `features/<name>/<layer>/extensions/`), one extension per file, named after the type it extends. Never add a top-level helper when an extension fits.
- **Styling.** The app has one shared look (`CLAUDE.md`, "Styling and theme"). Bordered tiles use `AppSurface`; radius and border width come from `AppRadius` and `AppBorderWidth`; button and dialog shapes come from `SportTheme`; text roles come from `AppTextThemeExtension` and `AppTextStyles`; colors come from the theme and alpha from `AppAlpha` or `TimerAlpha`. Never hand-build a tile with its own border, a raw radius, border width, alpha or color, or a repeated `copyWith(fontWeight: ...)`. A new shared token or widget needs two or more users. The goldens are the visual reference; do not run an emulator to check a style.
- **Strings.** The app uses `gen-l10n` (`l10n.yaml`, `lib/l10n/`). Every user-facing string (text, tooltips, semantic labels, snackbars) comes from `context.l10n`, and dates and numbers follow the locale. Add each new key to both `app_en.arb` and `app_es.arb` (with a `description` in the English one, ICU plural messages for counts) and run `fvm flutter gen-l10n`. Never hardcode English text and never add `FIXME-ALEX` blocks: the global rule that does so is for another codebase.
- **Format and analyze.** Run `fvm dart format` and `fvm flutter analyze --no-pub` only on the files you touched, by literal path. Never pass a directory.
- **Comments.** One or two short plain sentences explaining why, only where the code is not obvious.

## Tests

- Unit tests use hand-written fakes (no mocking package unless the task adds one). Not `patrol_finders`.
- Test paths mirror `lib/`: `test/features/<name>/<layer>/<file>_test.dart`. Tests for `tool/` mirror it under `test/tool/`.
- `test/architecture/layer_boundaries_test.dart` enforces the layer rules. Fix the code instead of loosening it, and add a named exception there only with a written reason.
- UI snapshot goldens live in `test/snapshots/ui_snapshots_test.dart` (`test/snapshots/goldens/*.png` and `test/snapshots/README.md`) and use `alchemist` platform goldens on macOS.
- Integration tests (`integration_test/`, Android only) follow `.agents/skills/skill-integration-tests/SKILL.md`. `fvm flutter test` does not run them; if no Android target is available, say so in the report and do not claim they passed.
- Write tests only for code the task changed. Run only the tests you touched, by file path.

## Review checks

Flag these, with a file and a line:

- Files in the wrong layer, platform types in domain contracts, use cases that only forward a call.
- A new user-facing string that is not a `context.l10n` key in both ARB files (general).
- A new top-level helper function that should be an extension, or an extension outside an `extensions/` folder (general).
- A hand-built bordered tile, raw radius, border width, alpha or color literal, per-button shape, or repeated text style that a shared piece replaces, unless it is a documented exception in `CLAUDE.md` (general).
- Bloc, `freezed`, a state management package or generated code (critical).
- For UI changes: icon-only buttons without a label or tooltip, and text scaling pinned (general).
- After a change that applies a rule across the app (a style sweep, a rename), run your own search for the pattern and check the matches by hand. Do not rely only on the diff.
