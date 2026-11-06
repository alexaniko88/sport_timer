---
paths:
  - "**/*.dart"
---

# Sport Timer Dart style

Rules for this project only. They stand alone. If the machine also has a global `~/.claude/rules/flutter/dart-core.md`, it adds to them; where they differ, these win. They apply to all the code in this app, new and existing, not only to code you touch.

- Never write a function type inline in a parameter, field or return type (like `Future<Result<void>> Function() action`). Name it with a `typedef` and use the name. Use an existing Flutter typedef (`VoidCallback`, `ValueChanged<T>`) when one fits. Put the typedef at the top of the file that uses it. Move it to `lib/core/typedefs.dart` only when it is generic and several features share it.
- A function, method, constructor or call with 3 or more parameters or arguments gets a trailing comma, one per line, for readability. This is stricter than the shared rule (more than 3).
- An enum with 3 or more values gets one value per line with a trailing comma. A list, set or map with 3 or more entries does the same when it does not fit on one line.
- In every class, put the fields first, then the constructor, then the methods.
- Use pattern matching wherever it makes the code easier to read, not only in a `switch`: switch expressions, `if-case`, object and record patterns with destructuring (`case Failure(:final error)`), `when` guards, and `||` patterns to share a body between cases. Fall back to a plain `switch`, `if` or manual checks only when the pattern version becomes hard to read. With only two outcomes (including a sealed class with two cases like `Result`), use `if`, `if-case` or a ternary instead of a `switch`. Use a `switch` from three outcomes up.
- A `Result` that must return early on `Failure` uses `fold` (named `onSuccess` and `onFailure`), with the rest of the method moved into a small private helper. Never cast with `as Success<T>` after an if-case, and never use a `switch` statement for the two cases of `Result`.
- Log with `debugPrint`, never `print`. For a long message (a stack trace, a full error or a big object) use `log` from `dart:developer`, because the platform log can cut a very long line.
- When a scope (a `build` method, a helper) reads the same value from the context more than once, take it once in a local `final` at the top and use that. For localization this is `final l10n = context.l10n;`, never `context.l10n.x` repeated. The same goes for any other value that is reused (a theme, a color, a `ViewModel` field). A single use can stay inline.
- A `switch` over an enum or a sealed type lists every value, with no `_` or `default`, so a new value has to be handled on purpose. This holds even when only one or two values do something: group the idle ones with `||`. The two-outcome rule above is for a real two-way choice, not for an enum with more values.

- Use an extension, never a top-level helper function, when the helper works on one type (a function whose first argument is the thing it works on, a mapper from a platform type to an app type, a getter or conversion on an existing type). Example: `templateName(context, id)` becomes `l10n.templateName(id)`. One extension per file, in an `extensions/` folder of its own layer (`core/`, `shared/presentation/` or `features/<name>/<layer>/`), named after what it extends. A top-level function is fine only when no single type owns the work (for example `main()` or DI setup). Apply this to every new helper, and to code you rewrite; do not sweep untouched code.
- Use the existing `gap` package for simple spacing between widgets in a `Row`, `Column` or scrollable list: prefer `Gap(AppSpacing.s8)` over a spacing-only `SizedBox`. Keep `SizedBox` when it sizes content, sets constraints or acts as a layout placeholder. Apply this when adding or changing layout; avoid unrelated spacing sweeps.
- Never use the bang operator (`!`) unless a third-party API makes type promotion impossible. Use `if (x != null)`, `if (x case final nonNull?)`, `?.` or `??`, and rely on type promotion.
- Keep widget styling as simple as the API allows. To restyle one `AppButton`, pass `style: FilledButton.styleFrom(...)`, which takes plain values. Do not wrap it in a local button theme or build a `ButtonStyle` by hand with `WidgetStatePropertyAll`, and do not add a fallback such as `?? FilledButton.styleFrom()` for a theme style that the app theme always sets.
- Run `fvm dart format` and `fvm flutter analyze` only on the files you touched, with literal file paths, never a directory.
