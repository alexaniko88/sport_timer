# Flutter and Dart rules

The rules for any Flutter or Dart project, by stage. Each role reads "Common" and its own section, after `.agents/skills/skill-dispatcher/references/runner-rules.md` and before `.agents/planner-dispatcher/project-overrides.md`. The project files hold the choices of the project (state management, strings, test doubles, snapshot tooling, layers, shared UI pieces, code style beyond the analyzer) and win where they differ from these rules. `suggested-overrides.md` next to this file has optional style lines a project can copy into its overrides.

## Common

- **Project choices.** Use the state management, localization setup, test doubles, snapshot tooling and folder layout the project rules name. Never add another state management package, a second pattern for the same job, or a heavy package the task does not ask for. When the project rules name none and the task needs one, report the missing decision instead of choosing.
- **Formatter and analyzer.** `dart format` and the project's `analysis_options.yaml` decide the layout and the lints. Fix every analyzer issue in the files you touched, keep the lines the formatter changes in them, and never format or fix files you did not touch. Do not add `// ignore:` comments unless the task asks for one.
- **Follow what exists.** Before you add a helper, extension, widget, constant or theme value, search for one that already does the job and use or extend it. Copy the pattern of similar code (the same kind of page, repository, mapper or error handling) instead of inventing one. Never use an API, widget or package that the code or its documentation does not show.
- **Generated files.** Never edit generated files by hand (`*.g.dart`, `*.freezed.dart`, localization output). Change the source and run the generator the project rules name. When a task needs a generator the project rules do not name, report it.

## Implementation

### Dart style

- **No null assertion.** Never use the null assertion operator (`x!`), unless a third-party API makes type promotion impossible. Use `if (x != null)`, `if (x case final value?)`, `?.` or `??`, and rely on type promotion.
- **Choose by the type.** For a `bool`, or a nullable value of any other type, use `if`, `if-case` or a ternary, never a `switch`. For an enum or a sealed type, use an exhaustive `switch` (a switch expression when it gives a value), even with 2 cases, so a new case fails to compile instead of falling into an `else`. A nullable enum or sealed type gets the same `switch` with a `null` case.
- **Exhaustive switches.** A `switch` over an enum or a sealed type lists every value, with no `_` or `default`. Group the cases that share a body with `||`. Never add a dead fallback value just to satisfy a switch.
- **Patterns.** Use object and record patterns with destructuring (`case Failure(:final error)`) instead of casts and temporary variables, and `when` guards instead of an `if` inside a case. Decode maps and JSON with patterns instead of manual key checks and casts.
- **Early return on failure.** To stop on the failure case of a result type, return early with an `if-case` (`if (result case Failure(:final error)) return ...;`), or use the type's own `fold` when it has one. Never cast (`as Success<T>`) after a check.

### Flutter

- **Widgets.** Use `const` constructors wherever possible. Split a large `build()` into small widget classes, not `_buildX()` methods.
- **Lifecycle.** Whatever a class creates or adds, the same class disposes or removes in its `dispose()`: `addListener` gets `removeListener`, a `StreamSubscription` gets `cancel()`, a controller, `FocusNode`, `Timer` or notifier it owns gets disposed or cancelled. Never start work or side effects inside `build()`.
- **Futures.** Await every future, or wrap one that must run on its own in `unawaited(...)`, so a dropped error or a race is a choice and not a slip.
- **Async and context.** After an `await`, check `mounted` (or the context's `mounted`) before using a `BuildContext` or calling `setState`. Work that may finish after its owner is disposed must not change state.
- **New state, not changed state.** Never change a state object in place and set it again: a notifier that compares values sees the same object and does not notify. Create a new state object (for example with `copyWith`).
- **Rebuild cost.** Build long or unbounded lists with a builder (`ListView.builder`), keep `setState` and rebuilds to the part of the tree that changes, and keep expensive work out of `build()`.
- **Logs and errors.** Never log secrets, tokens or personal data. Log through what the surrounding code uses, never `print`. Never leave an empty `catch`: catch the type you expect and handle or log it.
- **Theme values.** No new raw colors, text styles, radii, spacing or sizes in a widget. Use the theme and the shared values the project names.
- **Strings.** Every user-facing string (text, tooltip, semantic label, snackbar) follows the project's localization setup. Never hardcode one unless the project rules say how to.
- **Accessibility.** An icon-only button gets a semantic label or a tooltip. Purely decorative images and icons are excluded from semantics. Never pin the text scale (`TextScaler.noScaling`, `TextScaler.linear(1.0)`). Tap targets keep the platform minimum size.

## Tests

- **Copy a sibling.** Before you write a test, read an existing test of the same kind nearby and copy its folder, imports, setup and helpers.
- **Test doubles.** Use the fakes or the mocking package the project rules name, and reuse the shared ones before adding new ones. Never add a mocking package. With `mocktail`, a generic method whose type comes from another argument needs `any<T>()`, not a bare `any()`, in both `when` and `verify`.
- **Test data.** Reuse the shared fixtures. Add a new one next to the similar ones only when no fixture fits, with only the fields the case needs. Never change a widely used fixture for one test, and never add a production parameter only to make a test shorter.
- **Async tests.** Control time with `fakeAsync` or the widget tester's `pump`, never with real waits.
- **Widget tests.** Write one only when the task's plan asks for it, for an interaction that unit tests and snapshots cannot check. Inside `testWidgets`, never call `tester.ensureSemantics()`: semantics are already on.
- **Semantics checks.** Check semantics with `matchesSemantics` on a finder that targets the `Semantics` widget itself, because `getSemantics` only walks up the tree.
- **Snapshots.** Update golden or snapshot images only with the per-file update command the project names, and only for the images the task lists. Never update all of them.

## Review checks

Flag these, with a file and a line:

- A null assertion (`x!`), a `switch` over a `bool` or over a nullable value that is not an enum or sealed type, a `_` or `default` in a switch over an enum or a sealed type, or a cast after a type check (general).
- A missing `dispose()`, `cancel()` or `removeListener` for something the class created or added, or work started inside `build()` (critical when it leaks).
- A `BuildContext` or `setState` used after an `await` without a `mounted` check (critical).
- A state object changed in place and set again, so listeners are not notified (critical).
- Expensive work or a needless rebuild in `build()`: an unbounded list built without a builder, a `setState` wider than needed, a missing `const` the analyzer does not catch (general).
- A raw color, text style, radius, spacing or size in a widget (general).
- A user-facing string outside the project's localization setup, an icon-only button without a label, or a pinned text scale (general).
- A new state management package or pattern, a heavy dependency, or a hand edit of a generated file (critical).
- A secret, token or personal data in a log, an empty `catch`, or a `print` (critical for data in logs, general otherwise).

## Planning

- **Task kinds.** A Flutter piece is usually a widget (an isolated visual block), a screen assembly (wiring blocks, navigation and state into a page), a state or logic unit (a view model, controller or notifier, with its state), a repository or service, or a model with its mapping. Plan each as its own task when it is a separate responsibility.
- **Visual words.** In the backlog, a "component" is a widget and a "visual snapshot" is a golden image. A visual task names the widget, its states and the snapshot files it adds or changes.
- **Test kinds.** Unit tests for logic, state and mapping. Golden or snapshot tests for appearance, when the project has them. A widget test only for an interaction the other two cannot check, with the reason in the task. Integration tests stay outside dispatcher tasks.
- **Generated code and strings.** A task that changes a model with generated code, or adds a user-facing string, names the generator or localization command the project rules give. When they give none, the task stays `draft`.
